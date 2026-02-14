local expectedName = nil
local flashFrame = nil
local optionsFrame = nil

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        local searchResultID, newStatus = ...
        if newStatus == "inviteaccepted" then
            local resultInfo = C_LFGList.GetSearchResultInfo(searchResultID)
            if resultInfo and resultInfo.activityIDs and resultInfo.activityIDs[1] then
                local act = C_LFGList.GetActivityInfoTable(resultInfo.activityIDs[1])
                if act then
                    local name = act.fullName:gsub("%s%([^)]*%)", "")
                    print("|cffffd700Joined: |r" .. name)
                    expectedName = name
                    ShowFlashText(name)
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if expectedName and flashFrame and flashFrame:IsShown() then
            local instanceName = GetInstanceInfo()
            if instanceName == expectedName then
                flashFrame:Hide()
                expectedName = nil
            end
        end
    end
end)

function ShowFlashText(msg)
    if not flashFrame then
        flashFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        flashFrame:SetSize(380, 55)
        flashFrame:SetPoint("TOP", 0, -110)
        flashFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        flashFrame:SetBackdropColor(0, 0, 0, .85)
        flashFrame:SetBackdropBorderColor(1, .82, 0)

        local txt = flashFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        txt:SetPoint("CENTER")
        txt:SetJustifyH("CENTER")
        txt:SetTextColor(1, .93, 0)
        flashFrame.text = txt  -- Store for reuse

        local closeBtn = CreateFrame("Button", nil, flashFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function()
            flashFrame:Hide()
            expectedName = nil
        end)
    end

    flashFrame.text:SetText(msg)
    flashFrame:Show()
end

-- Slash commands
local function DrCmd(input)
    local args = {}
    for word in input:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and args[1]:lower() or ""

    if cmd == "" or cmd == "options" then
        -- Open options panel
        if not optionsFrame then
            optionsFrame = CreateFrame("Frame", "DrOptionsFrame", UIParent, "BackdropTemplate")
            optionsFrame:SetSize(400, 300)
            optionsFrame:SetPoint("CENTER")
            optionsFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            optionsFrame:SetBackdropColor(0, 0, 0, .85)
            optionsFrame:SetBackdropBorderColor(1, .82, 0)

            local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOP", 0, -10)
            title:SetText("Dungeon Reminder Options")

            local desc = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
            desc:SetText("Options panel - coming soon!")

            local closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
            closeBtn:SetPoint("TOPRIGHT", -5, -5)
            closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)
        end
        optionsFrame:Show()
    elseif cmd == "test" and args[2] then
        local testArg = table.concat(args, " ", 2):gsub(":$", "")  -- Join remaining args, strip trailing colon
        local name = testArg
        local id = tonumber(testArg)
        if id then
            local act = C_LFGList.GetActivityInfoTable(id)
            if act then
                name = act.fullName:gsub("%s%([^)]*%)", "")
            else
                print("|cffff0000Invalid dungeon ID: |r" .. id)
                return
            end
        end
        -- Assume name is valid if not ID
        print("|cffffd700Joined: |r" .. name)
        expectedName = name
        ShowFlashText(name)
    else
        print("|cffffd700Dungeon Reminder: |r /dr [options] |r- Open options |r| /dr test <dungeonId or name> |r- Test reminder")
    end
end

SLASH_DR1 = "/dr"
SlashCmdList["DR"] = DrCmd