-- ui/options.lua
-- Purpose: /dr options panel

local DR = _G.DungeonReminder

function DR:OpenOptions()
    if self.optionsFrame then
        self.optionsFrame:Show()
        return
    end

    local f = CreateFrame("Frame", "DrOptionsFrame", UIParent, "BackdropTemplate")
    f:SetSize(420, 320)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, .85)
    f:SetBackdropBorderColor(1, .82, 0)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Dungeon Reminder Options")

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Configure how the reminder looks.")

    local fontLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -40, -18)
    fontLabel:SetText("Reminder Font:")

    local dropdown = CreateFrame("Frame", "DrFontDropdown", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -16, -6)
    UIDropDownMenu_SetWidth(dropdown, 260)

    local function SetFont(path)
        DR:ApplyDefaults()
        DungeonReminderDB.profile.reminderFontPath = path
        DR:ApplyFlashFont()
        UIDropDownMenu_SetText(dropdown, DR:GetFontLabelByPath(path))
    end

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, font in ipairs(DR.FONT_CHOICES) do
            info.text = font.label
            info.func = function() SetFont(font.path) end
            info.checked = (DungeonReminderDB.profile and DungeonReminderDB.profile.reminderFontPath == font.path)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    DR:ApplyDefaults()
    UIDropDownMenu_SetText(dropdown, DR:GetFontLabelByPath(DungeonReminderDB.profile.reminderFontPath))

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    self.optionsFrame = f
    f:Show()
end