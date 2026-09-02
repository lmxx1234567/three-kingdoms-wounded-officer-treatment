-- Minimal host-side logic test. It validates timing, completion and recall.

local script_root = arg[1] or "../pack_root/script/campaign/mod"

local saved = {}
cm = {
    set_saved_value = function(_, key, value) saved[key] = value end,
    get_saved_value = function(_, key) return saved[key] end
}

function out(_) end

local listeners = {}
core = {
    add_listener = function(_, name, _, condition, callback, _)
        listeners[name] = { condition = condition, callback = callback }
    end
}

local function make_character(cqi, assignment_key, wounds, replenishing_in_settlement)
    local character = {
        cqi = cqi,
        assignment_key = assignment_key,
        wounds = wounds or {},
        loyalty_effects = {}
    }
    local faction = { human = true, treasury_value = 5000, ancillaries = {} }
    function faction:is_null_interface() return false end
    function faction:is_human() return self.human end
    function faction:name() return "faction_" .. tostring(cqi) end
    function faction:command_queue_index() return cqi + 1000 end
    function faction:treasury() return self.treasury_value end
    function faction:ceo_management()
        local owner = self
        return {
            is_null_interface = function() return false end,
            can_create_ceo = function(_, key) return owner.ancillaries[key] ~= true end,
            all_ceos = function()
                local items = {}
                for key, enabled in pairs(owner.ancillaries) do
                    if enabled then
                        items[#items + 1] = {
                            is_null_interface = function() return false end,
                            ceo_data_key = function() return key end
                        }
                    end
                end
                return {
                    num_items = function() return #items end,
                    item_at = function(_, index) return items[index + 1] end
                }
            end
        }
    end
    function character:faction() return faction end
    function character:is_null_interface() return false end
    function character:command_queue_index() return self.cqi end
    function character:has_military_force() return replenishing_in_settlement ~= nil end
    function character:military_force()
        return {
            is_null_interface = function() return false end,
            is_replenishing = function() return replenishing_in_settlement == true end,
            has_garrison_residence = function() return replenishing_in_settlement ~= nil end,
            garrison_residence = function()
                return {
                    is_null_interface = function() return false end,
                    is_settlement = function() return replenishing_in_settlement == true end
                }
            end
        }
    end
    function character:active_assignment()
        if self.assignment_key == "" then return { is_null_interface = function() return true end } end
        return {
            is_null_interface = function() return false end,
            assignment_record_key = function() return self.assignment_key end
        }
    end
    function character:ceo_management()
        local owner = self
        return {
            is_null_interface = function() return false end,
            all_ceos = function()
                local items = {}
                for key, enabled in pairs(owner.wounds) do
                    if enabled then
                        items[#items + 1] = {
                            is_null_interface = function() return false end,
                            ceo_data_key = function() return key end
                        }
                    end
                end
                return {
                    num_items = function() return #items end,
                    item_at = function(_, index) return items[index + 1] end
                }
            end
        }
    end
    return character, faction
end

local function make_modify_model(character, faction)
    return {
        random_number = function(_, minimum, _) return minimum end,
        get_modify_character_ceo_management = function()
            if character.modify_ceo_unavailable then
                return { is_null_interface = function() return true end }
            end
            return {
                is_null_interface = function() return false end,
                remove_ceos = function(_, key) character.wounds[key] = nil end,
                add_ceo = function(_, key) character.wounds[key] = true end
            }
        end,
        get_modify_faction = function()
            return {
                is_null_interface = function() return false end,
                trigger_dilemma = function(_, key)
                    if faction.trigger_dilemma_error then error("trigger failed") end
                    faction.triggered_dilemma = key
                end,
                decrease_treasury = function(_, amount)
                    faction.treasury_value = faction.treasury_value - amount
                end,
                ceo_management = function()
                    return {
                        is_null_interface = function() return false end,
                        add_ceo = function(_, key) faction.ancillaries[key] = true end
                    }
                end
            }
        end,
        get_modify_character = function(_, target)
            return {
                is_null_interface = function() return false end,
                add_loyalty_effect = function(_, key) target.loyalty_effects[key] = true end
            }
        end
    }
end

local function end_context(character, turn)
    return {
        query_character = function() return character end,
        query_model = function() return { turn_number = function() return turn end } end
    }
end

