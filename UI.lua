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

-- MoH color constants
local MOH_BG_COLOR = { 0.07, 0.05, 0.1, 1 }       -- #120d1a
local MOH_BORDER_COLOR = { 0.29, 0.13, 0.38, 1 }   -- #4a2060
local MOH_ALERT_BORDER = { 0.88, 0.34, 0.99, 1 }   -- #e056fd
local MOH_BAR_COLOR = { 0.6, 0.2, 0.9, 1 }         -- purple vitality bar
local MOH_PIP_LIT = { 0.7, 0.3, 1, 1 }             -- lit charge pip
local MOH_PIP_DIM = { 0.2, 0.15, 0.25, 0.5 }       -- dim charge pip

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
    self.mohFrame = MB_MoH
    self.mohPanel = MB_MoH  -- canonical reference used by tests and external callers

    -- Frame setup
    MB_MoH:SetSize(210, 80)
    MB_MoH:SetPoint("RIGHT", UIParent, "RIGHT", -160, 0)
    MB_MoH:SetMovable(true)
    MB_MoH:EnableMouse(true)
    MB_MoH:RegisterForDrag("LeftButton")
    MB_MoH:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    MB_MoH:SetBackdropColor(unpack(MOH_BG_COLOR))
    MB_MoH:SetBackdropBorderColor(unpack(MOH_BORDER_COLOR))

    -- Drag scripts (same pattern as other panels)
    MB_MoH:SetScript("OnDragStart", function(f)
        if f.unlocked or (EditModeManager and EditModeManager:IsEditModeActive()) then
            f:StartMoving()
        end
    end)
    MB_MoH:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local p, _, rp, x, y = f:GetPoint()
        MidnightBrewDB.positions = MidnightBrewDB.positions or {}
        MidnightBrewDB.positions[f:GetName()] = {p, rp, x, y}
    end)

    -- Row 1: Vitality label
    self.mohVitalityLabel = MB_MoH:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.mohVitalityLabel:SetPoint("TOPLEFT", 8, -8)
    self.mohVitalityLabel:SetText("VITALITY")
    self.mohVitalityLabel:SetTextColor(0.7, 0.3, 1)

    -- Row 1: Vitality bar
    self.mohVitalityBar = CreateFrame("StatusBar", nil, MB_MoH)
    self.mohVitalityBar:SetPoint("TOPLEFT", 8, -22)
    self.mohVitalityBar:SetPoint("TOPRIGHT", -55, -22)
    self.mohVitalityBar:SetHeight(14)
    self.mohVitalityBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.mohVitalityBar:SetStatusBarColor(unpack(MOH_BAR_COLOR))
    self.mohVitalityBar:SetMinMaxValues(0, 100)
    self.mohVitalityBar:SetValue(0)

    -- Row 1: Vitality numeric value
    self.mohVitalityValue = MB_MoH:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.mohVitalityValue:SetPoint("TOPRIGHT", -8, -22)
    self.mohVitalityValue:SetText("0")
    self.mohVitalityValue:SetJustifyH("RIGHT")
    self.mohVitalityValue:SetTextColor(1, 1, 1)

    -- Row 2: Celestial Infusion label
    self.mohCILabel = MB_MoH:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.mohCILabel:SetPoint("BOTTOMLEFT", 8, -38)
    self.mohCILabel:SetText("CELESTIAL INFUSION")
    self.mohCILabel:SetTextColor(0.7, 0.3, 1)

    -- Row 2: Charge pips (two 12x12 squares)
    self.mohPips = {}
    for i = 1, 2 do
        local pip = CreateFrame("Frame", nil, MB_MoH)
        pip:SetSize(12, 12)
        pip:SetPoint("BOTTOMLEFT", 115, -33)
        pip:SetPoint("LEFT", self.mohPips[i - 1] or pip, "RIGHT", 4, 0)
        if i == 1 then pip:SetPoint("LEFT", 115, 0) end

        pip.bg = pip:CreateTexture(nil, "BACKGROUND")
        pip.bg:SetAllPoints()
        pip.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        pip.bg:SetTextureRect(0, 0, 12, 12)

        pip:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        pip:SetBackdropBorderColor(0.3, 0.2, 0.4, 0.8)

        self.mohPips[i] = pip
    end

    -- Row 3: Aspect of Harmony label
    self.mohAspectLabel = MB_MoH:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.mohAspectLabel:SetPoint("BOTTOMLEFT", 8, -16)
    self.mohAspectLabel:SetText("ASPECT OF HARMONY")
    self.mohAspectLabel:SetTextColor(0.7, 0.3, 1)

    -- Row 3: Aspect timer value
    self.mohAspectValue = MB_MoH:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.mohAspectValue:SetPoint("BOTTOMRIGHT", -8, -16)
    self.mohAspectValue:SetText("--")
    self.mohAspectValue:SetJustifyH("RIGHT")
    self.mohAspectValue:SetTextColor(0.5, 0.5, 0.5)

    -- Store alert state
    self.mohAlertActive = false
    self.mohTicker = nil
