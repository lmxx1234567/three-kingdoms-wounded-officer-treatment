import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { validateLocalizationCosts } from "../tools/validate-localization-costs.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const configFile = "pack_root/script/campaign/mod/a_wota_config.lua";
const localeFiles = [
  "localization/wota_en.loc.tsv",
  "localization/wota_ja.loc.tsv",
  "localization/wota_ko.loc.tsv",
  "rpfm_import/wota_zh_cn.loc.tsv",
];
const treatmentKey = "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visitsFIRST";
const recruitKey = "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_recruitSECOND";

function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), "wota-localization-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  for (const file of [configFile, ...localeFiles]) {
    cpSync(join(root, file), join(directory, file));
  }
  return directory;
}

function changeCost(directory, name, cost) {
  const file = join(directory, configFile);
  const config = readFileSync(file, "utf8");
  writeFileSync(file, config.replace(new RegExp(`(WOTA_CONFIG\\.${name}\\s*=\\s*)\\d+`), `$1${cost}`));
}

function changeRow(directory, localeFile, key, value) {
  const file = join(directory, localeFile);
  const lines = readFileSync(file, "utf8").split(/\r?\n/);
  const index = lines.findIndex((line) => line.startsWith(`${key}\t`));
  assert.notEqual(index, -1, `Fixture must contain ${key}`);
  if (value === undefined) {
    lines.splice(index, 1);
  } else {
    const columns = lines[index].split("\t");
    columns[1] = value;
    lines[index] = columns.join("\t");
  }
  writeFileSync(file, lines.join("\n"));
}

test("repository prices match both configured costs in all four locales", () => {
  assert.doesNotThrow(() => validateLocalizationCosts(root));
});

for (const [name, cost] of [["hua_tuo_cost", 200], ["hua_tuo_recruit_cost", 100]]) {
  test(`rejects ${name}=${cost} when localization still shows the default`, (t) => {
    const directory = fixture(t);
    changeCost(directory, name, cost);
    assert.throws(() => validateLocalizationCosts(directory), /must show the configured/);
  });

  test(`the build entry point rejects mismatched ${name} without RPFM`, (t) => {
    const directory = fixture(t);
    changeCost(directory, name, cost);
    const result = spawnSync(process.execPath, [join(root, "tools/build-rpfm.mjs")], {
      cwd: directory,
      encoding: "utf8",
      timeout: 5000,
    });
    assert.ifError(result.error);
    assert.equal(result.status, 1);
    assert.match(result.stderr, new RegExp(`must show the configured ${cost} gold cost`));
  });
}

for (const [treatment, recruitment] of [[200, 100], [1234567, 4321]]) {
  test(`accepts updated localization for configured costs ${treatment}/${recruitment}`, (t) => {
    const directory = fixture(t);
    changeCost(directory, "hua_tuo_cost", treatment);
    changeCost(directory, "hua_tuo_recruit_cost", recruitment);
    for (const localeFile of localeFiles) {
      const file = join(directory, localeFile);
      const content = readFileSync(file, "utf8").replace(/([12]),?000/g, (_, digit) => {
        const amount = digit === "2" ? treatment : recruitment;
        return /wota_(en|ko)\./.test(localeFile) ? amount.toLocaleString("en-US") : String(amount);
      });
      writeFileSync(file, content);
    }
    assert.doesNotThrow(() => validateLocalizationCosts(directory));
  });
}

for (const [key, cost, text] of [
  [treatmentKey, "2000", "Treat (2,000 gold)"],
  [treatmentKey, "2000", "治療を受ける（2000金）"],
  [treatmentKey, "2000", "支付2000金治疗"],
  [treatmentKey, "2000", "치료받기 (2,000금)"],
  [recruitKey, "1000", "Retain (1,000 gold)"],
  [recruitKey, "1000", "招揽华佗（1000金）"],
]) {
  test(`accepts a complete ${cost} price in ${text}`, (t) => {
    const directory = fixture(t);
    changeRow(directory, localeFiles[0], key, text);
    assert.doesNotThrow(() => validateLocalizationCosts(directory));
  });
}

for (const [key, text] of [
  [treatmentKey, "Treat (12,000 gold)"],
  [treatmentKey, "Treat (20,000 gold)"],
  [treatmentKey, "Treat (20001 gold)"],
  [treatmentKey, "Treat (2,000.50 gold)"],
  [treatmentKey, "Treat (-2,000 gold)"],
  [treatmentKey, "Treat (.2000 gold)"],
  [treatmentKey, "Treat (20,00 gold)"],
  [treatmentKey, "Treat (2,,000 gold)"],
  [recruitKey, "Retain (11,000 gold)"],
  [recruitKey, "Retain (10,000 gold)"],
  [recruitKey, "Retain (10001 gold)"],
  [recruitKey, "Retain (1,000.50 gold)"],
  [recruitKey, "Retain (-1,000 gold)"],
  [treatmentKey, "No price"],
  [recruitKey, ""],
  [treatmentKey, undefined],
]) {
  test(`rejects an incorrect or missing price: ${text}`, (t) => {
    const directory = fixture(t);
    changeRow(directory, localeFiles[0], key, text);
    assert.throws(() => validateLocalizationCosts(directory), (error) => {
      assert.ok(error.message.includes(localeFiles[0]));
      assert.ok(error.message.includes(key));
      return true;
    });
  });
}

// Discover paid rows from the original data rather than importing the validator's
// key sets, so an accidentally omitted label or description fails this coverage.
for (const localeFile of localeFiles) {
  const paidRows = readFileSync(join(root, localeFile), "utf8")
    .split(/\r?\n/)
    .map((line) => line.split("\t"))
    .filter(([key, value]) => key.includes("_dilemma_") && /[12],?000/.test(value));
  assert.equal(paidRows.length, 11, `${localeFile} should contain 11 paid labels/descriptions`);
  for (const [key] of paidRows) {
    test(`checks ${localeFile}: ${key}`, (t) => {
      const directory = fixture(t);
      changeRow(directory, localeFile, key, "Wrong price (9999)");
      assert.throws(() => validateLocalizationCosts(directory), (error) => {
        assert.ok(error.message.includes(localeFile));
        assert.ok(error.message.includes(key));
        return true;
      });
    });
  }
}
