local addonName, ns = ...
local MB = CreateFrame("Frame")
ns.Core = MB

local defaults = { hudEnabled = true, sidebarEnabled = true, todThreshold = 0.15, autoMark = true }
MB.energySpent = 0
MB.inCombat = false
MB.healerUnit = nil

local DANGEROUS_MOBS = { ["Void-Caster"] = 8, ["Ethereal Binder"] = 7 }

function MB:OnLoad()
    ns.Debug:Initialize()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("TOTEM_UPDATE")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:SetScript("OnEvent", function(f, e, ...) self:OnEvent(e, ...) end)
end

function MB:OnEvent(event, ...)
    ns.Debug:SafeCall(function()
        if event == "ADDON_LOADED" and ... == addonName then
            MidnightBrewDB = MidnightBrewDB or defaults
            self:UpdateHealerUnit()
        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit == "player" then self:UpdateAuras() end
            if unit and unit:find("party") then self:ScanPartyForDispels(unit) end
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if ... == "player" then self:CalculateEHP() end
            if ... == "target" then self:CheckTouchOfDeath() end
        elseif event == "PLAYER_REGEN_DISABLED" then
            self.inCombat = true
            self.pullStartTime = GetTime()
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false
        elseif event == "UNIT_POWER_UPDATE" then
            self:UpdateHealerMana(...)
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:UpdateHealerUnit()
        elseif event == "PLAYER_TARGET_CHANGED" then
            self:AutoMarkTarget()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then self:TrackEnergySpend(spellID) end
        end
    end)
end

function MB:CalculateEHP()
    local cur, max = UnitHealth("player"), UnitHealthMax("player")
    local stag = UnitStagger("player") or 0
    local abs = UnitGetTotalAbsorbs("player") or 0
    local ehp = (cur + abs) - stag
    if ns.UI then ns.UI:UpdateEHPBar((ehp/max)*100, ehp, abs) end
end

function MB:UpdateAuras()
    local name, _, _, _, _, expTime = AuraUtil.FindAuraByName("Predictive Training", "player")
    if name and ns.UI then ns.UI:UpdateDodgeTracker(expTime - GetTime()) end
end

function MB:ScanPartyForDispels(unit)
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not aura then break end
        if aura.dispelName == "Poison" or aura.dispelName == "Disease" then
            ns.UI:TriggerDispelAlert(UnitName(unit), aura.dispelName)
            return
        end
        i = i + 1
    end
end

function MB:UpdateHealerUnit()
    for i = 1, GetNumGroupMembers() do
        local u = (IsInRaid() and "raid"..i or "party"..i)
        if UnitGroupRolesAssigned(u) == "HEALER" then self.healerUnit = u; return end
    end
end

function MB:UpdateHealerMana(unit)
    if unit == self.healerUnit then
        local p = (UnitPower(unit, 0) / UnitPowerMax(unit, 0)) * 100
        if ns.UI then ns.UI:UpdateHealerStatus(p) end
    end
end

function MB:TrackEnergySpend(spellID)
    local cost = GetSpellPowerCost(spellID)
    if cost and cost[1] then
        self.energySpent = self.energySpent + cost[1].cost
        if self.energySpent >= 300 then self.energySpent = self.energySpent - 300 end
        if ns.UI then ns.UI:UpdateFlurryProgress(self.energySpent/300) end
    end
end

MB:OnLoad()
