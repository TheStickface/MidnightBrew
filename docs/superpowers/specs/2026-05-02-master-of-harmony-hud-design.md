# Master of Harmony HUD — Design Spec
**Date:** 2026-05-02  
**Addon:** MidnightBrew (Patch 12.0.5)  
**Scope:** New `MB_MoH` tracking panel for the Master of Harmony hero talent tree

---

## Context

MidnightBrew currently has two UI elements: `MB_HUD` (EHP bar) and `MB_Sidebar` (combat state). The existing "Shado-Pan Intelligence" feature in the README was never built. The player is specced into **Master of Harmony**, not Shado-Pan, so that placeholder is replaced entirely by this spec.

---

## What We Are Building

A new draggable panel (`MB_MoH`) that tracks the three mechanics unique to Master of Harmony:

1. **Vitality** — a 0–100 resource generated from damage dealt and healing received. Cannot generate during the Aspect of Harmony spending period.
2. **Celestial Infusion charges** — 2 charges (via the Endless Draught talent). The primary spend button for Vitality.
3. **Aspect of Harmony timer** — active duration of the spending period triggered by Celestial Brew/Infusion.

---

## Panel Design

**Frame:** `MB_MoH`, 210×80, draggable, `BackdropTemplate`. Dark purple tinted background (`#120d1a`), thin purple border (`#4a2060`). Default anchor: `RIGHT, UIParent, RIGHT, -160, 0`. Position persisted in `MidnightBrewDB.positions` using the existing drag/save pattern.

### Three rows

| Row | Label | Content |
|-----|-------|---------|
| 1 | `VITALITY` | StatusBar, 0–100, purple gradient. Right side shows numeric value. |
| 2 | `CELESTIAL INFUSION` | Two pip squares (12×12). Lit = charge ready. Dim + empty border = on cooldown. |
| 3 | `ASPECT OF HARMONY` | Timer string (`4.2s`) when active, `—` dash when inactive. |

### Alert state (Vitality = 100)

- Panel border color switches to `#e056fd` with a purple outer glow (`box-shadow` equivalent: `SetBackdropBorderColor` bright + `SetAlpha` pulse via `OnUpdate`)
- Vitality label text changes to `SPEND NOW` and blinks (alpha 1 → 0.3, 0.8s cycle)
- Reverts immediately when Vitality drops below 100

### Aspect active state

- Vitality bar dims (alpha 0.4), label changes to `— locked —` in grey
- Aspect row label turns purple, timer counts down in real-time via `OnUpdate`
- Bar does not update value while locked (generation is suspended)

---

## Data Layer — `MoHModule.lua`

### Spell IDs

| Constant | Spell ID | Notes |
|----------|----------|-------|
| `SPELL_ASPECT_OF_HARMONY` | `450508` | Buff present during spending period |
| `SPELL_VITALITY_AURA` | TBD | Aura whose `.applications` (stack count) = Vitality value. **Must be confirmed in-game with:** `/run local a = C_UnitAuras.GetAuraDataBySpellID("player", SPELL_ID, "HELPFUL"); if a then print(a.spellId, a.applications) end` |
| `SPELL_CELESTIAL_INFUSION` | `1241059` | Used with `GetSpellCharges()` for charge count |

### State table

```lua
ns.MoH = {
    vitality        = 0,      -- 0–100
    harmonyActive   = false,
    harmonyExpiry   = 0,      -- GetTime() value
    celInfCharges   = 0,
    celInfMaxCharges = 2,
}
```

### Update trigger

`UNIT_AURA` event, filtered to `unit == "player"`. On each fire:
1. Scan for `SPELL_ASPECT_OF_HARMONY` via `C_UnitAuras.GetAuraDataBySpellID` → set `harmonyActive` and `harmonyExpiry`
2. Scan for `SPELL_VITALITY_AURA` → read `.applications` as `vitality` (only update if `harmonyActive == false`)
3. Call `GetSpellCharges(SPELL_CELESTIAL_INFUSION)` → set `celInfCharges`
4. Call `ns.UI:UpdateMoHPanel(ns.MoH)`

### Registration

Registered via the existing `MB:RegisterModule()` system. Module name: `"MasterOfHarmony"`.

---

## UI Layer — additions to `UI.lua`

### New functions

- `UI:CreateMoHPanel()` — builds the `MB_MoH` frame, all child elements, drag scripts. Called at the bottom of `UI.lua` alongside the existing `UI:Initialize()` call.
- `UI:UpdateMoHPanel(state)` — receives the `ns.MoH` state table and updates all display elements. Handles the alert state transition.
- `UI:SetMoHAlertActive(active)` — toggles the purple glow border and blink ticker on/off.

A `C_Timer.NewTicker(0.1, ...)` on the panel handles the Aspect of Harmony countdown display and the Vitality alert blink — stopped when not needed.

---

## TOC Changes

`MoHModule.lua` added after `Modules.lua`:

```
Modules.lua
MoHModule.lua
Config.lua
Tests.lua
```

---

## Out of Scope

- Intelligent fading (show/hide on combat) — separate feature, not in this spec
- Potential Energy / Harmonic Surge tracking — user explicitly chose Core only
- Shuffle / Purifying Brew tracking — user explicitly chose Core only
- Shado-Pan Intelligence — spec is removed; replaced by this module

---

## Open Question

The `SPELL_VITALITY_AURA` spell ID is unconfirmed. Implementation must include the in-game lookup command as a comment, and `SPELL_VITALITY_AURA` should be a named constant at the top of `MoHModule.lua` so it can be patched with a single line change if Blizzard changes the encoding.
