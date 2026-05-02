local addonName, ns = ...
local UI = {}
ns.UI = UI

-- HUD Elements
local MB_HUD = CreateFrame("Frame", "MB_HUD", UIParent, "BackdropTemplate")
local MB_Sidebar = CreateFrame("Frame", "MB_Sidebar", UIParent, "BackdropTemplate")
local MB_MoH = CreateFrame("Frame", "MB_MoH", UIParent, "BackdropTemplate")

-- Edit Mode Registration
if EditModeManager then
    EditModeManager:RegisterSystem({ instance = MB_HUD, systemName = "MB_SurvivalHUD", systemType = Enum.EditModeSystemType.Main })
    EditModeManager:RegisterSystem({ instance = MB_Sidebar, systemName = "MB_UtilitySidebar", systemType = Enum.EditModeSystemType.Main })
    EditModeManager:RegisterSystem({ instance = MB_MoH, systemName = "MB_MasterOfHarmony", systemType = Enum.EditModeSystemType.Main })
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

    -- Master of Harmony Panel
    self:CreateMoHPanel()
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

-- ============================================================================
-- Master of Harmony Panel
-- ============================================================================

function UI:CreateMoHPanel()
    local panel = MB_MoH  -- frame already created at module level
    panel:SetSize(210, 80)
    panel:SetPoint("RIGHT", UIParent, "RIGHT", -160, 0)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.07, 0.05, 0.10, 0.85)
    panel:SetBackdropBorderColor(0.29, 0.13, 0.38, 1)

    local header = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    header:SetText("MASTER OF HARMONY")
    header:SetTextColor(0.878, 0.337, 0.992)

    -- Row 1: Vitality
    local vitLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vitLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -23)
    vitLabel:SetText("VITALITY")
    vitLabel:SetTextColor(0.67, 0.67, 0.67)

    local vitValue = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vitValue:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -23)
    vitValue:SetText("0")
    vitValue:SetTextColor(0.878, 0.337, 0.992)

    local vitBar = CreateFrame("StatusBar", nil, panel)
    vitBar:SetSize(190, 7)
    vitBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
    vitBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    vitBar:SetStatusBarColor(0.608, 0.212, 0.949)
    vitBar:SetMinMaxValues(0, 100)
    vitBar:SetValue(0)

    -- Row 2: Celestial Infusion pips
    local celLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    celLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -48)
    celLabel:SetText("CELESTIAL INFUSION")
    celLabel:SetTextColor(0.67, 0.67, 0.67)

    local pips = {}
    for i = 1, 2 do
        local pip = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        pip:SetSize(12, 12)
        pip:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10 - (2 - i) * 16, -46)
        pip:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        pip:SetBackdropColor(0, 0.8, 1, 1)
        pip:SetBackdropBorderColor(0, 0.8, 1, 0.5)
        pips[i] = pip
    end

    -- Row 3: Aspect of Harmony timer
    local aspLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aspLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -64)
    aspLabel:SetText("ASPECT OF HARMONY")
    aspLabel:SetTextColor(0.67, 0.67, 0.67)

    local aspTimer = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aspTimer:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -64)
    aspTimer:SetText("--")
    aspTimer:SetTextColor(0.27, 0.27, 0.27)

    -- Drag scripts — identical pattern to MB_HUD / MB_Sidebar
    panel:SetScript("OnDragStart", function(self)
        if self.unlocked or (EditModeManager and EditModeManager:IsEditModeActive()) then
            self:StartMoving()
        end
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        MidnightBrewDB.positions = MidnightBrewDB.positions or {}
        MidnightBrewDB.positions[self:GetName()] = { p, rp, x, y }
    end)

    self.mohPanel         = panel
    self.mohVitalityLabel = vitLabel
    self.mohVitalityValue = vitValue
    self.mohVitalityBar   = vitBar
    self.mohPips          = pips
    self.mohCelLabel      = celLabel
    self.mohAspectLabel   = aspLabel
    self.mohAspectTimer   = aspTimer
    self.mohTicker        = nil
end

