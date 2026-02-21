-- ui/flash.lua
-- Purpose: reminder popup UI (flash frame)

local DR = _G.DungeonReminder

-- Built-in font choices (no libs)
DR.FONT_CHOICES = {
    { label = "Friz Quadrata (Default)", path = "Fonts\\FRIZQT__.TTF" },
    { label = "Arial Narrow",            path = "Fonts\\ARIALN.TTF" },
    { label = "Morpheus",                path = "Fonts\\MORPHEUS.TTF" },
    { label = "Skurri",                  path = "Fonts\\SKURRI.TTF" },
}

function DR:GetFontLabelByPath(path)
    for _, f in ipairs(self.FONT_CHOICES) do
        if f.path == path then return f.label end
    end
    return "Custom"
end

function DR:ApplyFlashFont()
    if not (self.flashFrame and self.flashFrame.text) then return end
    self:ApplyDefaults()

    local p = DungeonReminderDB.profile
    local fontPath = p.reminderFontPath or "Fonts\\FRIZQT__.TTF"

    local _, size, flags = self.flashFrame.text:GetFont()
    size = size or 16

    self.flashFrame.text:SetFont(fontPath, size, flags)
end

function DR:ShowFlashText(msg)
    if not self.flashFrame then
        local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetSize(380, 55)
        f:SetPoint("TOP", 0, -110)
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(0, 0, 0, .85)
        f:SetBackdropBorderColor(1, .82, 0)

        local txt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        txt:SetPoint("CENTER")
        txt:SetJustifyH("CENTER")
        txt:SetTextColor(1, .93, 0)
        f.text = txt

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function()
            f:Hide()
            DR.expectedName = nil
        end)

        self.flashFrame = f
    end

    self.flashFrame.text:SetText(msg)
    self:ApplyFlashFont()
    self.flashFrame:Show()
end