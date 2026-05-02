# Master of Harmony HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a draggable `MB_MoH` panel that tracks Vitality generation, Celestial Infusion charges, and Aspect of Harmony duration for the Master of Harmony Brewmaster spec.

**Architecture:** New `MoHModule.lua` owns all data tracking via `UNIT_AURA` event scanning and populates a `ns.MoH` state table; `UI.lua` gains three new functions for panel creation, display updates, and ticker-driven alert management. The panel is a fourth draggable widget alongside the existing `MB_HUD` and `MB_Sidebar`, following their established patterns exactly.

**Tech Stack:** Lua, WoW Addon API 12.0.5, `C_UnitAuras`, `GetSpellCharges` / `C_Spell.GetSpellCharges`, `C_Timer.NewTicker`, `BackdropTemplate`

---

## File Map

| File | Change |
|------|--------|
| `MidnightBrew.toc` | Add `MoHModule.lua` after `Modules.lua` |
| `MoHModule.lua` | **Create** — spell ID constants, `ns.MoH` state table, `GetPlayerAura` / `GetCelInfCharges` helpers, `RegisterModule` callback |
| `UI.lua` | Add `UI:CreateMoHPanel()`, `UI:UpdateMoHPanel()`, `UI:SetMoHAlertActive()` |
| `Core.lua` | Add `mohEnabled = true` and `mohAlertBlink = true` to DB defaults |
| `Config.lua` | Add two `CreateToggle` calls; expand frame height |
| `Tests.lua` | Add MoH test cases to `Tests:RunAll()` |
| `README.md` | Replace Shado-Pan line with Master of Harmony |

---

### Task 1: TOC update and MoHModule.lua skeleton

**Files:**
- Modify: `MidnightBrew.toc`
- Create: `MoHModule.lua`

- [ ] **Step 1: Update MidnightBrew.toc**

Replace the full contents of `MidnightBrew.toc` with:

```
## Interface: 120005
## Title: MidnightBrew
## Notes: Premium Brewmaster Survival HUD
## SavedVariables: MidnightBrewDB, MidnightBrewDebugDB

Init.lua
Debug.lua
Core.lua
UI.lua
Modules.lua
MoHModule.lua
Config.lua
Tests.lua
```

- [ ] **Step 2: Create MoHModule.lua with constants, state table, and helpers**

Create `MoHModule.lua`:

```lua
local addonName, ns = ...
local MB = ns.Core

-- To confirm SPELL_VITALITY_AURA in-game, run:
-- /run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL") if a then print(i,a.spellId,a.name,a.applications) end end
-- Find the "Vitality" entry and update the constant below.
local SPELL_ASPECT_OF_HARMONY  = 450508  -- buff present during spending period
local SPELL_VITALITY_AURA      = 0       -- TBD: set to 0 until confirmed in-game
local SPELL_CELESTIAL_INFUSION = 1241059 -- used for charge tracking

ns.MoH = {
    vitality         = 0,
    harmonyActive    = false,
    harmonyExpiry    = 0,
    celInfCharges    = 0,
    celInfMaxCharges = 2,
}

local function GetPlayerAura(spellID)
    if spellID == 0 then return nil end
    if C_UnitAuras.GetAuraDataBySpellID then
        return C_UnitAuras.GetAuraDataBySpellID("player", spellID, "HELPFUL")
    end
    -- Fallback: scan by index (same pattern as existing Modules.lua)
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.spellId == spellID then return aura end
        i = i + 1
    end
    return nil
end

local function GetCelInfCharges()
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(SPELL_CELESTIAL_INFUSION)
        if info then return info.currentCharges or 0, info.maxCharges or 2 end
    end
    local charges, maxCharges = GetSpellCharges(SPELL_CELESTIAL_INFUSION)
    return charges or 0, maxCharges or 2
end

MB:RegisterModule("MasterOfHarmony", {"UNIT_AURA", "PLAYER_SPECIALIZATION_CHANGED"}, function(event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local hasMoH = IsSpellKnown(SPELL_ASPECT_OF_HARMONY)
        if ns.UI and ns.UI.mohPanel then
            ns.UI.mohPanel:SetShown(hasMoH and (MidnightBrewDB.mohEnabled ~= false))
        end
        return
    end
    if unit ~= "player" then return end
    -- full update logic added in Task 2
end)
```

- [ ] **Step 3: Commit**

```bash
git add MidnightBrew.toc MoHModule.lua
git commit -m "feat: add MoHModule.lua skeleton with constants and TOC entry"
```