end

function UI:UpdateMoHPanel(state)
    if not self.mohFrame then return end

    -- Check config visibility
    if MidnightBrewDB and not MidnightBrewDB.mohEnabled then
        self.mohFrame:Hide()
        return
    end
    self.mohFrame:Show()

    local vitality = state.vitality or 0
    local harmonyActive = state.harmonyActive or false
    local harmonyExpiry = state.harmonyExpiry or 0
    local charges = state.celInfCharges or 0

    -- Update vitality bar
    self.mohVitalityBar:SetValue(vitality)
    self.mohVitalityValue:SetText(tostring(vitality))

    -- Update charge pips
    for i = 1, 2 do
        local pip = self.mohPips[i]
        if i <= charges then
            pip.bg:SetColorTexture(unpack(MOH_PIP_LIT))
            pip:SetBackdropBorderColor(0.8, 0.4, 1, 1)
        else
            pip.bg:SetColorTexture(unpack(MOH_PIP_DIM))
            pip:SetBackdropBorderColor(0.3, 0.2, 0.4, 0.5)
        end
    end

    -- Handle state transitions
    if harmonyActive then
        -- Aspect active state
        self.mohVitalityBar:SetAlpha(0.4)
        self.mohVitalityLabel:SetText("-- locked --")
        self.mohVitalityLabel:SetTextColor(0.5, 0.5, 0.5)
        self.mohAspectLabel:SetTextColor(0.7, 0.3, 1)

        -- Stop alert if active
        if self.mohAlertActive then
            self:SetMoHAlertActive(false)
        end

        -- Start ticker for countdown
        self:StartMoHTicker(harmonyExpiry)

    elseif vitality >= 100 then
        -- Alert state
        self.mohVitalityBar:SetAlpha(1)
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.7, 0.3, 1)
        self.mohAspectValue:SetText("--")
        self.mohAspectValue:SetTextColor(0.5, 0.5, 0.5)

        self:SetMoHAlertActive(true)
        self:StartMoHTicker(0)

    else
        -- Idle state
        self.mohVitalityBar:SetAlpha(1)
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.7, 0.3, 1)
        self.mohAspectValue:SetText("--")
        self.mohAspectValue:SetTextColor(0.5, 0.5, 0.5)

        self:SetMoHAlertActive(false)
        self:StopMoHTicker()
    end
end

function UI:SetMoHAlertActive(active)
    self.mohAlertActive = active

    if active then
        -- Bright border + glow
        MB_MoH:SetBackdropBorderColor(unpack(MOH_ALERT_BORDER))
    else
        -- Revert to normal border
        MB_MoH:SetBackdropBorderColor(unpack(MOH_BORDER_COLOR))
        -- Reset vitality label alpha (was blinking)
        if self.mohVitalityLabel then
            self.mohVitalityLabel:SetAlpha(1)
        end
    end
end

function UI:StartMoHTicker(harmonyExpiry)
    -- Stop existing ticker to prevent orphans
    self:StopMoHTicker()

    self.mohTicker = C_Timer.NewTicker(0.1, function()
        if harmonyExpiry and harmonyExpiry > 0 then
            -- Aspect countdown
            local remaining = harmonyExpiry - GetTime()
            if remaining <= 0 then
                self.mohAspectValue:SetText("--")
                self.mohAspectValue:SetTextColor(0.5, 0.5, 0.5)
            else
                self.mohAspectValue:SetText(string.format("%.1fs", remaining))
                self.mohAspectValue:SetTextColor(0.7, 0.3, 1)
            end
        end

        -- Alert blink (softer: 1 -> 0.6, 1.2s cycle)
        if self.mohAlertActive and MidnightBrewDB and MidnightBrewDB.mohAlertBlink ~= false then
            local t = GetTime()
            local alpha = 0.6 + 0.4 * math.abs(math.sin(t * math.pi / 0.6)) -- 1.2s cycle
            self.mohVitalityLabel:SetAlpha(alpha)
        end
    end)
end

function UI:StopMoHTicker()
    if self.mohTicker then
        self.mohTicker:Cancel()
        self.mohTicker = nil
    end
end
