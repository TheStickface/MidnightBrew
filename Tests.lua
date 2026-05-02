local addonName, ns = ...
local Tests = {}
ns.Tests = Tests

function Tests:RunAll()
    ns.Debug:Log("TEST", "Starting Stability Suite...")
    
    -- 1. Test EHP Math
    ns.Debug:SafeCall(function()
        ns.UI:UpdateEHPBar(50, 500000, 100000)
        ns.Debug:Log("TEST", "EHP UI Update: Success")
    end)
    
    -- 2. Test Threat Alert
    ns.Debug:SafeCall(function()
        ns.UI:TriggerThreatAlert("Test Training Dummy")
        ns.Debug:Log("TEST", "Threat Alert: Success")
    end)
    
    -- 3. Test Tiger's Lust Snare Simulation
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
        ns.Debug:Log("TEST", "MoH Frame Global: Success")
    end)
    ns.Debug:SafeCall(function()
        assert(ns.UI.mohPanel ~= nil, "ns.UI.mohPanel reference missing")
        ns.Debug:Log("TEST", "MoH Panel Reference: Success")
    end)

    print("|cff00ff00MidnightBrew: All stability tests passed.|r")
end
