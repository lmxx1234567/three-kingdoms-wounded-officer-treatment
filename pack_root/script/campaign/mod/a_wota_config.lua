-- Wounded Officer Treatment Assignments - configuration
-- Keep this file first alphabetically so it loads before the main script.

WOTA_CONFIG = WOTA_CONFIG or {}

WOTA_CONFIG.enabled = true
WOTA_CONFIG.rest_assignment_key = "wota_assignment_recuperate"
WOTA_CONFIG.doctor_assignment_key = "wota_assignment_seek_physician"

-- Hua Tuo may visit a settlement where a wounded officer's army is
-- garrisoned and actively replenishing. The dilemma is script-triggered.
WOTA_CONFIG.hua_tuo_event_enabled = true
WOTA_CONFIG.hua_tuo_dilemma_key = "wota_dilemma_hua_tuo_visits"
WOTA_CONFIG.hua_tuo_dilemma_keys = {
    basic = "wota_dilemma_hua_tuo_visits",
    follower = "wota_dilemma_hua_tuo_visits_recruit",
    manual = "wota_dilemma_hua_tuo_visits_manual",
    both = "wota_dilemma_hua_tuo_visits_both",
    recruit_only = "wota_dilemma_hua_tuo_visits_recruit_only",
    manual_only = "wota_dilemma_hua_tuo_visits_manual_only",
    rewards_only = "wota_dilemma_hua_tuo_visits_rewards_only"
}
WOTA_CONFIG.physician_dilemma_key = "wota_dilemma_physician_visits"
WOTA_CONFIG.hua_tuo_cost = 2000
WOTA_CONFIG.hua_tuo_recruit_cost = 1000
WOTA_CONFIG.hua_tuo_chance_percent = 10
WOTA_CONFIG.hua_tuo_cooldown_turns = 8
WOTA_CONFIG.hua_tuo_follower_ceo = "3k_main_ancillary_follower_hua_tuo"
WOTA_CONFIG.hua_tuo_manual_ceo = "3k_main_ancillary_accessory_hua_tuos_manual"
WOTA_CONFIG.hua_tuo_confiscation_loyalty_effect = "wota_loyalty_effect_hua_tuo_confiscated"

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
