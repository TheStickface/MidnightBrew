local addonName, ns = ...
local MB = CreateFrame("Frame")
ns.Core = MB

local defaults = { 
    hudEnabled = true, 
    sidebarEnabled = true, 
    todThreshold = 0.15, 
    autoMark = true,
    dungeonIntel = true
}

function MB:OnLoad()
    ns.Debug:Initialize()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    C_Timer.NewTicker(0.5, function() self:UpdateCombatState() end)
    self:SetScript("OnEvent", function(f, e, ...) self:OnEvent(e, ...) end)
end

function MB:OnEvent(event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        MidnightBrewDB = MidnightBrewDB or defaults
        ns.Debug:Log("SYSTEM", "Engine 2.0 (Modular) Online")
    end
    
    if MB.DispatchModuleEvent then
        self:DispatchModuleEvent(event, ...)
    end
end

MB:OnLoad()