---

### Task 2: UNIT_AURA tracking logic

**Files:**
- Modify: `MoHModule.lua`
- Modify: `Tests.lua`

- [ ] **Step 1: Replace the stub RegisterModule call with the full update**

In `MoHModule.lua`, replace the entire `MB:RegisterModule("MasterOfHarmony", ...)` block with:

```lua
MB:RegisterModule("MasterOfHarmony", {"UNIT_AURA", "PLAYER_SPECIALIZATION_CHANGED"}, function(event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local hasMoH = IsSpellKnown(SPELL_ASPECT_OF_HARMONY)
        if ns.UI and ns.UI.mohPanel then
            ns.UI.mohPanel:SetShown(hasMoH and (MidnightBrewDB.mohEnabled ~= false))
        end
        return
    end
    if unit ~= "player" then return end

    -- Aspect of Harmony (spending period active?)
    local harmonyAura = GetPlayerAura(SPELL_ASPECT_OF_HARMONY)
    if harmonyAura then
        ns.MoH.harmonyActive = true
        ns.MoH.harmonyExpiry = harmonyAura.expirationTime
    else
        ns.MoH.harmonyActive = false
        ns.MoH.harmonyExpiry = 0
    end

    -- Vitality (aura stacks — disabled until SPELL_VITALITY_AURA is confirmed)
    if not ns.MoH.harmonyActive then
        local vitalityAura = GetPlayerAura(SPELL_VITALITY_AURA)
        if vitalityAura then
            ns.MoH.vitality = math.min(100, vitalityAura.applications or 0)
        else
            ns.MoH.vitality = 0
        end
    end

    -- Celestial Infusion charges
    local charges, maxCharges = GetCelInfCharges()
    ns.MoH.celInfCharges    = charges
    ns.MoH.celInfMaxCharges = maxCharges

    if ns.UI and ns.UI.UpdateMoHPanel then
        ns.UI:UpdateMoHPanel(ns.MoH)
    end
end)
```

- [ ] **Step 2: Add state table test to Tests.lua**

In `Tests.lua`, inside `Tests:RunAll()`, add before the final `print` line:

```lua
    -- MoH Module
    ns.Debug:SafeCall(function()
        assert(ns.MoH ~= nil, "ns.MoH state table missing")
        ns.Debug:Log("TEST", "MoH State Table: Success")
    end)
```

- [ ] **Step 3: Commit**

```bash
git add MoHModule.lua Tests.lua
git commit -m "feat: implement UNIT_AURA tracking in MoHModule"
```

---

### Task 3: MB_MoH panel creation

**Files:**
- Modify: `UI.lua`
- Modify: `Tests.lua`

- [ ] **Step 1: Add UI:CreateMoHPanel() to UI.lua**

Add the following function to `UI.lua` immediately before the final `UI:Initialize()` call at the bottom of the file:

```lua
function UI:CreateMoHPanel()
    local panel = CreateFrame("Frame", "MB_MoH", UIParent, "BackdropTemplate")
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
        -- pip 2 (rightmost) at -10 from right; pip 1 at -26 from right (12px pip + 4px gap)
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

    -- EditMode registration for consistency with existing panels
    if EditModeManager then
        EditModeManager:RegisterSystem({
            instance   = panel,
            systemName = "MB_MasterOfHarmony",
            systemType = Enum.EditModeSystemType.Main,
        })
    end

    self.mohPanel         = panel
    self.mohVitalityLabel = vitLabel
    self.mohVitalityValue = vitValue
    self.mohVitalityBar   = vitBar
    self.mohPips          = pips
    self.mohAspectLabel   = aspLabel
    self.mohAspectTimer   = aspTimer
    self.mohTicker        = nil
end
```

- [ ] **Step 2: Call CreateMoHPanel from UI:Initialize()**

In `UI.lua`, find the last two lines of `UI:Initialize()`:

```lua
    MB_Sidebar:SetScript("OnDragStop", OnDragStop)
end
```

Replace with:

```lua
    MB_Sidebar:SetScript("OnDragStop", OnDragStop)
    self:CreateMoHPanel()
end
```

- [ ] **Step 3: Add panel existence test to Tests.lua**

In `Tests.lua`, inside `Tests:RunAll()`, add after the MoH state table test:

```lua
    ns.Debug:SafeCall(function()
        assert(_G["MB_MoH"] ~= nil, "MB_MoH frame not created")
        assert(ns.UI.mohPanel ~= nil, "ns.UI.mohPanel reference missing")
        ns.Debug:Log("TEST", "MoH Panel Frame: Success")
    end)
```

