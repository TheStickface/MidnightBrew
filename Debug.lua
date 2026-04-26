local addonName, ns = ...
local Debug = {}
ns.Debug = Debug

function Debug:Initialize()
    MidnightBrewDebugDB = MidnightBrewDebugDB or { logs = {}, snapshots = {}, config = { verbose = true } }
    self:Log("SYSTEM", "Diagnostic Engine Initialized")
end

function Debug:Log(category, message, data)
    local entry = { time = GetTime(), date = date("%H:%M:%S"), category = category, message = message, data = data }
    table.insert(MidnightBrewDebugDB.logs, 1, entry)
    if #MidnightBrewDebugDB.logs > 100 then table.remove(MidnightBrewDebugDB.logs) end
    if MidnightBrewDebugDB.config.verbose then
        print(string.format("|cff00ffff[MB-%s]|r %s", category, message))
    end
end

function Debug:CaptureSnapshot(reason)
    local snapshot = {
        reason = reason, timestamp = GetTime(),
        playerHP = UnitHealth("player"), stagger = UnitStagger("player"),
        pe = (ns.Core and ns.Core.energySpent) or 0
    }
    table.insert(MidnightBrewDebugDB.snapshots, 1, snapshot)
    if #MidnightBrewDebugDB.snapshots > 10 then table.remove(MidnightBrewDebugDB.snapshots) end
end

function Debug:SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        self:Log("ERROR", "Script Error: " .. tostring(err))
        self:CaptureSnapshot("Script Error")
    end
    return success
end