local function start_context(character, faction, turn)
    function faction:character_list()
        return {
            num_items = function() return 1 end,
            item_at = function() return character end
        }
    end
    local model = {
        turn_number = function() return turn end,
        character_for_command_queue_index = function(_, cqi)
            if cqi == character.cqi then return character end
            return { is_null_interface = function() return true end }
        end,
        world = function()
            return {
                is_null_interface = function() return false end,
                faction_list = function()
                    local items = faction.world_factions or { faction }
                    return {
                        num_items = function() return #items end,
                        item_at = function(_, index) return items[index + 1] end
                    }
                end,
                character_list = function()
                    local items = faction.world_characters or { character }
                    return {
                        num_items = function() return #items end,
                        item_at = function(_, index) return items[index + 1] end
                    }
                end
            }
        end
    }
    local modify_model = make_modify_model(character, faction)
    return {
        faction = function() return faction end,
        query_model = function() return model end,
        modify_model = function() return modify_model end
    }
end

local function dilemma_context(character, faction, choice, turn)
    local context = start_context(character, faction, turn)
    context.choice = function() return choice end
    context.dilemma = function() return faction.triggered_dilemma or WOTA_CONFIG.hua_tuo_dilemma_key end
    return context
end

local function assert_true(value, message)
    if not value then error(message, 2) end
end

dofile(script_root .. "/a_wota_config.lua")
dofile(script_root .. "/b_wounded_officer_treatment_assignments.lua")
dofile(script_root .. "/c_wounded_officer_treatment_hua_tuo.lua")

local maimed = "3k_main_ceo_trait_physical_maimed_leg"
local scarred = "3k_main_ceo_trait_physical_scarred"

-- Four-turn recuperation.
local c1, f1 = make_character(101, WOTA_CONFIG.rest_assignment_key, { [maimed] = true })
listeners.WOTA_RegisterTreatment.callback(end_context(c1, 10))
listeners.WOTA_RegisterTreatment.callback(end_context(c1, 10))
listeners.WOTA_CompleteTreatment.callback(start_context(c1, f1, 13))
assert_true(c1.wounds[maimed], "recuperation completed one turn early")
listeners.WOTA_CompleteTreatment.callback(start_context(c1, f1, 14))
assert_true(not c1.wounds[maimed] and c1.wounds[scarred], "recuperation did not heal on turn four")

-- One-turn physician search.
local c2, f2 = make_character(102, WOTA_CONFIG.doctor_assignment_key, { [maimed] = true })
listeners.WOTA_RegisterTreatment.callback(end_context(c2, 20))
listeners.WOTA_CompleteTreatment.callback(start_context(c2, f2, 21))
assert_true(not c2.wounds[maimed] and c2.wounds[scarred], "physician search did not heal on turn one")

-- Recall before completion cancels treatment.
local c3, f3 = make_character(103, WOTA_CONFIG.rest_assignment_key, { [maimed] = true })
listeners.WOTA_RegisterTreatment.callback(end_context(c3, 30))
c3.assignment_key = ""
listeners.WOTA_RegisterTreatment.callback(end_context(c3, 31))
listeners.WOTA_CompleteTreatment.callback(start_context(c3, f3, 34))
assert_true(c3.wounds[maimed] and not c3.wounds[scarred], "recalled treatment still healed")

-- Hua Tuo can visit a wounded officer whose army is replenishing in a settlement.
local c4, f4 = make_character(104, "", { [maimed] = true }, true)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c4, f4, 40))
assert_true(f4.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.both, "full Hua Tuo dilemma did not trigger")
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c4, f4, 0, 40))
assert_true(f4.treasury_value == 3000, "Hua Tuo treatment did not deduct 2000")
assert_true(not c4.wounds[maimed] and c4.wounds[scarred], "Hua Tuo treatment did not heal patient")

-- Declining the visit has no cost and does not heal.
local c5, f5 = make_character(105, "", { [maimed] = true }, true)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c5, f5, 50))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c5, f5, 3, 50))
assert_true(f5.treasury_value == 5000, "declining Hua Tuo still deducted money")
assert_true(c5.wounds[maimed] and not c5.wounds[scarred], "declining Hua Tuo still healed patient")
f5.triggered_dilemma = nil
listeners.WOTA_TriggerHuaTuo.callback(start_context(c5, f5, 51))
assert_true(not f5.triggered_dilemma, "Hua Tuo ignored the per-faction cooldown")

