local addonName, ns = ...
local UI = {}
ns.UI = UI

-- HUD Elements
local MB_HUD = CreateFrame("Frame", "MB_HUD", UIParent, "BackdropTemplate")
local MB_Sidebar = CreateFrame("Frame", "MB_Sidebar", UIParent, "BackdropTemplate")

-- Edit Mode Registration (Secure Mixin)
if EditModeManager then
    EditModeManager:RegisterSystem({
        instance = MB_HUD,
        systemName = "MB_SurvivalHUD",
        systemType = Enum.EditModeSystemType.Main,
    })
    EditModeManager:RegisterSystem({
        instance = MB_Sidebar,
        systemName = "MB_UtilitySidebar",
        systemType = Enum.EditModeSystemType.Main,
    })
end

function UI:Initialize()
    -- Build HUD ...
    MB_HUD:SetSize(250, 40)
    MB_HUD:SetPoint("CENTER", 0, -150)
    
    local ehpBar = CreateFrame("StatusBar", nil, MB_HUD)
    ehpBar:SetAllPoints()
    ehpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    ehpBar:SetStatusBarColor(0, 0.8, 1) -- Cyan for EHP
    ehpBar:SetMinMaxValues(0, 100)
    self.ehpBar = ehpBar
end

function UI:UpdateEHPBar(pct)
    -- Using the pre-calculated secure percentage
    if self.ehpBar then
        self.ehpBar:SetValue(pct or 0)
    end
end

-- ... rest of UI code ...
UI:Initialize()
