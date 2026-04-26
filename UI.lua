local addonName, ns = ...
local UI = {}
ns.UI = UI

-- HUD Elements
local MB_HUD = CreateFrame("Frame", "MB_HUD", UIParent, "BackdropTemplate")
local MB_Sidebar = CreateFrame("Frame", "MB_Sidebar", UIParent, "BackdropTemplate")

-- Edit Mode Registration
if EditModeManager then
    EditModeManager:RegisterSystem({ instance = MB_HUD, systemName = "MB_SurvivalHUD", systemType = Enum.EditModeSystemType.Main })
    EditModeManager:RegisterSystem({ instance = MB_Sidebar, systemName = "MB_UtilitySidebar", systemType = Enum.EditModeSystemType.Main })
end

function UI:Initialize()
    -- HUD Setup
    MB_HUD:SetSize(250, 40)
    MB_HUD:SetPoint("CENTER", 0, -150)
    MB_HUD:SetMovable(true)
    MB_HUD:EnableMouse(true)
    MB_HUD:RegisterForDrag("LeftButton")
    
    local ehpBar = CreateFrame("StatusBar", nil, MB_HUD)
    ehpBar:SetAllPoints()
    ehpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    ehpBar:SetStatusBarColor(0, 0.8, 1)
    ehpBar:SetMinMaxValues(0, 100)
    self.ehpBar = ehpBar

    -- Sidebar Setup
    MB_Sidebar:SetSize(120, 60)
    MB_Sidebar:SetPoint("RIGHT", -20, 0)
    MB_Sidebar:SetMovable(true)
    MB_Sidebar:EnableMouse(true)
    MB_Sidebar:RegisterForDrag("LeftButton")
    MB_Sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    MB_Sidebar:SetBackdropColor(0, 0, 0, 0.6)
    MB_Sidebar:SetBackdropBorderColor(1, 1, 1, 0.2)

    local stateValue = MB_Sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    stateValue:SetPoint("CENTER", 0, 0)
    stateValue:SetText("STABLE")
    self.stateValue = stateValue

    -- Drag Scripts
    local function OnDragStart(self)
        if self.unlocked or (EditModeManager and EditModeManager:IsEditModeActive()) then
            self:StartMoving()
        end
    end
    local function OnDragStop(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        MidnightBrewDB.positions = MidnightBrewDB.positions or {}
        MidnightBrewDB.positions[self:GetName()] = {p, rp, x, y}
    end

    MB_HUD:SetScript("OnDragStart", OnDragStart)
    MB_HUD:SetScript("OnDragStop", OnDragStop)
    MB_Sidebar:SetScript("OnDragStart", OnDragStart)
    MB_Sidebar:SetScript("OnDragStop", OnDragStop)
end

function UI:UpdateEHPBar(pct) if self.ehpBar then self.ehpBar:SetValue(pct or 0) end end
function UI:UpdateStateDisplay(state)
    if not self.stateValue then return end
    self.stateValue:SetText(state)
    if state == "CRITICAL" then self.stateValue:SetTextColor(1, 0, 0)
    elseif state == "PRESSURE" then self.stateValue:SetTextColor(1, 0.5, 0)
    else self.stateValue:SetTextColor(0, 1, 0) end
end

UI:Initialize()
