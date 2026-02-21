local expectedName = nil
local flashFrame = nil
local optionsFrame = nil

-- SavedVariables
DungeonReminderDB = DungeonReminderDB or {}

local function ApplyDefaults()
    DungeonReminderDB.profile = DungeonReminderDB.profile or {}
    local p = DungeonReminderDB.profile

    -- Store the actual font path (simplest)
    if not p.flashFontPath then
        p.flashFontPath = "Fonts\\FRIZQT__.TTF" -- default WoW UI font
    end
end

-- Simple built-in font choices (no libs)
local FONT_CHOICES = {
    { label = "Friz Quadrata (Default)", path = "Fonts\\FRIZQT__.TTF" },
    { label = "Arial Narrow",            path = "Fonts\\ARIALN.TTF" },
    { label = "Morpheus",                path = "Fonts\\MORPHEUS.TTF" },
    { label = "Skurri",                  path = "Fonts\\SKURRI.TTF" },
}

local function GetFontLabelByPath(path)
    for _, f in ipairs(FONT_CHOICES) do
        if f.path == path then return f.label end
    end
    return "Custom"
end

local function ApplyFlashFont()
    if not (flashFrame and flashFrame.text) then return end
    ApplyDefaults()

    local p = DungeonReminderDB.profile
    local fontPath = p.flashFontPath or "Fonts\\FRIZQT__.TTF"

    -- Keep your existing template’s size by reading current font size
    local _, size, flags = flashFrame.text:GetFont()
    size = size or 16

    flashFrame.text:SetFont(fontPath, size, flags)
end

-- Patch: activity name -> actual instance name exceptions
local INSTANCE_NAME_ALIASES = {
    ["Tazavesh Streets"] = "Tazavesh, the Veiled Market",
    ["Tazavesh Gambit"]  = "Tazavesh, the Veiled Market",
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ApplyDefaults()
        ApplyFlashFont()
        return
    end

    if event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        local searchResultID, newStatus = ...
        if newStatus == "inviteaccepted" then
            local resultInfo = C_LFGList.GetSearchResultInfo(searchResultID)
            if resultInfo and resultInfo.activityIDs and resultInfo.activityIDs[1] then
                local act = C_LFGList.GetActivityInfoTable(resultInfo.activityIDs[1])
                if act then
                    local name = act.fullName:gsub("%s%([^)]*%)", "")
                    print("|cffffd700Joined: |r" .. name)

                    -- Patch: store the instance-match name when needed (Tazavesh wings)
                    expectedName = INSTANCE_NAME_ALIASES[name] or name

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

        ApplyFlashFont()

        local closeBtn = CreateFrame("Button", nil, flashFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function()
            flashFrame:Hide()
            expectedName = nil
        end)
    end

    flashFrame.text:SetText(msg)
    ApplyFlashFont()
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
            desc:SetText("Configure how the reminder looks.")
            
            -- Font dropdown
            local fontLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fontLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -50, -18)
            fontLabel:SetText("Reminder Font:")

            local dropdown = CreateFrame("Frame", "DrFontDropdown", optionsFrame, "UIDropDownMenuTemplate")
            dropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -16, -6)

            local function SetFont(path)
                ApplyDefaults()
                DungeonReminderDB.profile.flashFontPath = path
                ApplyFlashFont()
                UIDropDownMenu_SetText(dropdown, GetFontLabelByPath(path))
            end

            UIDropDownMenu_SetWidth(dropdown, 240)
            UIDropDownMenu_Initialize(dropdown, function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                for _, f in ipairs(FONT_CHOICES) do
                    info.text = f.label
                    info.func = function() SetFont(f.path) end
                    info.checked = (DungeonReminderDB.profile and DungeonReminderDB.profile.flashFontPath == f.path)
                    UIDropDownMenu_AddButton(info, level)
                end
            end)

            -- Set initial dropdown text
            ApplyDefaults()
            UIDropDownMenu_SetText(dropdown, GetFontLabelByPath(DungeonReminderDB.profile.flashFontPath))

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

        -- Patch: mirror the same alias behavior for /dr test
        expectedName = INSTANCE_NAME_ALIASES[name] or name

        ShowFlashText(name)
    else
        print("|cffffd700Dungeon Reminder: |r /dr [options] |r- Open options |r| /dr test <dungeonId or name> |r- Test reminder")
    end
end

SLASH_DR1 = "/dr"
SlashCmdList["DR"] = DrCmd
