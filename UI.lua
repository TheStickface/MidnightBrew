local addonName, ns = ...
local UI = {}
ns.UI = UI

-- HUD Frame
local hud = CreateFrame("Frame", "MB_HUD", UIParent, "BackdropTemplate")
hud:SetSize(220, 40)
hud:SetPoint("CENTER", 0, -150)
hud:SetMovable(true)
hud:EnableMouse(true)
hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", hud.StartMoving)
hud:SetScript("OnDragStop", hud.StopMovingOrSizing)

local ehpBar = CreateFrame("StatusBar", nil, hud)
ehpBar:SetSize(200, 20)
ehpBar:SetPoint("CENTER")
ehpBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill")
ehpBar:SetMinMaxValues(0, 100)

local ehpText = ehpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ehpText:SetPoint("CENTER")

local drGlow = ehpBar:CreateTexture(nil, "OVERLAY")
drGlow:SetAllPoints()
drGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
drGlow:SetBlendMode("ADD")
drGlow:Hide()

-- Sidebar Frame
local sideFrame = CreateFrame("Frame", "MB_Sidebar", UIParent, "BackdropTemplate")
sideFrame:SetSize(150, 200)
sideFrame:SetPoint("RIGHT", -50, 0)
sideFrame:SetMovable(true)
sideFrame:EnableMouse(true)
sideFrame:RegisterForDrag("LeftButton")
sideFrame:SetScript("OnDragStart", sideFrame.StartMoving)
sideFrame:SetScript("OnDragStop", sideFrame.StopMovingOrSizing)

local utilityText = sideFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
utilityText:SetPoint("TOP", 0, -10)

function UI:UpdateEHPBar(percent, raw, absorb)
    ehpBar:SetValue(percent)
    ehpBar:SetStatusBarColor(absorb > 0 and 0 or 0.2, absorb > 0 and 0.9 or 0.8, absorb > 0 and 1 or 0.2)
    ehpText:SetText(string.format("EHP: %d%%", percent))
end

function UI:UpdateDodgeTracker(remaining)
    if remaining > 0 then drGlow:Show() else drGlow:Hide() end
end

function UI:UpdateStatueStatus(active, hp)
    -- Update sidebar text
end

-- Alpha Control
hud:SetScript("OnUpdate", function(self)
    local targetAlpha = (UnitAffectingCombat("player") or UnitExists("target")) and 1.0 or 0.2
    hud:SetAlpha(targetAlpha)
    sideFrame:SetAlpha(targetAlpha)
end)
