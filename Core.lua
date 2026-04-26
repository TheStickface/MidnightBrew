local addonName, ns = ...
local MB = CreateFrame("Frame")
ns.Core = MB

local defaults = { hudEnabled = true, sidebarEnabled = true, todThreshold = 0.15, autoMark = true }
MB.energySpent = 0
MB.inCombat = false

local DANGEROUS_MOBS = {
    ["Void-Caster"] = 8,
    ["Ethereal Binder"] = 7,
}

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
    self:SetScript("OnEvent", self.OnEvent)
end

function MB:OnEvent(event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        MidnightBrewDB = MidnightBrewDB or defaults
    elseif event == "UNIT_AURA" and ... == "player" then
        self:UpdateAuras()
    elseif event == "UNIT_HEALTH" then
        self:CalculateEHP()
        self:CheckTouchOfDeath()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self.inCombat = true
        self.pullStartTime = GetTime()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.inCombat = false
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "TOTEM_UPDATE" then
        self:UpdateStatue()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:AutoMarkTarget()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then self:TrackEnergySpend(spellID) end
    end
end

function MB:CalculateEHP()
    local currentHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local stagger = UnitStagger("player") or 0
    local totalAbsorb = UnitGetTotalAbsorbs("player") or 0
    local effectiveHP = (currentHP + totalAbsorb) - stagger
    if ns.UI then ns.UI:UpdateEHPBar((effectiveHP / maxHP) * 100, effectiveHP, totalAbsorb) end
end

function MB:TrackEnergySpend(spellID)
    local cost = GetSpellPowerCost(spellID)
    if cost and cost[1] then
        self.energySpent = self.energySpent + cost[1].cost
        if self.energySpent >= 300 then self.energySpent = self.energySpent - 300 end
        if ns.UI then ns.UI:UpdateFlurryProgress(self.energySpent / 300) end
    end
end

function MB:UpdateAuras()
    local name, _, count, _, duration, expirationTime = AuraUtil.FindAuraByName("Predictive Training", "player")
    if name and ns.UI then ns.UI:UpdateDodgeTracker(expirationTime - GetTime()) end
    
    local _, _, fCount = AuraUtil.FindAuraByName("Flurry Strikes", "player")
    if ns.UI then ns.UI:UpdateFlurryStacks(fCount or 0) end
end

function MB:AutoMarkTarget()
    if not MidnightBrewDB.autoMark or not IsInGroup() then return end
    local targetName = UnitName("target")
    if DANGEROUS_MOBS[targetName] and GetRaidTargetIndex("target") == nil then
        SetRaidTarget("target", DANGEROUS_MOBS[targetName])
    end
end

function MB:UpdateStatue()
    local haveTotem = GetTotemInfo(1)
    local statueHP = (haveTotem) and (UnitHealth("totem1") / UnitHealthMax("totem1") * 100) or 0
    if ns.UI then ns.UI:UpdateStatueStatus(haveTotem, statueHP) end
end

function MB:HandleCombatLog()
    local _, subEvent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        local msg = "MB: Interrupted " .. destName .. "!"
        SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY")
    end
end

MB:OnLoad()
