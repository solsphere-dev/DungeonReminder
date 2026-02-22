-- ui/options.lua
-- Purpose: /dr options panel (custom dropdown, no UIDropDownMenu / no external dropdown libs)

local DR = _G.DungeonReminder

-- ------------------------------------------------------------
-- Theme helpers (gold & black)
-- ------------------------------------------------------------
local THEME = {
  bg      = { 0.05, 0.05, 0.05, 0.92 },
  panel   = { 0.08, 0.08, 0.08, 0.95 },
  border  = { 1.00, 0.82, 0.00, 0.70 }, -- gold
  border2 = { 1.00, 0.82, 0.00, 0.35 },
  text    = { 0.90, 0.90, 0.90, 1.00 },
  textDim = { 0.70, 0.70, 0.70, 1.00 },
  hover   = { 1.00, 0.82, 0.00, 0.18 },
}

local function ApplyBackdrop(frame, bg, border, edgeSize)
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = edgeSize or 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

-- ------------------------------------------------------------
-- Custom dropdown (button + scrollable menu)
-- ------------------------------------------------------------
local function CreateScrollDropdown(parent, labelText, width, getItems, getValue, setValue, opts)
  opts = opts or {}
  local maxVisible = opts.maxVisible or 10
  local rowH = opts.rowHeight or 20
  local menuGap = opts.menuGap or 2

  local wrapper = CreateFrame("Frame", nil, parent)
  wrapper:SetSize(width, 46)

  local lbl = wrapper:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lbl:SetPoint("TOPLEFT", 0, 0)
  lbl:SetText(labelText)
  lbl:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4])

  local btn = CreateFrame("Button", nil, wrapper, "BackdropTemplate")
  btn:SetPoint("TOPLEFT", 0, -18)
  btn:SetSize(width, 24)
  ApplyBackdrop(btn, THEME.panel, THEME.border, 1)

  btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  btn.Text:SetPoint("LEFT", 8, 0)
  btn.Text:SetPoint("RIGHT", -20, 0)
  btn.Text:SetJustifyH("LEFT")
  btn.Text:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4])

  local arrow = btn:CreateTexture(nil, "OVERLAY")
  arrow:SetPoint("RIGHT", -6, 0)
  arrow:SetSize(10, 10)
  arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
  arrow:SetVertexColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], THEME.textDim[4])

  -- Menu frame lives in UIParent so it can overlay properly
  local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetClampedToScreen(true)
  ApplyBackdrop(menu, THEME.panel, THEME.border2, 1)
  menu:Hide()

  -- ScrollFrame (UIPanelScrollFrameTemplate gives you a scrollbar that "just works")
  local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 3, -3)
  scroll:SetPoint("BOTTOMRIGHT", -26, 3)

  local child = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(child)

  local rows = {}

  local function CloseMenu()
    menu:Hide()
  end

  local function RefreshText()
    local v = getValue()
    btn.Text:SetText(v or "Select...")
  end

  local function ClearRows()
    for i = 1, #rows do
      rows[i]:Hide()
      rows[i]:SetParent(nil)
      rows[i] = nil
    end
    wipe(rows)
  end

  local function BuildMenu()
    ClearRows()

    local items = getItems() or {}
    local count = #items

    local totalH = count * rowH
    local maxH = maxVisible * rowH + 6
    local shownH = math.min(totalH + 6, maxH)

    child:SetSize(width - 30, totalH)

    for i = 1, count do
      local opt = items[i] -- { value = "...", text = "..." }

      local r = CreateFrame("Button", nil, child)
      r:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      r:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)
      r:SetHeight(rowH)

      r.Text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.Text:SetPoint("LEFT", 6, 0)
      r.Text:SetPoint("RIGHT", -6, 0)
      r.Text:SetJustifyH("LEFT")
      r.Text:SetText(opt.text or opt.value or "")
      r.Text:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4])

      r.Highlight = r:CreateTexture(nil, "HIGHLIGHT")
      r.Highlight:SetAllPoints()
      r.Highlight:SetColorTexture(THEME.hover[1], THEME.hover[2], THEME.hover[3], THEME.hover[4])

      r:SetScript("OnClick", function()
        setValue(opt.value)
        RefreshText()
        CloseMenu()
      end)

      rows[#rows + 1] = r
    end

    menu:SetSize(width, shownH)

    -- If list is short, hide the scrollbar by tightening the scroll frame right edge.
    local sb = scroll.ScrollBar or _G[scroll:GetName() .. "ScrollBar"]
    if sb then
      if totalH <= (maxVisible * rowH) then
        sb:Hide()
        scroll:SetPoint("BOTTOMRIGHT", -6, 3)
      else
        sb:Show()
        scroll:SetPoint("BOTTOMRIGHT", -26, 3)
      end
    end
  end

  -- Close if you click outside the menu (simple + effective)
  -- We add an invisible fullscreen click-catcher behind the menu.
  local catcher = CreateFrame("Frame", nil, UIParent)
  catcher:SetFrameStrata("FULLSCREEN_DIALOG")
  catcher:EnableMouse(true)
  catcher:SetAllPoints(UIParent)
  catcher:Hide()
  catcher:SetScript("OnMouseDown", function()
    catcher:Hide()
    CloseMenu()
  end)

  local function OpenMenu()
    BuildMenu()
    RefreshText()

    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -menuGap)
    menu:Show()

    catcher:Show()
    -- ensure menu is above catcher
    menu:SetFrameLevel(catcher:GetFrameLevel() + 2)
  end

  btn:SetScript("OnClick", function()
    if menu:IsShown() then
      catcher:Hide()
      CloseMenu()
    else
      OpenMenu()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1.0)
  end)
  btn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])
  end)

  wrapper.Refresh = RefreshText
  RefreshText()
  return wrapper
