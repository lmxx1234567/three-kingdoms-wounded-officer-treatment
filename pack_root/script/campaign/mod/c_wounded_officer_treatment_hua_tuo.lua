-- Hua Tuo random event and dilemma resolution
-- Total War: THREE KINGDOMS 1.7.x

local api = WOTA_ASSIGNMENTS or {}
local cfg = api.cfg or {}
local safe_call = api.safe_call
local character_cqi = api.character_cqi
local faction_cqi = api.faction_cqi
local has_configured_wound = api.has_configured_wound
local replace_wounds = api.replace_wounds

local HUA_TUO_PENDING_PREFIX = "WOTA_HUA_TUO_PENDING_"
local HUA_TUO_COOLDOWN_PREFIX = "WOTA_HUA_TUO_COOLDOWN_"
local HUA_TUO_CONCLUDED_PREFIX = "WOTA_HUA_TUO_CONCLUDED_"

local function log(message)
    out("[WOTA] " .. tostring(message))
end

local function hua_tuo_pending_key(faction)
    return HUA_TUO_PENDING_PREFIX .. tostring(faction_cqi(faction))
end

local function hua_tuo_cooldown_key(faction)
    return HUA_TUO_COOLDOWN_PREFIX .. tostring(faction_cqi(faction))
end

local function reset_hua_tuo_cooldown(faction)
    cm:set_saved_value(hua_tuo_cooldown_key(faction), 0)
end

local function hua_tuo_concluded_key(faction)
    return HUA_TUO_CONCLUDED_PREFIX .. tostring(faction_cqi(faction))
end

local function faction_ceo_management(faction)
    local management = safe_call(faction, "ceo_management", nil)
    if not management or safe_call(management, "is_null_interface", true) then return nil end
    return management
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

local function faction_has_ceo(faction, wanted_key)
    local management = faction_ceo_management(faction)
    if not management then return false end
    return list_has_ceo(safe_call(management, "all_ceos", nil), wanted_key)
end

local function character_has_ceo(character, wanted_key)
    local management = safe_call(character, "ceo_management", nil)
    if not management or safe_call(management, "is_null_interface", true) then return false end
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

local function hua_tuo_dilemma_for(model, faction, treasury)
    local can_treat = treasury >= (cfg.hua_tuo_cost or 2000)
    if cm:get_saved_value(hua_tuo_concluded_key(faction)) == true then
        if can_treat then return cfg.physician_dilemma_key end
        return nil
    end

    local follower_available = faction_can_receive_ceo(model, faction, cfg.hua_tuo_follower_ceo)
    local manual_available = faction_can_receive_ceo(model, faction, cfg.hua_tuo_manual_ceo)
    local can_recruit = follower_available and treasury >= (cfg.hua_tuo_recruit_cost or 1000)
    local keys = cfg.hua_tuo_dilemma_keys or {}

    if can_treat then
        if can_recruit and manual_available then
            return keys.both or cfg.hua_tuo_dilemma_key
        elseif can_recruit then
            return keys.follower or cfg.hua_tuo_dilemma_key
        elseif manual_available then
            return keys.manual or cfg.hua_tuo_dilemma_key
        end
        return keys.basic or cfg.hua_tuo_dilemma_key
    end

    if can_recruit and manual_available then
        return keys.rewards_only
    elseif can_recruit then
        return keys.recruit_only
    elseif manual_available then
        return keys.manual_only
    end
    return nil
end

local function dilemma_action(dilemma_key, choice)
    local keys = cfg.hua_tuo_dilemma_keys or {}
    if dilemma_key == (keys.both or "") then
        return ({ [0] = "treat", [1] = "recruit", [2] = "confiscate", [3] = "decline" })[choice]
    elseif dilemma_key == (keys.follower or "") then
        return ({ [0] = "treat", [1] = "recruit", [2] = "decline" })[choice]
    elseif dilemma_key == (keys.manual or "") then
        return ({ [0] = "treat", [1] = "confiscate", [2] = "decline" })[choice]
    elseif dilemma_key == (keys.rewards_only or "") then
        return ({ [0] = "recruit", [1] = "confiscate", [2] = "decline" })[choice]
    elseif dilemma_key == (keys.recruit_only or "") then
        return ({ [0] = "recruit", [1] = "decline" })[choice]
    elseif dilemma_key == (keys.manual_only or "") then
        return ({ [0] = "confiscate", [1] = "decline" })[choice]
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
    local treasury = safe_call(faction, "treasury", 0)
    local dilemma_key = hua_tuo_dilemma_for(context:query_model(), faction, treasury)
    if not dilemma_key or dilemma_key == "" then return end

    cm:set_saved_value(pending_key, patient_cqi)
    cm:set_saved_value(hua_tuo_cooldown_key(faction), now + (cfg.hua_tuo_cooldown_turns or 8))
    local modify_faction = context:modify_model():get_modify_faction(faction)
    local triggered = modify_faction
        and not modify_faction:is_null_interface()
        and modify_faction:trigger_dilemma(dilemma_key, true)
    if not triggered then
        cm:set_saved_value(pending_key, 0)
        reset_hua_tuo_cooldown(faction)
        log("Hua Tuo dilemma failed to trigger; faction=" .. safe_call(faction, "name", ""))
        return
    end
    log("Physician dilemma triggered; key=" .. tostring(dilemma_key) .. " patient_cqi=" .. patient_cqi)
end

local function character_by_cqi(model, cqi)
    if not model or not model.character_for_command_queue_index then return nil end
    local ok, character = pcall(function() return model:character_for_command_queue_index(cqi) end)
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
            reset_hua_tuo_cooldown(faction)
            return
        end
        if not award_faction_ceo(context, faction, cfg.hua_tuo_follower_ceo) then
            log("Hua Tuo recruitment cancelled because the unique follower is unavailable")
            reset_hua_tuo_cooldown(faction)
            return
        end
        context:modify_model():get_modify_faction(faction):decrease_treasury(cost)
        cm:set_saved_value(hua_tuo_concluded_key(faction), true)
        log("Hua Tuo recruited; faction=" .. safe_call(faction, "name", ""))
        return
    elseif action == "confiscate" then
        if not award_faction_ceo(context, faction, cfg.hua_tuo_manual_ceo) then
            log("Hua Tuo manual confiscation cancelled because the unique accessory is unavailable")
            reset_hua_tuo_cooldown(faction)
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
        reset_hua_tuo_cooldown(faction)
        return
    end
    local patient = valid_pending_patient(context, faction, patient_cqi)
    if not patient then
        reset_hua_tuo_cooldown(faction)
        return
    end
    local modify_faction = context:modify_model():get_modify_faction(faction)
    if not modify_faction or modify_faction:is_null_interface() then
        reset_hua_tuo_cooldown(faction)
        return
    end
    local healed = replace_wounds(context, patient)
    if not healed then
        log("Physician treatment failed before payment; cqi=" .. patient_cqi)
        reset_hua_tuo_cooldown(faction)
        return
    end
    modify_faction:decrease_treasury(cost)
    log("Physician treatment resolved; cqi=" .. patient_cqi .. " healed=" .. tostring(healed))
end

local function init()
    if cfg.enabled == false or cfg.hua_tuo_event_enabled == false then return end
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
        function(context) return is_wota_physician_dilemma(context:dilemma()) end,
        resolve_hua_tuo_dilemma,
        true
    )
    log("Hua Tuo event initialized")
end

init()