- [ ] **Step 4: Commit**

```bash
git add UI.lua Tests.lua
git commit -m "feat: add MB_MoH panel frame with three display rows"
```

---

### Task 4: UpdateMoHPanel + SetMoHAlertActive

**Files:**
- Modify: `UI.lua`
- Modify: `Tests.lua`

- [ ] **Step 1: Add UI:SetMoHAlertActive() to UI.lua**

Add the following function to `UI.lua` immediately before `UI:CreateMoHPanel()`:

```lua
function UI:SetMoHAlertActive(active)
    if active then
        if not self.mohTicker then
            self.mohTicker = C_Timer.NewTicker(0.1, function()
                -- Aspect of Harmony countdown
                if ns.MoH and ns.MoH.harmonyActive then
                    local remaining = ns.MoH.harmonyExpiry - GetTime()
                    if remaining > 0 then
                        self.mohAspectTimer:SetText(string.format("%.1fs", remaining))
                    else
                        self.mohAspectTimer:SetText("--")
                        self.mohAspectTimer:SetTextColor(0.27, 0.27, 0.27)
                    end
                end
                -- Vitality alert blink (alpha 1 -> 0.6, 1.2s cycle)
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
```

- [ ] **Step 2: Add UI:UpdateMoHPanel() to UI.lua**

Add the following function immediately after `UI:SetMoHAlertActive()`:

```lua
function UI:UpdateMoHPanel(state)
    if not self.mohPanel then return end
    if MidnightBrewDB and MidnightBrewDB.mohEnabled == false then
        self.mohPanel:Hide()
        return
    end
    self.mohPanel:Show()

    if state.harmonyActive then
        -- Aspect spending period: vitality generation locked
        self.mohVitalityLabel:SetText("VITALITY")
        self.mohVitalityLabel:SetTextColor(0.4, 0.4, 0.4)
        self.mohVitalityValue:SetText("-- locked --")
        self.mohVitalityValue:SetTextColor(0.4, 0.4, 0.4)
        self.mohVitalityBar:SetAlpha(0.4)
        self.mohPanel:SetBackdropBorderColor(0.29, 0.13, 0.38, 1)
        self.mohAspectLabel:SetTextColor(0.878, 0.337, 0.992)

    elseif state.vitality >= 100 then
        -- Vitality capped: alert state
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
        -- Normal: building vitality
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

    -- Celestial Infusion pips
    for i, pip in ipairs(self.mohPips) do
        if i <= state.celInfCharges then
            pip:SetBackdropColor(0, 0.8, 1, 1)
            pip:SetBackdropBorderColor(0, 0.8, 1, 0.7)
        else
            pip:SetBackdropColor(0.10, 0.16, 0.23, 1)
            pip:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
        end
    end

    -- Ticker lifecycle: start when animation is needed, stop when not
    self:SetMoHAlertActive(state.harmonyActive or state.vitality >= 100)
end
```

- [ ] **Step 3: Add UpdateMoHPanel tests to Tests.lua**

In `Tests.lua`, inside `Tests:RunAll()`, add after the MoH panel frame test:

```lua
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 50, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (normal state): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 100, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (alert state): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 0, harmonyActive = true, harmonyExpiry = GetTime() + 5, celInfCharges = 1, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (aspect active): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 0, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (reset to idle): Success")
    end)
```

- [ ] **Step 4: Commit**

```bash
git add UI.lua Tests.lua
git commit -m "feat: implement UpdateMoHPanel and SetMoHAlertActive with ticker lifecycle"
```

---

### Task 5: DB defaults and Config toggles

**Files:**
- Modify: `Core.lua`
- Modify: `Config.lua`

- [ ] **Step 1: Add mohEnabled and mohAlertBlink to DB defaults in Core.lua**

In `Core.lua`, find:

```lua
local defaults = { hudEnabled = true, sidebarEnabled = true, todThreshold = 0.15, autoMark = true }
```

Replace with:

```lua
local defaults = { hudEnabled = true, sidebarEnabled = true, todThreshold = 0.15, autoMark = true, mohEnabled = true, mohAlertBlink = true }
```

- [ ] **Step 2: Add toggles to Config.lua**

In `Config.lua`, find:

```lua
CreateToggle("DungeonIntel", "Enable Dungeon Intelligence", -120, "dungeonIntel")
```

Replace with:

