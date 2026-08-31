import { existsSync } from "node:fs";
import { resolve } from "node:path";

const packPath = resolve(process.argv[2] ?? "dist/wounded_officer_treatment_assignments.pack");
if (!existsSync(packPath)) throw new Error("Pack not found");

const ws = new WebSocket("ws://127.0.0.1:45127/ws");
let nextId = 1;
let session;
const pending = new Map();

ws.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.data && Object.hasOwn(message.data, "SessionConnected")) {
    session?.(message.data.SessionConnected);
    return;
  }
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  if (message.data && Object.hasOwn(message.data, "Error")) request.reject(new Error(message.data.Error));
  else request.resolve(message.data);
});

await new Promise((resolvePromise, rejectPromise) => {
  ws.addEventListener("open", resolvePromise, { once: true });
  ws.addEventListener("error", rejectPromise, { once: true });
});
await new Promise((resolvePromise) => { session = resolvePromise; });

function send(data) {
  return new Promise((resolvePromise, rejectPromise) => {
    const id = nextId++;
    pending.set(id, { resolve: resolvePromise, reject: rejectPromise });
    ws.send(JSON.stringify({ id, data }));
  });
}

const [packKey] = (await send({ OpenPackFiles: [packPath] })).StringContainerInfo;
await send({ SetGameSelected: ["three_kingdoms", false] });
const tree = await send({ GetPackFileDataForTreeView: packKey });
const files = tree.ContainerInfoVecRFileInfo[1];
console.log(`Pack type: ${tree.ContainerInfoVecRFileInfo[0].pfh_file_type}`);
console.log(`Files: ${files.length}`);

for (const file of files.filter((entry) => entry.file_type === "DB")) {
  const decoded = await send({ DecodePackedFile: [packKey, file.path, "PackFile"] });
  const db = decoded.DBRFileInfo[0].table;
  console.log(`${file.path}: version=${db.definition.version}, rows=${db.table_data.length}`);
}

let diagnostics = await send({ DiagnosticsCheck: [[], false] });
const missingCache = diagnostics.Diagnostics.results.some(
  (entry) => entry.Config?.results?.some((result) => result.report_type === "DependenciesCacheNotGenerated"),
);
if (missingCache) {
  console.log("Generating dependencies cache...");
  await send("GenerateDependenciesCache");
  diagnostics = await send({ DiagnosticsCheck: [[], false] });
}
for (const result of diagnostics.Diagnostics.results) {
  if (!result.DB) continue;
  for (const item of result.DB.results) {
    console.log(`Diagnostic ${result.DB.path}: ${JSON.stringify(item.report_type)}`);
  }
}

const dependencyAssignments = await send({
  GetTablesFromDependencies: "campaign_group_character_assignments_tables",
});
for (const file of dependencyAssignments.VecRFile) {
  const table = file.data.Decoded.DB.table;
  console.log(`Vanilla ${file.path}: rows=${table.table_data.length}`);
  const groups = new Map();
  for (const row of table.table_data) {
    const group = Object.values(row[0])[0];
    const assignment = Object.values(row[1])[0];
    if (!groups.has(group)) groups.set(group, []);
    groups.get(group).push(assignment);
  }
  for (const [group, assignments] of [...groups].sort(([left], [right]) => left.localeCompare(right))) {
    console.log(`${group}\t${assignments.length}\t${assignments.join(",")}`);
  }
}

ws.close();
