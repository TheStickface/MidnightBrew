local addonName, ns = ...
local MB = ns.Core

-- To confirm SPELL_VITALITY_AURA in-game, run:
-- /run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL") if a then print(i,a.spellId,a.name,a.applications) end end
-- Find the "Vitality" entry and update the constant below.
local SPELL_ASPECT_OF_HARMONY  = 450508  -- buff present during spending period
local SPELL_VITALITY_AURA      = 0       -- TBD: set to 0 until confirmed in-game
local SPELL_CELESTIAL_INFUSION = 1241059 -- used for charge tracking

ns.MoH = {
    vitality         = 0,
    harmonyActive    = false,
    harmonyExpiry    = 0,
    celInfCharges    = 0,
    celInfMaxCharges = 2,
}

local function GetPlayerAura(spellID)
    if spellID == 0 then return nil end
    if C_UnitAuras.GetAuraDataBySpellID then
        return C_UnitAuras.GetAuraDataBySpellID("player", spellID, "HELPFUL")
    end
    -- Fallback: scan by index (same pattern as existing Modules.lua)
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.spellId == spellID then return aura end
        i = i + 1
    end
    return nil
end

local function GetCelInfCharges()
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(SPELL_CELESTIAL_INFUSION)
        if info then return info.currentCharges or 0, info.maxCharges or 2 end
    end
    local charges, maxCharges = GetSpellCharges(SPELL_CELESTIAL_INFUSION)
    return charges or 0, maxCharges or 2
end

MB:RegisterModule("MasterOfHarmony", {"UNIT_AURA", "PLAYER_SPECIALIZATION_CHANGED"}, function(event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local hasMoH = IsSpellKnown(SPELL_ASPECT_OF_HARMONY)
        if ns.UI and ns.UI.mohPanel then
            ns.UI.mohPanel:SetShown(hasMoH and (MidnightBrewDB.mohEnabled ~= false))
        end
        return
    end
    if unit ~= "player" then return end
    -- full update logic added in Task 2
end)
