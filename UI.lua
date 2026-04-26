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
    -- Setup HUD
    MB_HUD:SetSize(250, 40)
    MB_HUD:SetPoint("CENTER", 0, -150)
    MB_HUD:SetMovable(true)
    MB_HUD:SetClampedToScreen(true)
    
    local ehpBar = CreateFrame("StatusBar", nil, MB_HUD)
    ehpBar:SetAllPoints()
    ehpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    ehpBar:SetStatusBarColor(0, 0.8, 1)
    ehpBar:SetMinMaxValues(0, 100)
    self.ehpBar = ehpBar

    -- Setup Sidebar (GLASSMORPHISM STYLE)
    MB_Sidebar:SetSize(120, 100)
    MB_Sidebar:SetPoint("RIGHT", -20, 0)
    MB_Sidebar:SetMovable(true)
    MB_Sidebar:SetClampedToScreen(true)
    
    MB_Sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    MB_Sidebar:SetBackdropColor(0, 0, 0, 0.6)
    MB_Sidebar:SetBackdropBorderColor(1, 1, 1, 0.2)

    local stateTitle = MB_Sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stateTitle:SetPoint("TOP", 0, -10)
    stateTitle:SetText("COMBAT STATE")

    local stateValue = MB_Sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    stateValue:SetPoint("TOP", stateTitle, "BOTTOM", 0, -5)
    stateValue:SetText("STABLE")
    self.stateValue = stateValue

    -- Movement Handles
    local selection = CreateFrame("Frame", nil, MB_HUD, "BackdropTemplate")
    selection:SetAllPoints()
    selection:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    selection:SetBackdropBorderColor(0, 0.7, 1, 1)
    selection:Hide()
    self.selection = selection
end

function UI:UpdateEHPBar(pct)
    if self.ehpBar then self.ehpBar:SetValue(pct or 0) end
end

function UI:UpdateStateDisplay(state)
    if not self.stateValue then return end
    self.stateValue:SetText(state)
    if state == "CRITICAL" then self.stateValue:SetTextColor(1, 0, 0)
    elseif state == "PRESSURE" then self.stateValue:SetTextColor(1, 0.5, 0)
    elseif state == "KITING" then self.stateValue:SetTextColor(0, 1, 1)
    else self.stateValue:SetTextColor(0, 1, 0) end
end

function UI:TriggerDispelAlert(name, type)
    print("|cffff0000[MB ALERT]|r: DISPEL " .. name .. " (" .. type .. ")")
end

function UI:ShowPullRating(rating)
    print("|cff00ff00[MB AUDIT]|r: Pull Rating: |cffffffff" .. rating .. "|r")
end

UI:Initialize()