function UI:SetMoHAlertActive(active)
    if active then
        if not self.mohTicker then
            self.mohTicker = C_Timer.NewTicker(0.1, function()
                if not (ns.MoH and (ns.MoH.harmonyActive or ns.MoH.vitality >= 100)) then
                    self:SetMoHAlertActive(false)
                    return
                end
                if ns.MoH and ns.MoH.harmonyActive then
                    local remaining = ns.MoH.harmonyExpiry - GetTime()
                    if remaining > 0 then
                        self.mohAspectTimer:SetText(string.format("%.1fs", remaining))
                    else
                        self.mohAspectTimer:SetText("--")
                        self.mohAspectTimer:SetTextColor(0.27, 0.27, 0.27)
                    end
                else
                    self.mohAspectTimer:SetText("--")
                    self.mohAspectTimer:SetTextColor(0.27, 0.27, 0.27)
                end
                if ns.MoH and ns.MoH.vitality >= 100 and MidnightBrewDB.mohAlertBlink ~= false then
                    local alpha = 0.8 + 0.2 * math.sin(GetTime() * 2 * math.pi / 1.2)
                    self.mohVitalityLabel:SetAlpha(alpha)
                    self.mohVitalityValue:SetAlpha(alpha)
                else
                    self.mohVitalityLabel:SetAlpha(1)
                    self.mohVitalityValue:SetAlpha(1)
                end
            end)
        end
    else
        if self.mohTicker then
            self.mohTicker:Cancel()
            self.mohTicker = nil
        end
        if self.mohVitalityLabel then self.mohVitalityLabel:SetAlpha(1) end
        if self.mohVitalityValue  then self.mohVitalityValue:SetAlpha(1)  end
    end
end

function UI:UpdateMoHPanel(state)
    if not self.mohPanel then return end
    if MidnightBrewDB and MidnightBrewDB.mohEnabled == false then
        self.mohPanel:Hide()
        return
    end
    self.mohPanel:Show()

    if state.harmonyActive then
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.4, 0.4, 0.4)
        self.mohVitalityValue:SetText("-- locked --")
        self.mohVitalityValue:SetTextColor(0.4, 0.4, 0.4)
        self.mohVitalityBar:SetAlpha(0.4)
        self.mohPanel:SetBackdropBorderColor(0.29, 0.13, 0.38, 1)
        self.mohAspectLabel:SetTextColor(0.878, 0.337, 0.992)
    elseif state.vitality >= 100 then
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.878, 0.337, 0.992)
        self.mohVitalityValue:SetText("SPEND NOW")
        self.mohVitalityValue:SetTextColor(0.878, 0.337, 0.992)
        self.mohVitalityBar:SetValue(100)
        self.mohVitalityBar:SetAlpha(1)
        self.mohPanel:SetBackdropBorderColor(0.878, 0.337, 0.992, 1)
        self.mohAspectLabel:SetTextColor(0.67, 0.67, 0.67)
        self.mohAspectTimer:SetText("--")
        self.mohAspectTimer:SetTextColor(0.27, 0.27, 0.27)
    else
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.67, 0.67, 0.67)
        self.mohVitalityValue:SetText(tostring(state.vitality))
        self.mohVitalityValue:SetTextColor(0.878, 0.337, 0.992)
        self.mohVitalityBar:SetValue(state.vitality)
        self.mohVitalityBar:SetAlpha(1)
        self.mohPanel:SetBackdropBorderColor(0.29, 0.13, 0.38, 1)
        self.mohAspectLabel:SetTextColor(0.67, 0.67, 0.67)
        self.mohAspectTimer:SetText("--")
        self.mohAspectTimer:SetTextColor(0.27, 0.27, 0.27)
    end

    for i, pip in ipairs(self.mohPips) do
        if i <= state.celInfCharges then
            pip:SetBackdropColor(0, 0.8, 1, 1)
            pip:SetBackdropBorderColor(0, 0.8, 1, 0.7)
        else
            pip:SetBackdropColor(0.10, 0.16, 0.23, 1)
            pip:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
        end
    end

    self:SetMoHAlertActive(state.harmonyActive or state.vitality >= 100)
end
