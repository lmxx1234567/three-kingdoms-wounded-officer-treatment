-- Wounded Officer Treatment Assignments - configuration
-- Keep this file first alphabetically so it loads before the main script.

WOTA_CONFIG = WOTA_CONFIG or {}

WOTA_CONFIG.enabled = true
WOTA_CONFIG.rest_assignment_key = "wota_assignment_recuperate"
WOTA_CONFIG.doctor_assignment_key = "wota_assignment_seek_physician"

-- Duration is also defined in character_assignments_tables. These values are
-- used by the save-safe completion tracker and must match the DB rows.
WOTA_CONFIG.assignment_duration = {
    wota_assignment_recuperate = 4,
    wota_assignment_seek_physician = 1
}

-- The first four are verified vanilla permanent wound CEOs. Additional keys
-- can be appended by an MTU/TUP/WDG2 compatibility submod.
WOTA_CONFIG.severe_wound_ceos = {
    "3k_main_ceo_trait_physical_maimed_arm",
    "3k_main_ceo_trait_physical_maimed_leg",
    "3k_main_ceo_trait_physical_one-eyed",
    "3k_main_ceo_trait_physical_blind"
}

WOTA_CONFIG.recovery_ceo = "3k_main_ceo_trait_physical_scarred"
WOTA_CONFIG.heal_all_configured_wounds = true
WOTA_CONFIG.human_factions_only = true

