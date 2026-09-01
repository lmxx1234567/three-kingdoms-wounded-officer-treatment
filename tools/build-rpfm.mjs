import { existsSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";

const [, , sourcePackArg = "dist/wounded_officer_treatment_assignments.pack", outputPackArg] = process.argv;
const sourcePack = resolve(sourcePackArg);
const outputPack = resolve(outputPackArg ?? "build/wounded_officer_treatment_assignments.pack");
if (!globalThis.WebSocket) {
  fail("WebSocket is unavailable; on Node.js 20 run with --experimental-websocket");
}
const ws = new globalThis.WebSocket("ws://127.0.0.1:45127/ws");
let nextId = 1;
let sessionReady;
const pending = new Map();

function fail(message) {
  throw new Error(message);
}

function send(data) {
  return new Promise((resolvePromise, rejectPromise) => {
    const id = nextId++;
    pending.set(id, { resolve: resolvePromise, reject: rejectPromise });
    ws.send(JSON.stringify({ id, data }));
  });
}

ws.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.data && Object.hasOwn(message.data, "SessionConnected")) {
    sessionReady?.(message.data.SessionConnected);
    return;
  }
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  if (message.data && Object.hasOwn(message.data, "Error")) {
    request.reject(new Error(message.data.Error));
  } else {
    request.resolve(message.data);
  }
});

ws.addEventListener("error", (event) => {
  for (const request of pending.values()) request.reject(event.error ?? new Error("RPFM WebSocket error"));
  pending.clear();
});

await new Promise((resolvePromise, rejectPromise) => {
  ws.addEventListener("open", resolvePromise, { once: true });
  ws.addEventListener("error", rejectPromise, { once: true });
});

await new Promise((resolvePromise) => {
  sessionReady = resolvePromise;
});

if (!existsSync(sourcePack)) fail(`Source Pack not found: ${sourcePackArg}`);
mkdirSync(dirname(outputPack), { recursive: true });

const [packKey] = (await send({ OpenPackFiles: [sourcePack] })).StringContainerInfo;
await send({ SetGameSelected: ["three_kingdoms", false] });

const imports = [
  ["rpfm_import/character_assignments_tables__wota_assignments.tsv", "db/character_assignments_tables/wota_assignments"],
  ["rpfm_import/character_assignment_constraint_sets_tables__wota_constraints.tsv", "db/character_assignment_constraint_sets_tables/wota_constraints"],
  ["rpfm_import/character_assignment_constraint_set_required_ceos_tables__wota_wounds.tsv", "db/character_assignment_constraint_set_required_ceos_tables/wota_wounds"],
  ["rpfm_import/resource_transactions_tables__wota_costs.tsv", "db/resource_transactions_tables/wota_costs"],
  ["rpfm_import/campaign_group_character_assignments_tables__wota_campaigns.tsv", "db/campaign_group_character_assignments_tables/wota_campaigns"],
  ["rpfm_import/ui_character_assignments_tables__wota_ui.tsv", "db/ui_character_assignments_tables/wota_ui"],
  ["rpfm_import/ui_character_assignment_categories_tables__wota_category.tsv", "db/ui_character_assignment_categories_tables/wota_category"],
  ["rpfm_import/dilemmas_tables__wota_hua_tuo.tsv", "db/dilemmas_tables/wota_hua_tuo"],
  ["rpfm_import/cdir_events_dilemma_choice_details_tables__wota_hua_tuo.tsv", "db/cdir_events_dilemma_choice_details_tables/wota_hua_tuo"],
  ["rpfm_import/loyalty_factors_tables__wota_hua_tuo.tsv", "db/loyalty_factors_tables/wota_hua_tuo"],
  ["rpfm_import/loyalty_effects_tables__wota_hua_tuo.tsv", "db/loyalty_effects_tables/wota_hua_tuo"],
];

const scriptImports = [
  ["pack_root/script/campaign/mod/a_wota_config.lua", "script/campaign/mod/a_wota_config.lua"],
  ["pack_root/script/campaign/mod/b_wounded_officer_treatment_assignments.lua", "script/campaign/mod/b_wounded_officer_treatment_assignments.lua"],
];

for (const [tsvArg, tablePath] of imports) {
  const tsvPath = resolve(tsvArg);
  if (!existsSync(tsvPath)) fail(`TSV not found: ${tsvArg}`);
  await send({ ImportTSV: [packKey, tablePath, tsvPath] });
  console.log(`Imported ${tsvArg}`);
}

for (const [scriptArg, packPath] of scriptImports) {
  const scriptPath = resolve(scriptArg);
  if (!existsSync(scriptPath)) fail(`Script not found: ${scriptArg}`);
  await send({ AddPackedFiles: [packKey, [scriptPath], [{ File: packPath }], null] });
  console.log(`Imported ${scriptArg}`);
}

await send({ SavePackAs: [packKey, outputPack] });
console.log(`Built ${outputPackArg ?? "build/wounded_officer_treatment_assignments.pack"}`);
ws.close();
