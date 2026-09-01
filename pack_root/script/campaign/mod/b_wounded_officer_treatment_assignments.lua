-- Wounded Officer Treatment Assignments
-- Total War: THREE KINGDOMS 1.7.x

local cfg = WOTA_CONFIG or {}
local SAVE_PREFIX = "WOTA_TREATMENT_"
local HUA_TUO_PENDING_PREFIX = "WOTA_HUA_TUO_PENDING_"
local HUA_TUO_COOLDOWN_PREFIX = "WOTA_HUA_TUO_COOLDOWN_"
local HUA_TUO_CONCLUDED_PREFIX = "WOTA_HUA_TUO_CONCLUDED_"

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

local function faction_cqi(faction)
    return safe_call(faction, "command_queue_index", 0)
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

local function list_has_ceo(list, wanted_key)
    if not list or not list.num_items or not list.item_at then return false end
    for i = 0, list:num_items() - 1 do
        local ceo = list:item_at(i)
        if ceo and not safe_call(ceo, "is_null_interface", true)
            and safe_call(ceo, "ceo_data_key", "") == wanted_key then
            return true
        end
    end
    return false
end

local function character_has_ceo(character, wanted_key)
    return list_has_ceo(ceo_list(character), wanted_key)
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

local function hua_tuo_pending_key(faction)
    return HUA_TUO_PENDING_PREFIX .. tostring(faction_cqi(faction))
end

local function hua_tuo_cooldown_key(faction)
    return HUA_TUO_COOLDOWN_PREFIX .. tostring(faction_cqi(faction))
end

local function hua_tuo_concluded_key(faction)
    return HUA_TUO_CONCLUDED_PREFIX .. tostring(faction_cqi(faction))
end

local function faction_ceo_management(faction)
    local management = safe_call(faction, "ceo_management", nil)
    if not management or safe_call(management, "is_null_interface", true) then return nil end
    return management
end

local function faction_has_ceo(faction, wanted_key)
    local management = faction_ceo_management(faction)
    if not management then return false end
    return list_has_ceo(safe_call(management, "all_ceos", nil), wanted_key)
end

local function world_has_ceo(model, wanted_key)
    local world = safe_call(model, "world", nil)
    if not world or safe_call(world, "is_null_interface", true) then return false end

    local factions = safe_call(world, "faction_list", nil)
    if factions and factions.num_items and factions.item_at then
        for i = 0, factions:num_items() - 1 do
            local faction = factions:item_at(i)
            if faction and not safe_call(faction, "is_null_interface", true)
                and faction_has_ceo(faction, wanted_key) then
                return true
            end
        end
    end

    local characters = safe_call(world, "character_list", nil)
    if characters and characters.num_items and characters.item_at then
        for i = 0, characters:num_items() - 1 do
            local character = characters:item_at(i)
            if character and not safe_call(character, "is_null_interface", true)
                and character_has_ceo(character, wanted_key) then
                return true
            end
        end
    end
    return false
end

local function faction_can_receive_ceo(model, faction, wanted_key)
    if not wanted_key or wanted_key == "" or world_has_ceo(model, wanted_key) then return false end
    local management = faction_ceo_management(faction)
    if not management then return false end
    local ok, can_create = pcall(function() return management:can_create_ceo(wanted_key) end)
    return ok and can_create == true
end

local function hua_tuo_dilemma_for(model, faction)
    if cm:get_saved_value(hua_tuo_concluded_key(faction)) == true then
        return cfg.physician_dilemma_key, false, false
    end

    local follower_available = faction_can_receive_ceo(model, faction, cfg.hua_tuo_follower_ceo)
    local manual_available = faction_can_receive_ceo(model, faction, cfg.hua_tuo_manual_ceo)
    local keys = cfg.hua_tuo_dilemma_keys or {}
    if follower_available and manual_available then
        return keys.both or cfg.hua_tuo_dilemma_key, true, true
    elseif follower_available then
        return keys.follower or cfg.hua_tuo_dilemma_key, true, false
    elseif manual_available then
        return keys.manual or cfg.hua_tuo_dilemma_key, false, true
    end
    return keys.basic or cfg.hua_tuo_dilemma_key, false, false
end

local function dilemma_action(dilemma_key, choice)
    local keys = cfg.hua_tuo_dilemma_keys or {}
    if dilemma_key == (keys.both or "") then
        return ({ [0] = "treat", [1] = "recruit", [2] = "confiscate", [3] = "decline" })[choice]
    elseif dilemma_key == (keys.follower or "") then
        return ({ [0] = "treat", [1] = "recruit", [2] = "decline" })[choice]
    elseif dilemma_key == (keys.manual or "") then
        return ({ [0] = "treat", [1] = "confiscate", [2] = "decline" })[choice]
    elseif dilemma_key == cfg.physician_dilemma_key
        or dilemma_key == (keys.basic or cfg.hua_tuo_dilemma_key) then
        return ({ [0] = "treat", [1] = "decline" })[choice]
    end
    return nil