-- An army that is not replenishing is not eligible even if the officer is wounded.
local c6, f6 = make_character(106, "", { [maimed] = true }, false)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c6, f6, 60))
assert_true(not f6.triggered_dilemma, "Hua Tuo triggered outside settlement replenishment")

-- Below the treatment price, show only the affordable unique-reward choices.
local c7, f7 = make_character(107, "", { [maimed] = true }, true)
f7.treasury_value = 1999
listeners.WOTA_TriggerHuaTuo.callback(start_context(c7, f7, 70))
assert_true(f7.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.rewards_only,
    "unaffordable treatment choice was still shown")

local c7b, f7b = make_character(117, "", { [maimed] = true }, true)
f7b.treasury_value = 999
listeners.WOTA_TriggerHuaTuo.callback(start_context(c7b, f7b, 71))
assert_true(f7b.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.manual_only,
    "unaffordable treatment and recruitment choices were still shown")

local c7c, f7c = make_character(127, "", { [maimed] = true }, true)
f7c.treasury_value = 999
f7c.ancillaries[WOTA_CONFIG.hua_tuo_manual_ceo] = true
listeners.WOTA_TriggerHuaTuo.callback(start_context(c7c, f7c, 72))
assert_true(not f7c.triggered_dilemma,
    "event triggered even though no displayed action could succeed")

local c7d, f7d = make_character(137, "", { [maimed] = true }, true)
f7d.treasury_value = 1999
listeners.WOTA_TriggerHuaTuo.callback(start_context(c7d, f7d, 73))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c7d, f7d, 0, 73))
assert_true(f7d.treasury_value == 999 and f7d.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo],
    "recruit-only affordable layout mapped its first choice incorrectly")

local c7e, f7e = make_character(147, "", { [maimed] = true }, true)
f7e.treasury_value = 999
listeners.WOTA_TriggerHuaTuo.callback(start_context(c7e, f7e, 74))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c7e, f7e, 0, 74))
assert_true(f7e.ancillaries[WOTA_CONFIG.hua_tuo_manual_ceo]
    and c7e.loyalty_effects[WOTA_CONFIG.hua_tuo_confiscation_loyalty_effect],
    "manual-only affordable layout mapped its first choice incorrectly")

-- Recruiting Hua Tuo costs 1,000, grants the unique follower without healing,
-- and permanently changes future visits for this faction to generic physicians.
local c8, f8 = make_character(108, "", { [maimed] = true }, true)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c8, f8, 80))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c8, f8, 1, 80))
assert_true(f8.treasury_value == 4000, "recruiting Hua Tuo did not deduct 1000")
assert_true(f8.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo], "Hua Tuo follower was not granted")
assert_true(c8.wounds[maimed] and not c8.wounds[scarred], "recruiting Hua Tuo also healed the patient")
f8.triggered_dilemma = nil
listeners.WOTA_TriggerHuaTuo.callback(start_context(c8, f8, 88))
assert_true(f8.triggered_dilemma == WOTA_CONFIG.physician_dilemma_key,
    "Hua Tuo recruitment did not switch later visits to generic physicians")

-- Confiscating the manual grants the unique accessory, does not heal, applies
-- the configured loyalty effect, and also concludes this faction's Hua Tuo chain.
local c9, f9 = make_character(109, "", { [maimed] = true }, true)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c9, f9, 90))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c9, f9, 2, 90))
assert_true(f9.ancillaries[WOTA_CONFIG.hua_tuo_manual_ceo], "Hua Tuo's Manual was not granted")
assert_true(c9.loyalty_effects[WOTA_CONFIG.hua_tuo_confiscation_loyalty_effect],
    "confiscation satisfaction penalty was not applied")
assert_true(c9.wounds[maimed] and not c9.wounds[scarred], "confiscating the manual also healed the patient")
f9.triggered_dilemma = nil
listeners.WOTA_TriggerHuaTuo.callback(start_context(c9, f9, 98))
assert_true(f9.triggered_dilemma == WOTA_CONFIG.physician_dilemma_key,
    "manual confiscation did not switch later visits to generic physicians")

-- Existing unique ancillaries hide only their own Easter-egg choices.
local c10, f10 = make_character(110, "", { [maimed] = true }, true)
local _, other10 = make_character(210, "", {}, nil)
other10.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo] = true
f10.world_factions = { f10, other10 }
listeners.WOTA_TriggerHuaTuo.callback(start_context(c10, f10, 100))
assert_true(f10.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.manual,
    "Hua Tuo follower in another faction did not hide recruitment only")

