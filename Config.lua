local addonName, ns = ...
local MB = ns.Core

-- Create the Control Center Frame
local frame = CreateFrame("Frame", "MB_ConfigWindow", UIParent, "BackdropTemplate")
frame:SetSize(400, 300)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Dark Premium Styling
frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.05, 0.05, 0.1, 0.9) -- Midnight Navy
frame:SetBackdropBorderColor(0.3, 0.3, 0.5, 1)

-- Header
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -20)
title:SetText("MidnightBrew |cff00ccffControl Center|r")

-- Status Readout (Heuristics)
local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
status:SetPoint("TOPRIGHT", -20, -20)
C_Timer.NewTicker(0.5, function()
    if frame:IsVisible() and MB then
        status:SetText("State: |cff00ff00" .. (MB.CurrentState or "STABLE") .. "|r")
    end
end)

-- Basic Toggle Builder
local function CreateToggle(name, label, yOffset, dbKey)
    local cb = CreateFrame("CheckButton", "MB_CB_"..name, frame, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    cb.Text:SetText(label)
    cb:SetScript("OnShow", function(self) 
        if MidnightBrewDB then
            self:SetChecked(MidnightBrewDB[dbKey]) 
        end
    end)
    cb:SetScript("OnClick", function(self) 
        if MidnightBrewDB then
            MidnightBrewDB[dbKey] = self:GetChecked() 
        end
    end)
    return cb
end

-- Useful Feature Toggles
CreateToggle("HUD", "Enable Survival HUD", -60, "hudEnabled")
CreateToggle("DungeonIntel", "Enable Dungeon Intelligence", -90, "dungeonIntel")
CreateToggle("AutoMark", "Auto-Mark Dangerous Mobs", -120, "autoMark")

-- Test Button
local testBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
testBtn:SetSize(150, 25)
testBtn:SetPoint("BOTTOMLEFT", 20, 20)
testBtn:SetText("Run Stability Suite")
testBtn:SetScript("OnClick", function() 
    if ns.Tests and ns.Tests.RunAll then
        ns.Tests:RunAll()
    else
        print("|cffff0000[MB Error]|r: Test module not found.")
    end
end)

-- Close Button
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 0, 0)

-- Slash Command Update
SLASH_MIDNIGHTBREW1 = "/mb"
SlashCmdList["MIDNIGHTBREW"] = function(msg)
    local cmd = msg:lower()
    if cmd == "test" then
        if ns.Tests and ns.Tests.RunAll then ns.Tests:RunAll() end
    elseif cmd == "reset" then
        if ns.UI and ns.UI.ResetPositions then ns.UI:ResetPositions() end
    else
        if frame:IsVisible() then frame:Hide() else frame:Show() end
    end
end
