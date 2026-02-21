-- slash.lua
-- Purpose: slash command router

local DR = _G.DungeonReminder

local function DrCmd(input)
    local args = {}
    for word in (input or ""):gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and args[1]:lower() or ""

    if cmd == "" or cmd == "options" then
        DR:OpenOptions()
        return
    end

    if cmd == "test" and args[2] then
        local testArg = table.concat(args, " ", 2):gsub(":$", "")
        local name = testArg
        local id = tonumber(testArg)

        if id then
            local act = C_LFGList.GetActivityInfoTable(id)
            if act and act.fullName then
                name = act.fullName:gsub("%s%([^)]*%)", "")
            else
                print("|cffff0000Invalid dungeon ID: |r" .. id)
                return
            end
        end

        print("|cffffd700Joined: |r" .. name)
        DR.expectedName = DR:GetExpectedInstanceNameFromActivityName(name)
        DR:ShowFlashText(name)
        return
    end

    print("|cffffd700Dungeon Reminder:|r /dr [options] - Open options | /dr test <dungeonId or name> - Test reminder")
end

SLASH_DR1 = "/dr"
SlashCmdList["DR"] = DrCmd