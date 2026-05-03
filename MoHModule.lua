local addonName, ns = ...
local MB = ns.Core

-- Vitality is not exposed via aura API (points all nil, applications=0).
-- We track it by accumulating player damage dealt + healing received via CLEU.
-- VITALITY_CAP_FACTOR: estimated cap = this fraction of player max HP.
-- Tune in-game: increase if bar fills instantly, decrease if it never fills.
local SPELL_ASPECT_OF_HARMONY  = 450521  -- confirmed: passive "Storing X vitality" buff (duration=0, always present when vitality>0)
local SPELL_CELESTIAL_INFUSION = 1241059 -- spend trigger; also used for charge tracking
local VITALITY_CAP_FACTOR      = 0.25   -- 25% of max HP = estimated full vitality
local HARMONY_SPENDING_DURATION = 8     -- seconds after Celestial Infusion where vitality generation pauses

ns.MoH = {
    vitality         = 0,      -- 0-100 estimated percentage
    vitalityRaw      = 0,      -- raw accumulated damage+healing since last spend
    harmonyActive    = false,  -- true during spending window after Celestial Infusion cast
    harmonyExpiry    = 0,      -- GetTime() when spending window ends
    celInfCharges    = 0,
    celInfMaxCharges = 2,
}

local playerGUID
local lastMoHUpdate = 0

local function GetPlayerGUID()
    if not playerGUID then playerGUID = UnitGUID("player") end
    return playerGUID
end

local function GetCelInfCharges()
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(SPELL_CELESTIAL_INFUSION)
        return (info and info.currentCharges or 0), (info and info.maxCharges or 2)
    end
    if GetSpellCharges then
        local charges, maxCharges = GetSpellCharges(SPELL_CELESTIAL_INFUSION)
        return charges or 0, maxCharges or 2
    end
    return 0, 2
end

-- Register CLEU on the core event frame so DispatchModuleEvent routes it to us
MB:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

MB:RegisterModule("MasterOfHarmony", {"UNIT_AURA", "PLAYER_SPECIALIZATION_CHANGED", "COMBAT_LOG_EVENT_UNFILTERED"}, function(event, unit)

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local hasMoH = IsSpellKnown(SPELL_ASPECT_OF_HARMONY)
        if ns.UI and ns.UI.mohPanel then
            ns.UI.mohPanel:SetShown(hasMoH and (MidnightBrewDB.mohEnabled ~= false))
        end
        return
    end

    -- ── COMBAT LOG: accumulate vitality, detect Celestial Infusion cast ──────
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, destGUID, _, _, _, a1, a2, a3, a4 = CombatLogGetCurrentEventInfo()
        local pguid = GetPlayerGUID()

        -- Celestial Infusion cast → start spending window, reset accumulation
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == pguid and a1 == SPELL_CELESTIAL_INFUSION then
            ns.MoH.harmonyActive = true
            ns.MoH.harmonyExpiry = GetTime() + HARMONY_SPENDING_DURATION
            ns.MoH.vitalityRaw   = 0
            ns.MoH.vitality      = 0
            if ns.UI and ns.UI.UpdateMoHPanel then
                ns.UI:UpdateMoHPanel(ns.MoH)
            end
            return
        end

        -- Accumulate damage dealt and healing received while not in spending window
        if not ns.MoH.harmonyActive then
            local gained = 0
            if subevent == "SWING_DAMAGE" and sourceGUID == pguid then
                -- SWING_DAMAGE: a1 = amount
                gained = math.max(0, a1 or 0)
            elseif (subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") and sourceGUID == pguid then
                -- SPELL_DAMAGE: a4 = amount (after spellId, spellName, spellSchool)
                gained = math.max(0, a4 or 0)
            elseif (subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL") and destGUID == pguid then
                -- SPELL_HEAL: a4 = amount
                gained = math.max(0, a4 or 0)
            end

            if gained > 0 then
                ns.MoH.vitalityRaw = ns.MoH.vitalityRaw + gained
                local cap = (UnitHealthMax("player") or 1000000) * VITALITY_CAP_FACTOR
                ns.MoH.vitality = math.min(100, (ns.MoH.vitalityRaw / cap) * 100)

                -- Throttle UI updates to ~10fps to avoid spamming the frame
                local now = GetTime()
                if now - lastMoHUpdate >= 0.1 and ns.UI and ns.UI.UpdateMoHPanel then
                    lastMoHUpdate = now
                    ns.UI:UpdateMoHPanel(ns.MoH)
                end
            end
        end
        return
    end

    -- ── UNIT_AURA: update charges, check if spending window expired ───────────
    if event == "UNIT_AURA" then
        if unit ~= "player" then return end

        -- Expire spending window if time has passed
        if ns.MoH.harmonyActive and GetTime() >= ns.MoH.harmonyExpiry then
            ns.MoH.harmonyActive = false
            ns.MoH.harmonyExpiry = 0
        end

        local charges, maxCharges = GetCelInfCharges()
        ns.MoH.celInfCharges    = charges
        ns.MoH.celInfMaxCharges = maxCharges

        if ns.UI and ns.UI.UpdateMoHPanel then
            ns.UI:UpdateMoHPanel(ns.MoH)
        end
    end
end)
