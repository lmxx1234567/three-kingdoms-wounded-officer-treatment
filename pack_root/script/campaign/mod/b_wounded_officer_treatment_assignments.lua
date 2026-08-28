-- Wounded Officer Treatment Assignments
-- Total War: THREE KINGDOMS 1.7.x

local cfg = WOTA_CONFIG or {}
local SAVE_PREFIX = "WOTA_TREATMENT_"

local function log(message)
    out("[WOTA] " .. tostring(message))
end

local function safe_call(object, method_name, fallback)
    if not object or not object[method_name] then return fallback end
    local ok, result = pcall(function() return object[method_name](object) end)
    if ok then return result end
    return fallback
end

local function character_cqi(character)
    return safe_call(character, "command_queue_index", 0)
end

local function treatment_key(cqi, suffix)
    return SAVE_PREFIX .. tostring(cqi) .. "_" .. suffix
end

local function context_turn(context)
    local model = safe_call(context, "query_model", nil)
    if model then return safe_call(model, "turn_number", 0) end
    return 0
end

local function active_assignment_key(character)
    local assignment = safe_call(character, "active_assignment", nil)
    if not assignment or safe_call(assignment, "is_null_interface", true) then return "" end
    return safe_call(assignment, "assignment_record_key", "")
end

local function is_treatment_assignment(key)
    return key == cfg.rest_assignment_key or key == cfg.doctor_assignment_key
end

local function ceo_list(character)
    local management = safe_call(character, "ceo_management", nil)
    if not management or safe_call(management, "is_null_interface", true) then return nil end
    return safe_call(management, "all_ceos", nil)
end

local function character_has_ceo(character, wanted_key)
    local list = ceo_list(character)
    if not list then return false end
    for i = 0, list:num_items() - 1 do
        local ceo = list:item_at(i)
        if ceo and not ceo:is_null_interface() and ceo:ceo_data_key() == wanted_key then
            return true
        end
    end
    return false
end

local function has_configured_wound(character)
    for i = 1, #(cfg.severe_wound_ceos or {}) do
        if character_has_ceo(character, cfg.severe_wound_ceos[i]) then return true end
    end
    return false
end

local function clear_treatment(cqi)
    cm:set_saved_value(treatment_key(cqi, "assignment"), "")
    cm:set_saved_value(treatment_key(cqi, "due_turn"), 0)
end

local function register_or_cancel_treatment(context)
    local character = context:query_character()
    if not character or character:is_null_interface() then return end

    local faction = character:faction()
    if cfg.human_factions_only and (not faction or not faction:is_human()) then return end

    local cqi = character_cqi(character)
    if cqi <= 0 then return end

    local active_key = active_assignment_key(character)
    local saved_key = cm:get_saved_value(treatment_key(cqi, "assignment")) or ""

    if is_treatment_assignment(active_key) then
        if not has_configured_wound(character) then
            clear_treatment(cqi)
            log("Treatment ignored because patient has no configured wound; cqi=" .. cqi)
            return
        end

        if saved_key ~= active_key then
            local duration = (cfg.assignment_duration or {})[active_key] or 1
            cm:set_saved_value(treatment_key(cqi, "assignment"), active_key)
            cm:set_saved_value(treatment_key(cqi, "due_turn"), context_turn(context) + duration)
            log("Treatment started; cqi=" .. cqi .. " assignment=" .. active_key .. " duration=" .. duration)
        end
    elseif saved_key ~= "" then
        -- The player recalled or replaced the assignment before its due turn.
        local due_turn = cm:get_saved_value(treatment_key(cqi, "due_turn")) or 0
        if context_turn(context) < due_turn then
            clear_treatment(cqi)
            log("Treatment cancelled before completion; cqi=" .. cqi)
        end
    end
end

local function replace_wounds(context, character)
    local management = character:ceo_management()
    local modify_management = context:modify_model():get_modify_character_ceo_management(management)
    if not modify_management or modify_management:is_null_interface() then return false end

    local removed = false
    for i = 1, #(cfg.severe_wound_ceos or {}) do
        local wound_key = cfg.severe_wound_ceos[i]
        if character_has_ceo(character, wound_key) then
            modify_management:remove_ceos(wound_key)
            removed = true
            if not cfg.heal_all_configured_wounds then break end
        end
    end

    if removed and cfg.recovery_ceo and cfg.recovery_ceo ~= "" then
        if not character_has_ceo(character, cfg.recovery_ceo) then
            modify_management:add_ceo(cfg.recovery_ceo)
        end
    end
    return removed
end

local function complete_due_treatments(context)
    local faction = context:faction()
    if cfg.human_factions_only and not faction:is_human() then return end

    local now = context:query_model():turn_number()
    local characters = faction:character_list()
    for i = 0, characters:num_items() - 1 do
        local character = characters:item_at(i)
        if character and not character:is_null_interface() then
            local cqi = character_cqi(character)
            local saved_key = cm:get_saved_value(treatment_key(cqi, "assignment")) or ""
            local due_turn = cm:get_saved_value(treatment_key(cqi, "due_turn")) or 0
            if is_treatment_assignment(saved_key) and due_turn > 0 and now >= due_turn then
                -- Automatic assignment expiry can clear active_assignment before
                -- FactionTurnStart, so the saved due turn is authoritative here.
                local healed = replace_wounds(context, character)
                clear_treatment(cqi)
                log("Treatment completed; cqi=" .. cqi .. " healed=" .. tostring(healed))
            end
        end
    end
end

local function init()
    if cfg.enabled == false then
        log("Disabled by configuration")
        return
    end

    core:add_listener(
        "WOTA_RegisterTreatment",
        "CharacterTurnEnd",
        function(context)
            local character = context:query_character()
            return character and not character:is_null_interface()
        end,
        register_or_cancel_treatment,
        true
    )

    core:add_listener(
        "WOTA_CompleteTreatment",
        "FactionTurnStart",
        function(context)
            return (not cfg.human_factions_only) or context:faction():is_human()
        end,
        complete_due_treatments,
        true
    )

    log("Initialized")
end

init()
