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
    self:RegisterEvent("PLAYER_TOTEM_UPDATE") -- CORRECTED NAME
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    
    self:SetScript("OnEvent", function(frame, event, arg1, arg2, arg3) 
        self:OnEvent(event, arg1, arg2, arg3) 
    end)
end

function MB:OnEvent(event, arg1, arg2, arg3)
    ns.Debug:SafeCall(function()
        if event == "ADDON_LOADED" and arg1 == addonName then
            MidnightBrewDB = MidnightBrewDB or defaults
            self:UpdateHealerUnit()
            ns.Debug:Log("SYSTEM", "Core Engine Initialized Successfully")
            
        elseif event == "UNIT_AURA" then
            if arg1 == "player" then self:UpdateAuras() end
            if arg1 and arg1:find("party") then self:ScanPartyForDispels(arg1) end
            
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if arg1 == "player" then self:CalculateEHP() end
            if arg1 == "target" then self:CheckTouchOfDeath() end
            
        elseif event == "PLAYER_REGEN_DISABLED" then
            self.inCombat = true
            self.pullStartTime = GetTime()
            
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false
            
        elseif event == "UNIT_POWER_UPDATE" then
            self:UpdateHealerMana(arg1)
            
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:UpdateHealerUnit()
            
        elseif event == "PLAYER_TARGET_CHANGED" then
            self:AutoMarkTarget()
            
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if arg1 == "player" then 
                self:TrackEnergySpend(arg3) 
                if arg3 == 116705 then -- Spear Hand Strike
                    local targetName = UnitName("target") or "Unknown"
                    local msg = "MB: Interrupted " .. targetName .. "!"
                    SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY")
                end
            end
            
        elseif event == "PLAYER_TOTEM_UPDATE" then
            self:UpdateStatue()
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

function MB:CheckTouchOfDeath()
    if not UnitExists("target") then return end
    local isEx = (UnitHealth("target")/UnitHealthMax("target") <= MidnightBrewDB.todThreshold) or (UnitHealth("target") < UnitHealthMax("player"))
    if ns.UI then ns.UI:UpdateExecuteHUD(isEx) end
end

function MB:AutoMarkTarget()
    if not MidnightBrewDB.autoMark or not IsInGroup() then return end
    local name = UnitName("target")
    if DANGEROUS_MOBS[name] and GetRaidTargetIndex("target") == nil then
        SetRaidTarget("target", DANGEROUS_MOBS[name])
    end
end

function MB:UpdateStatue()
    local have = GetTotemInfo(1)
    local hp = (have) and (UnitHealth("totem1") / UnitHealthMax("totem1") * 100) or 0
    if ns.UI then ns.UI:UpdateStatueStatus(have, hp) end
end

MB:OnLoad()