local c11, f11 = make_character(111, "", { [maimed] = true }, true)
local _, other11 = make_character(211, "", {}, nil)
other11.ancillaries[WOTA_CONFIG.hua_tuo_manual_ceo] = true
f11.world_factions = { f11, other11 }
listeners.WOTA_TriggerHuaTuo.callback(start_context(c11, f11, 110))
assert_true(f11.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.follower,
    "Hua Tuo manual in another faction did not hide confiscation only")

local c12, f12 = make_character(112, "", { [maimed] = true }, true)
f12.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo] = true
f12.ancillaries[WOTA_CONFIG.hua_tuo_manual_ceo] = true
listeners.WOTA_TriggerHuaTuo.callback(start_context(c12, f12, 120))
assert_true(f12.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.basic,
    "both owned ancillaries did not leave the basic Hua Tuo dilemma")

-- Availability is checked again when the choice resolves. If another faction
-- acquires the unique follower while the dilemma is open, no money is charged
-- and this faction's Hua Tuo story remains unconcluded.
local c13, f13 = make_character(113, "", { [maimed] = true }, true)
local _, other13 = make_character(213, "", {}, nil)
f13.world_factions = { f13, other13 }
listeners.WOTA_TriggerHuaTuo.callback(start_context(c13, f13, 130))
assert_true(f13.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.both,
    "race-condition setup did not show both choices")
other13.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo] = true
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c13, f13, 1, 130))
assert_true(f13.treasury_value == 5000 and not f13.ancillaries[WOTA_CONFIG.hua_tuo_follower_ceo],
    "unavailable follower was duplicated or still charged")
f13.triggered_dilemma = nil
listeners.WOTA_TriggerHuaTuo.callback(start_context(c13, f13, 138))
assert_true(f13.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.manual,
    "failed unique reward incorrectly concluded the Hua Tuo story")

-- If wound replacement cannot obtain a modify interface, treatment is free and
-- the cooldown is reset so a working visit can be offered again immediately.
local c14, f14 = make_character(114, "", { [maimed] = true }, true)
c14.modify_ceo_unavailable = true
listeners.WOTA_TriggerHuaTuo.callback(start_context(c14, f14, 140))
listeners.WOTA_ResolveHuaTuo.callback(dilemma_context(c14, f14, 0, 140))
assert_true(f14.treasury_value == 5000 and c14.wounds[maimed],
    "failed wound replacement charged money or changed the wound")
c14.modify_ceo_unavailable = false
f14.triggered_dilemma = nil
listeners.WOTA_TriggerHuaTuo.callback(start_context(c14, f14, 141))
assert_true(f14.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.both,
    "failed wound replacement did not reset the cooldown")

-- trigger_dilemma is a void command: no return value is success, while an
-- actual command error clears pending state and cooldown for an immediate retry.
local c15, f15 = make_character(115, "", { [maimed] = true }, true)
listeners.WOTA_TriggerHuaTuo.callback(start_context(c15, f15, 150))
assert_true(f15.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.both,
    "void trigger_dilemma return was treated as failure")

local c16, f16 = make_character(116, "", { [maimed] = true }, true)
f16.trigger_dilemma_error = true
listeners.WOTA_TriggerHuaTuo.callback(start_context(c16, f16, 160))
assert_true(not f16.triggered_dilemma, "failed trigger_dilemma still queued an event")
f16.trigger_dilemma_error = false
listeners.WOTA_TriggerHuaTuo.callback(start_context(c16, f16, 161))
assert_true(f16.triggered_dilemma == WOTA_CONFIG.hua_tuo_dilemma_keys.both,
    "failed trigger_dilemma did not clear pending state and cooldown")

-- Faction callbacks must tolerate nil and null-interface factions.
local nil_faction_context = {
    faction = function() return nil end
}
assert_true(not listeners.WOTA_CompleteTreatment.condition(nil_faction_context), "nil faction passed listener condition")
listeners.WOTA_CompleteTreatment.callback(nil_faction_context)

local null_faction = {
    is_null_interface = function() return true end
}
local null_faction_context = {
    faction = function() return null_faction end
}
assert_true(not listeners.WOTA_CompleteTreatment.condition(null_faction_context), "null faction passed listener condition")
listeners.WOTA_CompleteTreatment.callback(null_faction_context)

print("WOTA tests passed")
