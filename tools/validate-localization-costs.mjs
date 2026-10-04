import { readFileSync } from "node:fs";
import { resolve } from "node:path";

function showsCost(value, cost) {
  // Keep numeric punctuation/signs in each token so neither a longer amount nor
  // a decimal/negative amount can match an integer price. Commas may group
  // thousands; currency text can directly adjoin the digits in JA/ZH/KO.
  const numbers = value.match(/[+-]?(?:\d[\d,.]*\d|\d|\.\d+)/g) ?? [];
  return numbers.some((number) => /^(?:\d+|\d{1,3}(?:,\d{3})+)$/.test(number)
    && number.replaceAll(",", "") === cost);
}

function configuredCost(root, name) {
  const config = readFileSync(resolve(root, "pack_root/script/campaign/mod/a_wota_config.lua"), "utf8");
  const match = config.match(new RegExp(`WOTA_CONFIG\\.${name}\\s*=\\s*(\\d+)`));
  if (!match) throw new Error(`Could not read WOTA_CONFIG.${name}`);
  return match[1];
}

export function validateLocalizationCosts(root = process.cwd()) {
  const treatmentCost = configuredCost(root, "hua_tuo_cost");
  const recruitCost = configuredCost(root, "hua_tuo_recruit_cost");
  const treatmentKeys = new Set([
    "dilemmas_localised_description_wota_dilemma_hua_tuo_visits",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visitsFIRST",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_recruitFIRST",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_manualFIRST",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_bothFIRST",
    "dilemmas_localised_description_wota_dilemma_physician_visits",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_physician_visitsFIRST",
  ]);
  const recruitKeys = new Set([
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_recruitSECOND",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_bothSECOND",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_recruit_onlyFIRST",
    "cdir_events_dilemma_choice_details_localised_choice_label_wota_dilemma_hua_tuo_visits_rewards_onlyFIRST",
  ]);
  const localeFiles = [
    "localization/wota_en.loc.tsv",
    "localization/wota_ja.loc.tsv",
    "localization/wota_ko.loc.tsv",
    "rpfm_import/wota_zh_cn.loc.tsv",
  ];

  for (const localeFile of localeFiles) {
    const localizedRows = new Map(readFileSync(resolve(root, localeFile), "utf8")
      .split(/\r?\n/)
      .map((line) => line.split("\t"))
      .map(([key, value]) => [key, value]));
    for (const [keys, cost] of [[treatmentKeys, treatmentCost], [recruitKeys, recruitCost]]) {
      for (const key of keys) {
        const value = localizedRows.get(key);
        if (!value || !showsCost(value, cost)) {
          throw new Error(`${localeFile} must show the configured ${cost} gold cost for ${key}`);
        }
      }
    }
  }
}