```lua
CreateToggle("DungeonIntel", "Enable Dungeon Intelligence", -120, "dungeonIntel")
CreateToggle("MoH",      "Enable Master of Harmony Panel", -150, "mohEnabled")
CreateToggle("MoHBlink", "Enable Vitality Alert Blink",    -180, "mohAlertBlink")
```

- [ ] **Step 3: Expand the config window height**

In `Config.lua`, find:

```lua
frame:SetSize(400, 350)
```

Replace with:

```lua
frame:SetSize(400, 420)
```

- [ ] **Step 4: Commit**

```bash
git add Core.lua Config.lua
git commit -m "feat: add mohEnabled and mohAlertBlink config toggles"
```

---

### Task 6: README update and final wiring check

**Files:**
- Modify: `README.md`
- Modify: `Tests.lua`

- [ ] **Step 1: Update README.md**

In `README.md`, find:

```markdown
- **Shado-Pan Intelligence:** Automated tracking of the **Predictive Training** (8% DR) window.
```

Replace with:

```markdown
- **Master of Harmony Panel:** Tracks Vitality generation, Celestial Infusion charges, and Aspect of Harmony duration with a dedicated HUD panel.
```

- [ ] **Step 2: Verify the final Tests:RunAll() body**

Open `Tests.lua` and confirm it matches exactly:

```lua
function Tests:RunAll()
    ns.Debug:Log("TEST", "Starting Stability Suite...")

    ns.Debug:SafeCall(function()
        ns.UI:UpdateEHPBar(50, 500000, 100000)
        ns.Debug:Log("TEST", "EHP UI Update: Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:TriggerThreatAlert("Test Training Dummy")
        ns.Debug:Log("TEST", "Threat Alert: Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:TriggerTigerLustAlert()
        ns.Debug:Log("TEST", "Tiger's Lust Alert: Success")
    end)

    -- MoH Module
    ns.Debug:SafeCall(function()
        assert(ns.MoH ~= nil, "ns.MoH state table missing")
        ns.Debug:Log("TEST", "MoH State Table: Success")
    end)
    ns.Debug:SafeCall(function()
        assert(_G["MB_MoH"] ~= nil, "MB_MoH frame not created")
        assert(ns.UI.mohPanel ~= nil, "ns.UI.mohPanel reference missing")
        ns.Debug:Log("TEST", "MoH Panel Frame: Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 50, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (normal state): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 100, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (alert state): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 0, harmonyActive = true, harmonyExpiry = GetTime() + 5, celInfCharges = 1, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (aspect active): Success")
    end)
    ns.Debug:SafeCall(function()
        ns.UI:UpdateMoHPanel({ vitality = 0, harmonyActive = false, harmonyExpiry = 0, celInfCharges = 2, celInfMaxCharges = 2 })
        ns.Debug:Log("TEST", "MoH Update (reset to idle): Success")
    end)

    print("|cff00ff00MidnightBrew: All stability tests passed.|r")
end
```

- [ ] **Step 3: Final commit**

```bash
git add README.md Tests.lua
git commit -m "feat: complete MoH HUD — README and final test wiring"
```

---

## In-Game Verification Checklist

After loading the addon in WoW, run through the spec testing checklist:

1. Run `/mb test` — all MoH entries should log "Success"
2. Verify panel appears at the right edge of screen, dark purple, three rows visible
3. Deal damage — Vitality bar should increase (requires SPELL_VITALITY_AURA to be confirmed first)
4. Cast Celestial Infusion — verify: one pip dims, Aspect timer starts counting down, Vitality row shows `-- locked --`
5. Let Vitality reach 100 — verify purple border glow + "SPEND NOW" blink (alpha 1→0.6, soft 1.2s cycle)
6. Drag panel, `/reload` — verify position persisted
7. Enter Edit Mode — verify `MB_MasterOfHarmony` is listed and movable
8. Open `/mb`, toggle off "Master of Harmony Panel" — verify panel hides. Toggle on — panel returns
9. Toggle off "Vitality Alert Blink" — verify alert state shows glow only, no blink

**Confirming SPELL_VITALITY_AURA (required before Vitality bar works):**

Run this in-game while in combat or with buffs active:
```
/run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL") if a then print(i,a.spellId,a.name,a.applications) end end
```
Find the "Vitality" aura, note its `spellId`, then update `SPELL_VITALITY_AURA` in `MoHModule.lua` and commit:
```bash
git add MoHModule.lua
git commit -m "fix: confirm SPELL_VITALITY_AURA spell ID in-game"
```
