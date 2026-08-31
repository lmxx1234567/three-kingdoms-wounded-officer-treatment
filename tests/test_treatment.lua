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

local function make_character(cqi, assignment_key, wounds)
    local character = { cqi = cqi, assignment_key = assignment_key, wounds = wounds or {} }
    local faction = { human = true }
    function faction:is_human() return self.human end
    function character:faction() return faction end
    function character:is_null_interface() return false end
    function character:command_queue_index() return self.cqi end
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

local function make_modify_model(character)
    return {
        get_modify_character_ceo_management = function()
            return {
                is_null_interface = function() return false end,
                remove_ceos = function(_, key) character.wounds[key] = nil end,
                add_ceo = function(_, key) character.wounds[key] = true end
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
    return {
        faction = function() return faction end,
        query_model = function() return { turn_number = function() return turn end } end,
        modify_model = function() return make_modify_model(character) end
    }
end

local function assert_true(value, message)
    if not value then error(message, 2) end
end

dofile(script_root .. "/a_wota_config.lua")
dofile(script_root .. "/b_wounded_officer_treatment_assignments.lua")

local maimed = "3k_main_ceo_trait_physical_maimed_leg"
local scarred = "3k_main_ceo_trait_physical_scarred"

-- Four-turn recuperation.
local c1, f1 = make_character(101, WOTA_CONFIG.rest_assignment_key, { [maimed] = true })
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

print("WOTA tests passed")
