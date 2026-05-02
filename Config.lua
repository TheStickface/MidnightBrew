local addonName, ns = ...
local MB = ns.Core

local frame = CreateFrame("Frame", "MB_ConfigWindow", UIParent, "BackdropTemplate")
frame:SetSize(400, 350)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.05, 0.05, 0.1, 0.9)
frame:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -20)
title:SetText("MidnightBrew |cff00ccffControl Center|r")

local function CreateToggle(name, label, yOffset, dbKey)
    local cb = CreateFrame("CheckButton", "MB_CB_"..name, frame, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    cb.Text:SetText(label)
    cb:SetScript("OnShow", function(self) if MidnightBrewDB then self:SetChecked(MidnightBrewDB[dbKey]) end end)
    cb:SetScript("OnClick", function(self) if MidnightBrewDB then MidnightBrewDB[dbKey] = self:GetChecked() end end)
    return cb
end

CreateToggle("HUD", "Enable Survival HUD", -60, "hudEnabled")
CreateToggle("Sidebar", "Enable Utility Sidebar", -90, "sidebarEnabled")
CreateToggle("DungeonIntel", "Enable Dungeon Intelligence", -120, "dungeonIntel")
CreateToggle("MoH",      "Enable Master of Harmony Panel", -150, "mohEnabled")
CreateToggle("MoHBlink", "Enable Vitality Alert Blink",    -180, "mohAlertBlink")

-- UNLOCK HUD BUTTON
local unlockBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
unlockBtn:SetSize(120, 30)
unlockBtn:SetPoint("TOPLEFT", 20, -210)
unlockBtn:SetText("Unlock HUD")
unlockBtn:SetScript("OnClick", function()
    local MB_HUD = _G["MB_HUD"]
    local MB_Sidebar = _G["MB_Sidebar"]
    local MB_MoH = _G["MB_MoH"]
    if not MB_HUD then return end

    MB_HUD.unlocked = not MB_HUD.unlocked
    if MB_Sidebar then MB_Sidebar.unlocked = MB_HUD.unlocked end
    if MB_MoH then MB_MoH.unlocked = MB_HUD.unlocked end

    print("|cff00ccff[MB]|r: HUD " .. (MB_HUD.unlocked and "|cff00ff00Unlocked|r (Drag with Mouse)" or "|cffff0000Locked|r"))
end)

local testBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
testBtn:SetSize(150, 25)
testBtn:SetPoint("BOTTOMLEFT", 20, 20)
testBtn:SetText("Run Stability Suite")
testBtn:SetScript("OnClick", function() if ns.Tests then ns.Tests:RunAll() end end)

-- Resize frame to accommodate new toggles
frame:SetSize(400, 420)

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 0, 0)

SLASH_MIDNIGHTBREW1 = "/mb"
SlashCmdList["MIDNIGHTBREW"] = function(msg)
    if msg == "test" then
        if ns.Tests then ns.Tests:RunAll() end
    else
        if frame:IsVisible() then frame:Hide() else frame:Show() end
    end
end