end

-- ------------------------------------------------------------
-- Options UI
-- ------------------------------------------------------------
function DR:OpenOptions()
  if self.optionsFrame then
    self.optionsFrame:Show()
    return
  end

  local f = CreateFrame("Frame", "DrOptionsFrame", UIParent, "BackdropTemplate")
  f:SetSize(440, 260)
  f:SetPoint("CENTER")
  ApplyBackdrop(f, THEME.bg, { 1, .82, 0, 0.85 }, 1)

  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("Dungeon Reminder Options")

  local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  desc:SetPoint("TOP", title, "BOTTOM", 0, -6)
  desc:SetText("Configure how the reminder looks.")
  desc:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], THEME.textDim[4])

  -- Ensure DB has defaults
  DR:ApplyDefaults()
  local p = DungeonReminderDB.profile

  -- -----------------------------
  -- Font list helpers
  -- -----------------------------
  local function GetFontItems()
    local out = {}

    -- Preferred: LibSharedMedia
    if DR.LSM and DR.LSM.List then
      local fonts = DR.LSM:List("font")
      table.sort(fonts)
      for _, name in ipairs(fonts) do
        out[#out + 1] = { value = name, text = name }
      end
      return out
    end

    -- Fallback: DR.FONT_CHOICES (expects {label=, path=} entries)
    if DR.FONT_CHOICES then
      for _, it in ipairs(DR.FONT_CHOICES) do
        out[#out + 1] = { value = it.label, text = it.label }
      end
      table.sort(out, function(a, b) return tostring(a.text) < tostring(b.text) end)
    end

    return out
  end

  local function GetCurrentFontName()
    -- If LSM: store and display by NAME
    if DR.LSM then
      return p.reminderFontName or "Friz Quadrata (Default)"
    end
    -- Fallback: derive label from stored path if you have helper
    if DR.GetFontLabelByPath then
      return DR:GetFontLabelByPath(p.reminderFontPath) or "Default"
    end
    return "Default"
  end

  local function SetFontSelection(fontName)
    DR:ApplyDefaults()
    local prof = DungeonReminderDB.profile

    if DR.LSM then
      prof.reminderFontName = fontName
      prof.reminderFontPath = DR.LSM:Fetch("font", fontName, true) or prof.reminderFontPath
    else
      -- fallback: resolve label -> path
      if DR.FONT_CHOICES then
        for _, it in ipairs(DR.FONT_CHOICES) do
          if it.label == fontName then
            prof.reminderFontPath = it.path
            break
          end
        end
      end
    end

    -- Apply immediately
    if DR.ApplyFlashFont then
      DR:ApplyFlashFont()
    end
  end

  -- -----------------------------
  -- Reminder Font dropdown
  -- -----------------------------
  local dropdown = CreateScrollDropdown(
    f,
    "Reminder Font:",
    320,
    GetFontItems,
    GetCurrentFontName,
    SetFontSelection,
    {
      maxVisible = 10,   -- this is the “rein it in” control
      rowHeight  = 20,
      menuGap    = 2,
    }
  )
  dropdown:SetPoint("TOPLEFT", 20, -78)

  -- Close button
  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", -5, -5)
  closeBtn:SetScript("OnClick", function() f:Hide() end)

  -- Small footer hint (optional)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 12, 10)
  hint:SetText("Tip: Drag this window to move it.")
  hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 0.8)

  self.optionsFrame = f
  f:Show()
end