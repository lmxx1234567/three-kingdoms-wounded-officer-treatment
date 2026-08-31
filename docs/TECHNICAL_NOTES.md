# Technical notes

The assignment DB applies the initiation cost and duration. Lua never deducts treasury, preventing double charges.

`CharacterTurnEnd` observes a newly started assignment and saves its due turn. `FactionTurnStart` heals when the due turn is reached. If the active assignment disappears before that due turn, `CharacterTurnEnd` clears the saved treatment as a recall/cancellation.

Automatic expiry may remove `active_assignment()` before `FactionTurnStart`; for this reason the saved due turn is authoritative on the completion turn.

The script uses the public 3K interfaces `active_assignment`, `assignment_record_key`, character CEO query management, and modify-character CEO management (`remove_ceos`, `add_ceo`).

## Follow-up work requiring the complete game installation

The repository contains the mod data and scripts, but not the vanilla Three Kingdoms
pack files or the game executable. The local Three Kingdoms installation is now
configured in RPFM. The icon resource and database semantics below have been verified against the installed
vanilla `database.pack`. The Pack has been rebuilt and verified to reach the campaign
loading path; assignment behavior and broader compatibility still require regression checks.

### 1. Enumerate and select a vanilla assignment icon — verified

- Load the vanilla CA packs in RPFM and enumerate the `ui` resources, especially PNG
  files whose paths contain `icon`, `character`, `assignment`, `heal`, `wound`,
  `physician`, or related terms.
- Preview candidate images and record their exact virtual pack paths, dimensions,
  format, and alpha-channel behavior.
- Check whether the icon is stored in `data.pack` or a patch/DLC pack, so the mod does
  not depend on an optional DLC unnecessarily.
- The verified shared treatment icon is
  `/ui/campaign ui/effect_bundles/resilience.png`, used by the vanilla
  `3k_ytr_assignment_healing_rituals` assignment.

### 2. Verify `icon_path` semantics in the vanilla database — verified

- Compare vanilla rows in `ui_character_assignments_tables` and
  `ui_character_assignment_categories_tables` to determine whether the assignment
  icon, category icon, or both are read by the assignment panel.
- Confirm whether an empty `icon_path` falls back to a generic icon, renders an empty
  slot, or produces a missing-resource warning.
- Check whether the path is case-sensitive and whether it must use the virtual `ui/...`
  path, including the file extension.
- Vanilla assignment rows use the effect-bundle path in `ui_character_assignments_tables`;
  category rows use the assignment-slot path in
  `ui_character_assignment_categories_tables`. The mod reuses the verified resilience
  icon for both treatment assignments and the vanilla Man slot icon for the custom
  treatment category.

### 3. Apply and validate the icon change — source applied

- Fill the selected path in `rpfm_import/ui_character_assignments_tables__wota_ui.tsv`
  and/or `rpfm_import/ui_character_assignment_categories_tables__wota_category.tsv`,
  according to the vanilla behavior discovered above.
- Rebuild `dist/wounded_officer_treatment_assignments.pack` with the configured RPFM
  schema and run RPFM diagnostics against the resulting pack.
- Confirm that the pack contains no unintended vanilla assets and that the icon path
  resolves through the game's virtual file system.
- Rebuild or re-check any language packs if the icon is supplied through a shared UI
  table rather than localization.

### 4. Perform in-game UI regression testing

- Start a new campaign for the main campaign and each supported DLC campaign group.
- Give a qualifying permanently wounded officer each treatment assignment and verify
  that the icon appears in the assignment list, assignment details, active-assignment
  view, and any completion/cancellation notification that exposes the assignment icon.
- Check normal, disabled, selected, hover, and tooltip states at common UI scales and
  resolutions. Confirm that the icon is not cropped, blurred, or visually confused with
  a military assignment.
- Test with the intended compatibility stack (including MTU, TUP, and WDG2 where
  applicable) and verify that no UI resource conflict or load-order issue is introduced.

### 5. Complete runtime behavior verification

- Verify assignment availability, initiation cost, duration, and severe-wound
  constraints in an actual campaign rather than only through Lua tests.
- End turns through treatment completion, early recall, save/load, and automatic
  assignment expiry paths. Confirm that the icon and assignment state remain correct
  in each path.
- Verify that treatment still removes the configured severe wound and adds `Scarred`,
  and that no treasury double-charge occurs.
- Capture the game version, active DLCs, enabled mods, and test results so the release
  notes can state the tested environment.

These checks should be treated as release-blocking for an icon change or any change to
the assignment tables. Repository-only checks can validate TSV shape, Lua syntax, pack
contents, and deterministic script tests, but they cannot establish that a referenced
vanilla UI resource exists or that the game renders it correctly.
