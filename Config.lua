local addonName, ns = ...
SLASH_MB1 = "/mb"
SlashCmdList["MB"] = function(msg)
    local cmd = msg:lower()
    if cmd == "reset" then
        MB_HUD:SetPoint("CENTER", 0, -150)
        MB_Sidebar:SetPoint("RIGHT", -50, 0)
    elseif cmd == "test" then
        ns.Tests:RunAll()
    elseif cmd == "debug" then
        for i=1, 5 do
            local l = MidnightBrewDebugDB.logs[i]
            if l then print(string.format("[%s] %s", l.category, l.message)) end
        end
    else
        print("MidnightBrew: /mb reset, /mb test, /mb debug")
    end
end
