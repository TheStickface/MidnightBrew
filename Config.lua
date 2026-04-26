local addonName, ns = ...
local MB = ns.Core

local frame = CreateFrame("Frame", "MB_ConfigWindow", UIParent, "BackdropTemplate")
frame:SetSize(400, 320)
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

local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
status:SetPoint("TOPRIGHT", -20, -20)
C_Timer.NewTicker(0.5, function()
    if frame:IsVisible() and MB then
        status:SetText("State: |cff00ff00" .. (MB.CurrentState or "STABLE") .. "|r")
    end
end)

local function CreateToggle(name, label, yOffset, dbKey)
    local cb = CreateFrame("CheckButton", "MB_CB_"..name, frame, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    cb.Text:SetText(label)
    cb:SetScript("OnShow", function(self) if MidnightBrewDB then self:SetChecked(MidnightBrewDB[dbKey]) end end)
    cb:SetScript("OnClick", function(self) if MidnightBrewDB then MidnightBrewDB[dbKey] = self:GetChecked() end end)
    return cb
end

CreateToggle("HUD", "Enable Survival HUD", -60, "hudEnabled")
CreateToggle("DungeonIntel", "Enable Dungeon Intelligence", -90, "dungeonIntel")
CreateToggle("AutoMark", "Auto-Mark Dangerous Mobs", -120, "autoMark")

local recBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
recBtn:SetSize(120, 25)
recBtn:SetPoint("TOPLEFT", 20, -160)
recBtn:SetText("Record Target")
recBtn:SetScript("OnClick", function() if MB.RecordCurrentTarget then MB:RecordCurrentTarget() end end)

local testBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
testBtn:SetSize(150, 25)
testBtn:SetPoint("BOTTOMLEFT", 20, 20)
testBtn:SetText("Run Stability Suite")
testBtn:SetScript("OnClick", function() if ns.Tests then ns.Tests:RunAll() end end)

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