end

local function is_wota_physician_dilemma(dilemma_key)
    if dilemma_key == cfg.physician_dilemma_key or dilemma_key == cfg.hua_tuo_dilemma_key then
        return true
    end
    for _, key in pairs(cfg.hua_tuo_dilemma_keys or {}) do
        if dilemma_key == key then return true end
    end
    return false
end


local function is_replenishing_in_settlement(character)
    if not safe_call(character, "has_military_force", false) then return false end

    local force = safe_call(character, "military_force", nil)
    if not force or safe_call(force, "is_null_interface", true) then return false end
    if not safe_call(force, "is_replenishing", false) then return false end
    if not safe_call(force, "has_garrison_residence", false) then return false end

    local residence = safe_call(force, "garrison_residence", nil)
    if not residence or safe_call(residence, "is_null_interface", true) then return false end
    return safe_call(residence, "is_settlement", false)
end

local function eligible_hua_tuo_patients(faction)
    local eligible = {}
    local characters = faction:character_list()
    for i = 0, characters:num_items() - 1 do
        local character = characters:item_at(i)
        if character and not character:is_null_interface()
            and has_configured_wound(character)
            and is_replenishing_in_settlement(character) then
            eligible[#eligible + 1] = character
        end
    end
    return eligible
end

local function maybe_trigger_hua_tuo(context)
    if cfg.hua_tuo_event_enabled == false then return end

    local faction = context:faction()
    if not faction or safe_call(faction, "is_null_interface", true) then return end
    if cfg.human_factions_only and not safe_call(faction, "is_human", false) then return end
    if faction_cqi(faction) <= 0 then return end

    local pending_key = hua_tuo_pending_key(faction)
    if (cm:get_saved_value(pending_key) or 0) > 0 then return end

    local now = context:query_model():turn_number()
    if now < (cm:get_saved_value(hua_tuo_cooldown_key(faction)) or 0) then return end

    local patients = eligible_hua_tuo_patients(faction)
    if #patients == 0 then return end

    local chance = cfg.hua_tuo_chance_percent or 10
    if context:modify_model():random_number(1, 100) > chance then return end

    local patient = patients[context:modify_model():random_number(1, #patients)]
    local patient_cqi = character_cqi(patient)
    if patient_cqi <= 0 then return end

    local model = context:query_model()
    local dilemma_key, follower_available, manual_available = hua_tuo_dilemma_for(model, faction)
    local treasury = safe_call(faction, "treasury", 0)
    local can_treat = treasury >= (cfg.hua_tuo_cost or 2000)
    local can_recruit = follower_available and treasury >= (cfg.hua_tuo_recruit_cost or 1000)
    if not can_treat and not can_recruit and not manual_available then return end

    cm:set_saved_value(pending_key, patient_cqi)
    cm:set_saved_value(
        hua_tuo_cooldown_key(faction),
        now + (cfg.hua_tuo_cooldown_turns or 8)
    )

    local modify_faction = context:modify_model():get_modify_faction(faction)
    local triggered = modify_faction
        and not modify_faction:is_null_interface()
        and modify_faction:trigger_dilemma(dilemma_key, true)
    if not triggered then
        cm:set_saved_value(pending_key, 0)
        cm:set_saved_value(hua_tuo_cooldown_key(faction), 0)
        log("Hua Tuo dilemma failed to trigger; faction=" .. safe_call(faction, "name", ""))
        return
    end

    log("Physician dilemma triggered; key=" .. tostring(dilemma_key) .. " patient_cqi=" .. patient_cqi)
end

local function character_by_cqi(model, cqi)
    if not model or not model.character_for_command_queue_index then return nil end
    local ok, character = pcall(function()
        return model:character_for_command_queue_index(cqi)
    end)
    if ok then return character end
    return nil
end

local function valid_pending_patient(context, faction, patient_cqi)
    if patient_cqi <= 0 then return nil end
    local patient = character_by_cqi(context:query_model(), patient_cqi)
    if not patient or safe_call(patient, "is_null_interface", true) then
        log("Physician action cancelled because patient no longer exists; cqi=" .. patient_cqi)
        return nil
    end
    if character_cqi(patient) ~= patient_cqi or not has_configured_wound(patient) then
        log("Physician action cancelled because patient is no longer eligible; cqi=" .. patient_cqi)
        return nil
    end
    local patient_faction = safe_call(patient, "faction", nil)
    if not patient_faction or faction_cqi(patient_faction) ~= faction_cqi(faction) then
        log("Physician action cancelled because patient changed faction; cqi=" .. patient_cqi)
        return nil
    end
    return patient
end

local function award_faction_ceo(context, faction, ceo_key)
    if not faction_can_receive_ceo(context:query_model(), faction, ceo_key) then return false end
    local modify_faction = context:modify_model():get_modify_faction(faction)
    if not modify_faction or safe_call(modify_faction, "is_null_interface", true) then return false end
    local management = safe_call(modify_faction, "ceo_management", nil)
    if not management or safe_call(management, "is_null_interface", true) then return false end
    management:add_ceo(ceo_key)
    -- The query-side inventory may not refresh until the next model tick. A
    -- successful can_create_ceo check immediately before this call is the
    -- authoritative uniqueness guard.
    return true
end

local function apply_confiscation_penalty(context, faction)
    local effect_key = cfg.hua_tuo_confiscation_loyalty_effect
    if not effect_key or effect_key == "" then return end
    local characters = faction:character_list()
    for i = 0, characters:num_items() - 1 do
        local character = characters:item_at(i)
        if character and not safe_call(character, "is_null_interface", true) then
            local modify_character = context:modify_model():get_modify_character(character)
            if modify_character and not safe_call(modify_character, "is_null_interface", true) then
                modify_character:add_loyalty_effect(effect_key)
            end
        end
    end
end

local function resolve_hua_tuo_dilemma(context)
    local faction = context:faction()
    if not faction or safe_call(faction, "is_null_interface", true) then return end

    local pending_key = hua_tuo_pending_key(faction)
    local patient_cqi = cm:get_saved_value(pending_key) or 0
    cm:set_saved_value(pending_key, 0)
    local action = dilemma_action(context:dilemma(), context:choice())
    if not action or action == "decline" then return end

    if action == "recruit" then
        local cost = cfg.hua_tuo_recruit_cost or 1000
        if safe_call(faction, "treasury", 0) < cost then
            log("Hua Tuo recruitment cancelled because treasury is insufficient")
            return
        end
        if not award_faction_ceo(context, faction, cfg.hua_tuo_follower_ceo) then
            log("Hua Tuo recruitment cancelled because the unique follower is unavailable")
            return
        end
        local modify_faction = context:modify_model():get_modify_faction(faction)
        modify_faction:decrease_treasury(cost)
        cm:set_saved_value(hua_tuo_concluded_key(faction), true)
        log("Hua Tuo recruited; faction=" .. safe_call(faction, "name", ""))
        return
    elseif action == "confiscate" then
        if not award_faction_ceo(context, faction, cfg.hua_tuo_manual_ceo) then
            log("Hua Tuo manual confiscation cancelled because the unique accessory is unavailable")
            return
        end
        apply_confiscation_penalty(context, faction)
        cm:set_saved_value(hua_tuo_concluded_key(faction), true)
        log("Hua Tuo manual confiscated; faction=" .. safe_call(faction, "name", ""))
        return
    end

    local cost = cfg.hua_tuo_cost or 2000
    if safe_call(faction, "treasury", 0) < cost then
        log("Hua Tuo treatment cancelled because treasury is insufficient")
        return
    end

    local patient = valid_pending_patient(context, faction, patient_cqi)
    if not patient then return end

    local modify_faction = context:modify_model():get_modify_faction(faction)
    if not modify_faction or modify_faction:is_null_interface() then return end
    modify_faction:decrease_treasury(cost)

    local healed = replace_wounds(context, patient)
    log("Physician treatment resolved; cqi=" .. patient_cqi .. " healed=" .. tostring(healed))
end

local function complete_due_treatments(context)
    local faction = context:faction()
    if not faction or safe_call(faction, "is_null_interface", true) then return end
    if cfg.human_factions_only and not safe_call(faction, "is_human", false) then return end

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
            local faction = context:faction()
            if not faction or safe_call(faction, "is_null_interface", true) then return false end
            return (not cfg.human_factions_only) or safe_call(faction, "is_human", false)
        end,
        complete_due_treatments,
        true
    )

    core:add_listener(
        "WOTA_TriggerHuaTuo",
        "FactionTurnStart",
        function(context)
            local faction = context:faction()
            if not faction or safe_call(faction, "is_null_interface", true) then return false end
            return (not cfg.human_factions_only) or safe_call(faction, "is_human", false)
        end,
        maybe_trigger_hua_tuo,
        true
    )

    core:add_listener(
        "WOTA_ResolveHuaTuo",
        "DilemmaChoiceMadeEvent",
        function(context)
            return is_wota_physician_dilemma(context:dilemma())
        end,
        resolve_hua_tuo_dilemma,
        true
    )

    log("Initialized")
end

init()
