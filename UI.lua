local addonName, ns = ...
local UI = {}
ns.UI = UI

-- Main HUD
local hud = CreateFrame("Frame", "MB_HUD", UIParent, "BackdropTemplate")
hud:SetSize(220, 50)
hud:SetPoint("CENTER", 0, -150)
hud:SetMovable(true)
hud:EnableMouse(true)
hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", hud.StartMoving)
hud:SetScript("OnDragStop", hud.StopMovingOrSizing)

local ehpBar = CreateFrame("StatusBar", nil, hud)
ehpBar:SetSize(200, 22)
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

-- Sidebar
local side = CreateFrame("Frame", "MB_Sidebar", UIParent, "BackdropTemplate")
side:SetSize(160, 250)
side:SetPoint("RIGHT", -50, 0)
side:SetMovable(true)
side:EnableMouse(true)
side:RegisterForDrag("LeftButton")
side:SetScript("OnDragStart", side.StartMoving)
side:SetScript("OnDragStop", side.StopMovingOrSizing)

local statusText = side:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statusText:SetPoint("TOP", 0, -10)
statusText:SetText("MIDNIGHTBREW READY")

-- Update Functions
function UI:UpdateEHPBar(pct, raw, abs)
    ehpBar:SetValue(pct)
    ehpBar:SetStatusBarColor(abs > 0 and 0 or 0.2, abs > 0 and 0.9 or 0.8, abs > 0 and 1 or 0.2)
    ehpText:SetText(string.format("EHP: %d%%", pct))
end

function UI:UpdateDodgeTracker(rem)
    if rem > 0 then drGlow:Show() else drGlow:Hide() end
end

function UI:UpdateHealerStatus(mana)
    local color = mana < 20 and "|cffff0000" or (mana < 50 and "|cffffff00" or "|cff00ff00")
    statusText:SetText(color .. "HEALER: " .. math.floor(mana) .. "%|r")
end

function UI:TriggerThreatAlert(name)
    print("|cffff0000LOOSE MOB: " .. name .. "|r")
end

function UI:TriggerTigerLustAlert()
    UIFrameFlash(hud, 0.2, 0.2, 1, true, 0, 0)
end

function UI:TriggerDispelAlert(name, type)
    print(string.format("|cff00ff00DETOX %s: %s|r", type:upper(), name))
end

hud:SetScript("OnUpdate", function(self)
    local alpha = (UnitAffectingCombat("player") or UnitExists("target")) and 1.0 or 0.2
    hud:SetAlpha(alpha)
    side:SetAlpha(alpha)
end)
