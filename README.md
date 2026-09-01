# Wounded Officer Treatment Assignments

[简体中文](README.zh-CN.md)

## Steam Workshop

| Item | Workshop |
| --- | --- |
| Main mod | [Wounded Officer Treatment Assignments](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327386) |
| English translation | [English Translation](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327818) |
| Japanese translation | [日本語翻訳](https://steamcommunity.com/sharedfiles/filedetails/?id=3793327897) |
| Korean translation | [한국어 번역](https://steamcommunity.com/sharedfiles/filedetails/?id=3793328007) |

The three translation Packs require the main mod. Subscribe to the main mod first, then enable exactly one translation Pack.

A campaign mod for **Total War: THREE KINGDOMS 1.7.x** that lets permanently injured officers recover through two character assignments or a chance encounter with Hua Tuo.

The mod is faction-neutral. Its event does not require Hua Tuo to be recruited, nor does the mod depend on the Faction Council or any Yellow Turban council mechanic. Simplified Chinese is included in the main Pack; English, Japanese, and Korean are provided as separate language Packs.

## Hua Tuo random event

When an army containing a permanently injured officer is **garrisoned in a settlement and actively replenishing**, there is a 10% chance each turn that Hua Tuo visits. One eligible officer is selected at random. Paying 2,000 gold immediately replaces that officer's configured severe wounds with `Scarred`; declining costs nothing.

If the vanilla unique Hua Tuo follower is not owned anywhere in the campaign, the faction may pay 1,000 gold to retain him. If the unique Hua Tuo's Manual is unowned, the faction may instead imprison Hua Tuo and seize it, giving all current faction characters -10 satisfaction for five turns. Neither Easter-egg choice also treats the selected patient.

Hua Tuo can still travel and offer treatment while either ancillary belongs to another faction; only the corresponding unique reward is hidden. After a faction successfully recruits Hua Tuo or seizes the manual, its future encounters become two-choice visits from unnamed renowned physicians. The event has an eight-turn cooldown. Chance, costs, and cooldown are configurable in `pack_root/script/campaign/mod/a_wota_config.lua`.

## Assignments

| Assignment | Cost | Duration | Result |
| --- | ---: | ---: | --- |
| Recuperate locally | Free | 4 turns | Replaces configured permanent wounds with `Scarred` |
| Seek a Renowned Physician | 4,000 | 1 turn | Replaces configured permanent wounds with `Scarred` |

Both assignments are performed by the injured officer. Local recuperation is free; foreign physician treatment costs 4000. Recalling an officer before treatment finishes cancels recovery, does not refund the physician fee, and adds no extra recall delay.

By default, one completed treatment removes all configured severe wounds from that officer and adds:

```text
3k_main_ceo_trait_physical_scarred
```

Supported vanilla wound CEOs:

```text
3k_main_ceo_trait_physical_maimed_arm
3k_main_ceo_trait_physical_maimed_leg
3k_main_ceo_trait_physical_one-eyed
3k_main_ceo_trait_physical_blind
```

## Installation

1. Download [`dist/wounded_officer_treatment_assignments.pack`](dist/wounded_officer_treatment_assignments.pack).
2. Copy it into the game's `data` directory.
3. Enable it in the Total War launcher.
4. Place it after MTU, TUP, and WDG2 in the load order.
5. Test with a backup save first.

## Languages

The main Pack uses **Simplified Chinese by default**. Players using another language should enable exactly one language Pack after the main Pack:

| Language | Pack |
| --- | --- |
| Simplified Chinese | Included in `wounded_officer_treatment_assignments.pack` |
| English | [`wota_translation_en.pack`](dist/localization/wota_translation_en.pack) |
| Japanese | [`wota_translation_ja.pack`](dist/localization/wota_translation_ja.pack) |
| Korean | [`wota_translation_ko.pack`](dist/localization/wota_translation_ko.pack) |

Load order example:

```text
wounded_officer_treatment_assignments.pack
wota_translation_en.pack
```

Do not enable multiple translation Packs together because they intentionally override the same localisation keys.

## Compatibility

All custom records use the `wota_` prefix, and the mod does not overwrite vanilla, MTU, TUP, or WDG2 rows. It works directly with characters that use the supported vanilla wound CEOs.

For an overhaul-specific wound CEO, add the key in both places:

- `pack_root/script/campaign/mod/a_wota_config.lua`
- `rpfm_import/character_assignment_constraint_set_required_ceos_tables__wota_wounds.tsv`

The Lua entry enables treatment; the DB entry makes the assignments appear for that wound.

The included Pack covers the main campaign and DLC campaign-group records currently configured in [`docs/COMPATIBILITY_CONFIG.tsv`](docs/COMPATIBILITY_CONFIG.tsv). These references should be checked against the user's installed `database.pack` when testing on Windows.

## Project layout

```text
dist/                  Compiled Mod-type PFH5 Pack
dist/localization/     Optional English, Japanese, and Korean Loc Packs
localization/          Translation source TSV files
pack_root/             Campaign Lua scripts
rpfm_import/           RPFM-ready DB and Loc TSV files
tests/                 Host-side Lua logic test
docs/                  Technical and compatibility notes
workshop/              Workshop previews, content mirrors, VDF templates, and publishing notes
```

## Testing status

Passed offline:

- Lua syntax validation
- Four-turn treatment timing
- One-turn treatment timing
- Early-recall cancellation
- Hua Tuo/physician settlement eligibility, dynamic unique-ancillary choices, costs, and cooldown
- Recruitment/confiscation terminal state, world-wide unique CEO checks, and five-turn satisfaction penalty
- TSV structure validation
- RPFM binary compilation
- Binary DB and Loc round-trip export
- English, Japanese, and Korean Loc Pack round-trip export

In-game UI and dependency testing is pending on Windows with **Total War: THREE KINGDOMS** installed.

Run the host-side logic test with:

```bash
lua tests/test_treatment.lua pack_root/script/campaign/mod
```

## Building with RPFM

With RPFM 5.x, start `rpfm_server` and run the repository build client:

```bash
node --experimental-websocket tools/build-rpfm.mjs
```

The client opens the existing Pack, imports the changed TSV files from `rpfm_import`,
and writes the rebuilt Pack under `build/`. It accepts an optional source Pack and
output Pack path. The TSV files already contain RPFM metadata rows and correct internal
Pack paths. For a manual build, create a Mod-type Pack for Three Kingdoms, import
`pack_root/script`, then mass-import the TSV files from `rpfm_import`.

See [`docs/TECHNICAL_NOTES.md`](docs/TECHNICAL_NOTES.md) for the completion tracker design.

## License

Licensed under the [MIT License](LICENSE).
