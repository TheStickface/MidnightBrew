local addonName, ns = ...
local MB = ns.Core
ns.Modules = {}

-- Combat States (Heuristics)
MB.State = {
    STABLE = "STABLE",
    PRESSURE = "PRESSURE",
    CRITICAL = "CRITICAL",
    KITING = "KITING"
}
MB.CurrentState = MB.State.STABLE

-- Module Registry
local registry = {}

function MB:RegisterModule(name, events, onEvent, onUpdate)
    registry[name] = {
        events = events,
        onEvent = onEvent,
        onUpdate = onUpdate,
        enabled = true
    }
    for _, event in ipairs(events) do
        self:RegisterEvent(event)
    end
end

-- Heuristic Engine (PATCH 12.0 SECURE VERSION)
function MB:UpdateCombatState()
    -- Using C_UnitHealth to avoid "Secret Number" arithmetic errors
    local hpPct = (C_UnitHealth and C_UnitHealth.GetPercentHealth("player")) or 100
    
    -- Using C_UnitMove for secure speed detection
    local speed = (C_UnitMove and C_UnitMove.GetSpeed("player")) or 0
    local isKiting = speed > 7 
    
    local newState = MB.State.STABLE
    if hpPct < 30 then newState = MB.State.CRITICAL
    elseif hpPct < 60 then newState = MB.State.PRESSURE
    elseif isKiting and hpPct < 80 then newState = MB.State.KITING end
    
    if newState ~= MB.CurrentState then
        MB.CurrentState = newState
        ns.Debug:Log("HEURISTIC", "State Changed: " .. newState)
    end
end

function MB:DispatchModuleEvent(event, ...)
    for name, mod in pairs(registry) do
        if mod.enabled and mod.onEvent then
            mod.onEvent(event, ...)
        end
    end
end

-- DETOX SENTINEL
MB:RegisterModule("DetoxSentinel", {"UNIT_AURA"}, function(event, unit)
    if not unit or not unit:find("party") then return end
    local i = 1
    while true do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not aura then break end
        if aura.dispelName == "Poison" or aura.dispelName == "Disease" then
            ns.UI:TriggerDispelAlert(UnitName(unit), aura.dispelName)
            return
        end
        i = i + 1
    end
end)

-- PERFORMANCE AUDITOR
local damageInPull = 0
local healerManaAtStart = 1

MB:RegisterModule("Auditor", {"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_COMBAT"}, function(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        damageInPull = 0
        healerManaAtStart = (MB.healerUnit and (UnitPower(MB.healerUnit) / UnitPowerMax(MB.healerUnit))) or 1
    elseif event == "PLAYER_REGEN_ENABLED" then
        local healerManaAtEnd = (MB.healerUnit and (UnitPower(MB.healerUnit) / UnitPowerMax(MB.healerUnit))) or 1
        local manaDiff = (healerManaAtStart - healerManaAtEnd) * 100
        
        -- Secure Score Calculation (avoiding direct division if possible)
        local score = 1.0
        if damageInPull > 0 then
            score = UnitHealthMax("player") / (damageInPull + 1)
        end
        
        local rating = score > 2 and "S" or (score > 1 and "A" or "B")
        if ns.UI then ns.UI:ShowPullRating(rating) end
    end
end)

function MB:RecordCurrentTarget()
    if not UnitExists("target") then return end
    local name = UnitName("target")
    MidnightBrewDB.customMobs = MidnightBrewDB.customMobs or {}
    MidnightBrewDB.customMobs[name] = 8
    print("|cff00ccff[MB]|r: Recorded " .. name .. " as high priority.")
end
