-- core.lua
-- Purpose: core state + event logic for Dungeon Reminder

DungeonReminderDB = DungeonReminderDB or {}

local DR = {}
_G.DungeonReminder = DR

-- Core state
DR.expectedName = nil

-- Patch: activity name -> actual instance name exceptions
DR.INSTANCE_NAME_ALIASES = {
    ["Tazavesh: Streets of Wonder"] = "Tazavesh, the Veiled Market",
    ["Tazavesh: So'leah's Gambit"]  = "Tazavesh, the Veiled Market",
}

function DR:ApplyDefaults()
    DungeonReminderDB.profile = DungeonReminderDB.profile or {}
    local p = DungeonReminderDB.profile

    if not p.reminderFontPath then
        p.reminderFontPath = "Fonts\\FRIZQT__.TTF"
    end
end

function DR:GetExpectedInstanceNameFromActivityName(activityName)
    return self.INSTANCE_NAME_ALIASES[activityName] or activityName
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        DR:ApplyDefaults()
        if DR.ApplyFlashFont then DR:ApplyFlashFont() end
        return
    end

    if event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        local searchResultID, newStatus = ...
        if newStatus ~= "inviteaccepted" then return end

        local resultInfo = C_LFGList.GetSearchResultInfo(searchResultID)
        if not (resultInfo and resultInfo.activityIDs and resultInfo.activityIDs[1]) then return end

        local act = C_LFGList.GetActivityInfoTable(resultInfo.activityIDs[1])
        if not (act and act.fullName) then return end

        local displayName = act.fullName:gsub("%s%([^)]*%)", "")
        print("|cffffd700Joined: |r" .. displayName)

        DR.expectedName = DR:GetExpectedInstanceNameFromActivityName(displayName)

        if DR.ShowFlashText then
            DR:ShowFlashText(displayName)
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if not (DR.expectedName and DR.flashFrame and DR.flashFrame:IsShown()) then return end

        local instanceName = GetInstanceInfo()
        if instanceName == DR.expectedName then
            DR.flashFrame:Hide()
            DR.expectedName = nil
        end
    end
end)