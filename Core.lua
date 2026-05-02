local addonName, ns = ...
local MB = CreateFrame("Frame")
ns.Core = MB

function MB:StartEngine()
    ns.Debug:Log("SYSTEM", "Starting Heuristics Engine...")
    
    -- Restore Saved Positions
    if MidnightBrewDB and MidnightBrewDB.positions then
        for name, pos in pairs(MidnightBrewDB.positions) do
            local f = _G[name]
            if f then
                f:ClearAllPoints()
                f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
            end
        end
    end

    -- Safety check: ensure Modules.lua has attached this function
    if self.UpdateCombatState then
        C_Timer.NewTicker(0.5, function() self:UpdateCombatState() end)
    else
        ns.Debug:Log("ERROR", "UpdateCombatState not found!")
    end
    
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("PLAYER_TOTEM_UPDATE")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function MB:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        local defaults = {
            hudEnabled = true,
            sidebarEnabled = true,
            mohEnabled = true,
            mohAlertBlink = true,
            todThreshold = 0.15,
            autoMark = true,
        }
        MidnightBrewDB = MidnightBrewDB or defaults
        self:StartEngine()
    end
    
    if self.DispatchModuleEvent then
        self:DispatchModuleEvent(event, arg1)
    end
end

MB:RegisterEvent("ADDON_LOADED")
MB:SetScript("OnEvent", function(f, e, a1) MB:OnEvent(e, a1) end)
