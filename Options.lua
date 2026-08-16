local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local WINDOW_NAME = "oUF_ManiaOptionsFrame"
local WINDOW_WIDTH = 920

local INNER_X, INNER_Y = 17, 64
local INNER_PAD = 12
local INNER_BOTTOM = 14
local TAB_X, TAB_Y = 32, 27
local LIST_WIDTH = 199
local LIST_HEIGHT = 430
local LIST_X = 18

local INNER_HEIGHT = LIST_HEIGHT + 2 * INNER_PAD
local LIST_Y = INNER_Y + INNER_PAD
local WINDOW_HEIGHT = INNER_Y + INNER_HEIGHT + INNER_BOTTOM
local LIST_SPACING = 2
local LIST_BAR_INSET = 14
local CONTENT_GAP = 16
local CONTENT_RIGHT = -22

local PAGE_GAP = 6

local ROW_HEIGHT = 38
local ROW_SPACING = 4
local LABEL_INSET = 12
local LABEL_GAP = 8
local CONTROL_COLUMN = 300
local DROPDOWN_OFFSET = 32

local LAUNCH_WIDTH = 200
local BUTTON_HEIGHT = 22
local TAG_BUTTON_WIDTH = 30
local SLIDER_STEP = 1

local OFFSET_MIN, OFFSET_MAX = -200, 200
local FREE_WIDTH_MIN, FREE_WIDTH_MAX = 40, 400
local POSITION_MIN, POSITION_MAX = -1000, 1000
local SIZE_MIN, SIZE_MAX = 0, 64
local TEXT_WIDTH_MIN, TEXT_WIDTH_MAX = 0, 300
local CASTBAR_WIDTH_MIN, CASTBAR_WIDTH_MAX = 0, 400

local SCROLL_BAR_INSET = 22
local SCROLL_BAR_GAP = 8
local SCROLL_TOLERANCE = 1

local SLIDER_WIDTH = 250
local SLIDER_INPUT_OFFSET = 25
local TAG_INPUT_OFFSET = 8
local TAG_BUTTON_OFFSET = 8
local TAG_INPUT_WIDTH = SLIDER_WIDTH + SLIDER_INPUT_OFFSET - TAG_INPUT_OFFSET - TAG_BUTTON_OFFSET
local TAG_BUTTON_RIGHT = CONTROL_COLUMN + SLIDER_WIDTH + SLIDER_INPUT_OFFSET + TAG_BUTTON_WIDTH

local PREVIEW_SHOW = "Preview"
local PREVIEW_ALL = "Preview all"
local PREVIEW_GROUP = "Preview group"
local PREVIEW_HIDE = "Stop preview"
local PREVIEW_WIDTH = 110
local HEADER_BUTTON_GAP = 6

local RELOAD_POPUP = "OUF_MANIA_RELOAD"
local DEFAULTS_POPUP = "OUF_MANIA_DEFAULTS"
local FRAME_SECTION = "frame"

local FRAME_FIELDS = {
	"enabled", "width", "height", "power", "showPower", "posX", "posY",
	"spacing", "vertical", "showPlayer", "healerPower", "hideFriendlyNPCPower",
}

local ALL_KEY = ns.ALL_KEY
local GENERAL_LABEL = "General"
local LINKED_MARKER = " *"

local UNIT_LABELS = {
	player = "Player",
	target = "Target",
	targettarget = "Target of target",
	focus = "Focus",
	pet = "Pet",
	party = "Party",
	boss = "Boss",
}

local UNITS = { { key = ALL_KEY, label = "All units" } }

for _, key in ipairs(ns.UNIT_KEYS) do
	UNITS[#UNITS + 1] = { key = key, label = UNIT_LABELS[key] }
end

local CUSTOM_TEXT_SECTION = "customtext"

local ELEMENTS = {
	{ key = CUSTOM_TEXT_SECTION, label = "Text", custom = true },
	{ key = ns.PREDICTION_SECTION, label = "Health prediction", prediction = true,
		extra = ns.PREDICTION_ELEMENTS },
	{ key = "castbar", label = "Cast bar", extra = { "castbarIcon", "castbarLatency", "castbarWidth" } },
	{ key = ns.CLASS_SLOT, label = "Class resource", bar = true },
	{ key = ns.POWER_SLOT, label = "Additional power", bar = true },
	{ key = "resting", label = "Resting icon" },
	{ key = "combat", label = "Combat icon" },
	{ key = "leader", label = "Leader icon" },
	{ key = "assistant", label = "Assistant icon" },
	{ key = "raidrole", label = "Main tank and assist" },
	{ key = "grouprole", label = "Group role icon" },
	{ key = "raidtarget", label = "Raid target marker" },
	{ key = "readycheck", label = "Ready check icon" },
	{ key = "resurrect", label = "Resurrect icon" },
	{ key = "summon", label = "Summon icon" },
	{ key = "phase", label = "Phasing icon" },
	{ key = "quest", label = "Quest icon" },
	{ key = "pvp", label = "PvP icon" },
	{ key = "pvpclass", label = "PvP classification" },
	{ key = "threat", label = "Threat glow" },
	{ key = ns.PRIORITY_SECTION, label = "Priority groups", priority = true },
}

local LINK_PADDING = 12
local LINK_WIDTH = TAG_BUTTON_RIGHT + LINK_PADDING
local LINK_TOGGLE_GAP = 2
local LINK_LINE_HEIGHT = 30
local LINK_BUTTON_WIDTH = 60
local LINK_BUTTON_GAP = 6

local EMPTY = {}
local AXES = { "x", "y" }

local ICON_SIDES = {
	{ value = "LEFT", label = "Left" },
	{ value = "RIGHT", label = "Right" },
}

local GROWTH_OPTIONS = {
	{ value = true, label = "Vertical" },
	{ value = false, label = "Horizontal" },
}

local SPACING_MIN, SPACING_MAX = 0, 60
local ICON_SIZE_MIN, ICON_SIZE_MAX = 8, 32

local SIZE_ROWS = {
	{ label = "Frame width", field = "width", min = 40, max = 400 },
	{ label = "Frame height", field = "height", min = 16, max = 100 },
	{ label = "Power bar height", field = "power", min = 2, max = 40 },
}

local SYNC_OPTIONS = {
	{ key = "playerParty", label = "Sync player and party sizes" },
	{ key = "smallFrames", label = "Sync pet, focus and target of target sizes" },
	{ key = "mirrorPosition", label = "Mirror player and target positions" },
}

local window
local content
local list
local listScroll
local listScrollBar
local header
local previewButton
local selectedElement
local pages = {}
local buttons = {}
local unitIndex = 1
local refreshing
local RefreshListLabels
local ReflowBody
local UpdateScrollBar

local function PreviewTarget()
	local unit = UNITS[unitIndex]

	if unit.key == ALL_KEY and not selectedElement then
		return
	end

	if selectedElement then
		if ns:HasPreviewArt(selectedElement.key) then
			return unit.key, selectedElement.key
		end

		return
	end

	return unit.key
end

local function PreviewMode()
	local unit, element = PreviewTarget()

	if not unit then
		return nil
	elseif element then
		return "element", unit, element
	elseif ns:HasGroupPreview(unit) then
		return "group", unit
	end

	return "unit", unit
end

local function IsPreviewing(mode, unit, element)
	if mode == "element" then
		return ns:IsPreviewSet(unit, element)
	elseif mode == "group" then
		return ns:IsGroupPreviewed(unit)
	elseif mode == "unit" then
		return ns:IsWholeUnitPreviewed(unit)
	end

	return false
end

local function RefreshPreviewButton()
	local mode, unit, element = PreviewMode()

	previewButton:SetShown(mode ~= nil)

	if IsPreviewing(mode, unit, element) then
		previewButton:SetText(PREVIEW_HIDE)
	elseif mode == "element" then
		previewButton:SetText(PREVIEW_SHOW)
	elseif mode == "group" then
		previewButton:SetText(PREVIEW_GROUP)
	else
		previewButton:SetText(PREVIEW_ALL)
	end
end

local function TogglePreview()
	local mode, unit, element = PreviewMode()
	local wanted = not IsPreviewing(mode, unit, element)

	if mode == "element" then
		ns:SetPreviewSet(unit, element, wanted)
	elseif mode == "group" then
		ns:SetGroupPreviewed(unit, wanted)
		ns:SetWholeUnitPreviewed(unit, wanted)
	elseif mode == "unit" then
		ns:SetWholeUnitPreviewed(unit, wanted)
	end

	RefreshPreviewButton()
end

local function RefreshPage(page)
	refreshing = true

	for _, refresh in ipairs(page.content.refreshers) do
		refresh()
	end

	refreshing = false
end

local function RefreshAll()
	for _, page in next, pages do
		if page.built then
			RefreshPage(page)
		end
	end

	RefreshListLabels()
end

function ns:RefreshOptionsWindow()
	RefreshAll()
end

local function RegisterControl(body, row, control)
	body.controls[#body.controls + 1] = { row = row, control = control }
	return row
end

local function TagRows(body, from, IsVisible)
	for index = from, #body.controls do
		body.controls[index].IsVisible = IsVisible
	end
end

local function PlaceRow(body, row, previous, height)
	height = height or row:GetHeight()

	if previous then
		body.contentHeight = body.contentHeight + ROW_SPACING
	end

	body.contentHeight = body.contentHeight + height
	ns:SetHeight(row, height)
	ns:SetPoint(row, "LEFT", body, "LEFT", 0, 0)
	ns:SetPoint(row, "RIGHT", body, "RIGHT", 0, 0)

	if previous then
		ns:SetPoint(row, "TOP", previous, "BOTTOM", 0, -ROW_SPACING)
	else
		ns:SetPoint(row, "TOP", body, "TOP", 0, 0)
	end

	return row
end

local function CreateRow(body, previous, label, height)
	local row = PlaceRow(body, CreateFrame("Frame", nil, body), previous, height or ROW_HEIGHT)

	if label then
		local text = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetPoint("LEFT", row, "LEFT", LABEL_INSET, 0)
		text:SetPoint("RIGHT", row, "LEFT", CONTROL_COLUMN - LABEL_GAP, 0)
		text:SetJustifyH("LEFT")
		text:SetWordWrap(false)
		text:SetText(label)
		row.Label = text
	end

	return row
end

local function AddControlRow(body, previous, label, offset, CreateControl, Refresh)
	local row = CreateRow(body, previous, label)
	local control = CreateControl(row)

	control:SetPoint("LEFT", row, "LEFT", CONTROL_COLUMN + offset, 0)

	body.refreshers[#body.refreshers + 1] = function()
		Refresh(control)
	end

	return RegisterControl(body, row, control)
end

local function AddSliderRow(body, previous, label, minValue, maxValue, getValue, setValue)
	return AddControlRow(body, previous, label, 0, function(row)
		return ns:CreateSlider(row, minValue, maxValue, SLIDER_STEP, getValue, function(value)
			if not refreshing then
				setValue(value)
			end
		end)
	end, function(slider)
		slider:SetValue(getValue())
	end)
end

local function AddToggleRow(body, previous, label, getValue, setValue)
	return AddControlRow(body, previous, label, 0, function(row)
		return ns:CreateToggle(row, "", getValue, setValue)
	end, function(toggle)
		toggle:SetValue(getValue())
	end)
end

local function AddDropdownRow(body, previous, label, options, getValue, setValue)
	return AddControlRow(body, previous, label, DROPDOWN_OFFSET, function(row)
		return ns:CreateDropdown(row, options, getValue, setValue)
	end, function(dropdown)
		dropdown:GenerateMenu()
	end)
end

local function AddColorRow(body, previous, label, getValue, setValue)
	return AddControlRow(body, previous, label, 0, function(row)
		local swatch = CreateFrame("Button", nil, row, "ColorSwatchTemplate")

		swatch:SetScript("OnClick", function()
			local info = {}
			info.r, info.g, info.b = getValue()

			info.swatchFunc = function()
				setValue(ColorPickerFrame:GetColorRGB())
			end

			info.cancelFunc = function()
				setValue(ColorPickerFrame:GetPreviousValues())
			end

			ColorPickerFrame:SetupColorPickerAndShow(info)
		end)

		return swatch
	end, function(swatch)
		swatch:SetColorRGB(getValue())
	end)
end

local function AddTagEditRow(body, previous, label, title, getValue, setValue)
	return AddControlRow(body, previous, label, TAG_INPUT_OFFSET, function(row)
		local editBox = ns:CreateEditBox(row, getValue, setValue)
		editBox:SetWidth(TAG_INPUT_WIDTH)

		local button = ns:CreateButton(row, "...", function()
			ns:OpenTagEditor(title, getValue, setValue)
		end)
		button:SetSize(TAG_BUTTON_WIDTH, BUTTON_HEIGHT)
		button:SetPoint("LEFT", editBox, "RIGHT", TAG_BUTTON_OFFSET, 0)

		return editBox
	end, function(editBox)
		editBox:Refresh()
	end)
end

local function AddAxisRows(body, previous, label, minValue, maxValue, getValue, setValue)
	local row = previous

	for index, axis in ipairs(AXES) do
		row = AddSliderRow(body, row, label .. " " .. axis:upper(), minValue, maxValue, function()
			return select(index, getValue())
		end, function(value)
			setValue(axis, value)
		end)
	end

	return row
end

local function AddMediaRow(body, previous, label, mediaType, field)
	return AddControlRow(body, previous, label, DROPDOWN_OFFSET, function(row)
		return ns:CreateMediaDropdown(row, mediaType, function()
			return ns.db[field] or LSM:GetDefault(mediaType)
		end, function(name)
			ns.db[field] = name
			ns:ApplyMedia()
		end)
	end, function(dropdown)
		dropdown:GenerateMenu()
	end)
end

local function BuildGeneralPage(body)
	local row = AddMediaRow(body, nil, "Bar texture", "statusbar", "texture")
	row = AddMediaRow(body, row, "Font", "font", "font")

	local minSize, maxSize = ns:GetFontSizeRange()
	row = AddSliderRow(body, row, "Font size", minSize, maxSize, function()
		return ns:GetFontSize()
	end, function(value)
		ns.db.fontSize = value
		ns:ApplyMedia()
	end)

	row = AddSliderRow(body, row, "Icon tag size", ICON_SIZE_MIN, ICON_SIZE_MAX, function()
		return ns:GetIconTagSize()
	end, function(value)
		ns:SetIconTagSize(value)
	end)

	row = AddDropdownRow(body, row, "Health color", ns:GetBarColorModes(), function()
		return ns:GetHealthColorMode()
	end, function(value)
		ns:SetHealthColorMode(value)
	end)

	row = AddColorRow(body, row, "Health custom color", function()
		return ns:GetHealthCustomColor()
	end, function(r, g, b)
		ns:SetHealthCustomColor(r, g, b)
	end)

	row = AddDropdownRow(body, row, "Power color", ns:GetPowerColorModes(), function()
		return ns:GetPowerColorMode()
	end, function(value)
		ns:SetPowerColorMode(value)
	end)

	for _, sync in ipairs(SYNC_OPTIONS) do
		row = AddToggleRow(body, row, sync.label, function()
			return ns:IsSyncEnabled(sync.key)
		end, function(value)
			ns:SetSyncEnabled(sync.key, value)
			RefreshAll()
		end)
	end
end

local function BuildFramePage(body, unit)
	local row = AddToggleRow(body, nil, "Enable this frame", function()
		return ns:IsUnitEnabled(unit)
	end, function(value)
		ns:SetUnitEnabled(unit, value)
		StaticPopup_Show(RELOAD_POPUP)
	end)

	row = AddAxisRows(body, row, "Position", POSITION_MIN, POSITION_MAX, function()
		return ns:GetUnitOffset(unit)
	end, function(axis, value)
		ns:SetUnitOffset(unit, axis, value)
	end)

	for index, size in ipairs(SIZE_ROWS) do
		row = AddSliderRow(body, row, size.label, size.min, size.max, function()
			return math.floor(select(index, ns:GetUnitSizes(unit)) + 0.5)
		end, function(value)
			ns:SetUnitSize(unit, size.field, value)
		end)
	end

	row = AddToggleRow(body, row, "Show the power bar", function()
		return ns:IsUnitPowerShown(unit)
	end, function(value)
		ns:SetUnitPowerEnabled(unit, value)
	end)

	row = AddToggleRow(body, row, "Only on healers", function()
		return ns:IsHealerPowerOnly(unit)
	end, function(value)
		ns:SetHealerPowerOnly(unit, value)
	end)

	row = AddToggleRow(body, row, "Hide on friendly NPCs", function()
		return ns:IsHidingFriendlyNPCPower(unit)
	end, function(value)
		ns:SetHideFriendlyNPCPower(unit, value)
	end)

	if unit == "party" then
		row = AddDropdownRow(body, row, "Growth", GROWTH_OPTIONS, function()
			return ns:IsPartyVertical()
		end, function(vertical)
			ns:SetPartyVertical(vertical)
		end)

		row = AddToggleRow(body, row, "Show the player", function()
			return ns:IsPartyPlayerShown()
		end, function(value)
			ns:SetPartyPlayerShown(value)
		end)
	end

	if ns:HasUnitSpacing(unit) then
		AddSliderRow(body, row, "Gap between units", SPACING_MIN, SPACING_MAX, function()
			return ns:GetUnitSpacing(unit)
		end, function(value)
			ns:SetUnitSpacing(unit, value)
		end)
	end
end

local function SetRowEnabled(entry, enabled)
	local labelColor = enabled and NORMAL_FONT_COLOR or GRAY_FONT_COLOR
	local control = entry.control
	local isEditBox = control.IsObjectType and control:IsObjectType("EditBox")
	local controlColor = (enabled and isEditBox) and HIGHLIGHT_FONT_COLOR or labelColor

	if control.SetEnabled then
		control:SetEnabled(enabled)
	end

	if control.SetTextColor then
		control:SetTextColor(controlColor:GetRGB())
	end

	entry.row.Label:SetTextColor(labelColor:GetRGB())
end

local function AddLinkRow(body, previous, element, units)
	local available = LINK_WIDTH - 2 * LINK_PADDING
	local top = 2 * LINK_PADDING + BUTTON_HEIGHT
	local row = CreateRow(body, previous, nil, LINK_LINE_HEIGHT)

	local inset = ns:CreateInset(body)
	ns:SetPoint(inset, "TOPLEFT", row, "TOPLEFT", 0, 0)
	ns:SetPoint(inset, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, LINK_PADDING)

	local header = ns:CreateSectionHeader(row, "Applies to")
	header.Divider:Hide()
	ns:SetHeight(header, BUTTON_HEIGHT)
	ns:SetPoint(header, "TOPLEFT", inset, "TOPLEFT", LINK_PADDING, -LINK_PADDING)
	ns:SetPoint(header, "TOPRIGHT", inset, "TOPRIGHT", -LINK_PADDING, -LINK_PADDING)
	ns:SetPoint(header.Title, "LEFT", header, "LEFT", 0, 0)

	local toggles = {}
	local x, line, toggleHeight = 0, 0, LINK_LINE_HEIGHT
	local toggle, toggleWidth

	for index, key in ipairs(units) do
		toggle = ns:CreateToggle(row, UNIT_LABELS[key], function()
			return ns:IsElementLinked(key, element)
		end, function(value)
			ns:SetElementLinked(key, element, value)
			RefreshAll()
		end)

		toggleWidth = toggle:GetWidth() + toggle.Text:GetStringWidth() + LINK_TOGGLE_GAP
		toggleHeight = toggle:GetHeight()

		if x > 0 and x + toggleWidth > available then
			x, line = 0, line + 1
		end

		ns:SetPoint(toggle, "TOPLEFT", row, "TOPLEFT",
			LINK_PADDING + x + toggleWidth - toggle:GetWidth(),
			-(top + line * LINK_LINE_HEIGHT))

		x = x + toggleWidth + LINK_PADDING
		toggles[index] = toggle
	end

	local rowHeight = top + line * LINK_LINE_HEIGHT + toggleHeight + 2 * LINK_PADDING

	body.contentHeight = body.contentHeight + rowHeight - LINK_LINE_HEIGHT
	ns:SetHeight(row, rowHeight)
	ns:SetWidth(inset, LINK_WIDTH)

	local function SetAll(linked)
		for _, key in ipairs(units) do
			ns:SetElementLinked(key, element, linked)
		end

		RefreshAll()
	end

	local none = ns:CreateButton(header, "None", function()
		SetAll(false)
	end)
	none:SetSize(LINK_BUTTON_WIDTH, BUTTON_HEIGHT)
	ns:SetPoint(none, "RIGHT", header, "RIGHT", 0, 0)

	local all = ns:CreateButton(header, "All", function()
		SetAll(true)
	end)
	all:SetSize(LINK_BUTTON_WIDTH, BUTTON_HEIGHT)
	ns:SetPoint(all, "RIGHT", none, "LEFT", -LINK_BUTTON_GAP, 0)

	body.refreshers[#body.refreshers + 1] = function()
		for index, key in ipairs(units) do
			toggles[index]:SetValue(ns:IsElementLinked(key, element))
		end
	end

	return row
end

local function StorageUnit(unit, element)
	if unit ~= ALL_KEY then
		return unit
	end

	local units = ns:GetElementUnits(element)

	return #units == 1 and units[1] or ALL_KEY
end

local function AnchorOptions(element)
	local options = {}

	for _, point in ipairs(ns:GetAnchorPoints(element)) do
		options[#options + 1] = { value = point, label = point }
	end

	return options
end

local function BuildElementPage(body, unit, info)
	local units = ns:GetElementUnits(info.key)
	local multiUnit = #units > 1
	local storageUnit = StorageUnit(unit, info.key)
	local row

	local function IsDetached()
		return ns:GetElementPlacement(storageUnit, info.key) == ns.PLACEMENT_FREE
	end

	local function IsBelow()
		return ns:GetElementPlacement(storageUnit, info.key) == ns.PLACEMENT_OUTSIDE
	end

	local function IsStacked()
		return not IsDetached()
	end

	local function IsBoxed()
		return IsBelow() or IsDetached()
	end

	if unit == ALL_KEY then
		if multiUnit then
			row = AddLinkRow(body, nil, info.key, units)
		end
	elseif multiUnit then
		row = AddToggleRow(body, nil, "Use All units settings", function()
			return ns:IsElementLinked(unit, info.key)
		end, function(value)
			ns:SetElementLinked(unit, info.key, value)
			RefreshAll()
		end)
	end

	local first = #body.controls + 1

	row = AddToggleRow(body, row, "Show", function()
		return ns:IsElementShown(storageUnit, info.key)
	end, function(value)
		ns:SetElementShown(storageUnit, info.key, value)
	end)

	if info.tag then
		row = AddTagEditRow(body, row, "Tag", info.label, function()
			return ns:GetElementTag(storageUnit, info.key)
		end, function(text)
			ns:SetElementTag(storageUnit, info.key, text)
		end)
	end

	if ns:HasElementAnchor(info.key) then
		row = AddDropdownRow(body, row, info.tag and "Alignment" or "Anchor point",
			AnchorOptions(info.key), function()
			return ns:GetElementAnchor(storageUnit, info.key)
		end, function(point)
			ns:SetElementAnchor(storageUnit, info.key, point)
		end)
	end

	if ns:HasElementPlacement(info.key) then
		row = AddDropdownRow(body, row, "Placement", ns:GetPlacements(info.key), function()
			return ns:GetElementPlacement(storageUnit, info.key)
		end, function(placement)
			ns:SetElementPlacement(storageUnit, info.key, placement)
			ReflowBody(body)
		end)
	end

	if ns:HasFreePlacement(info.key) then
		local from = #body.controls + 1

		if info.key ~= "castbar" then
			row = AddSliderRow(body, row, "Width", FREE_WIDTH_MIN, FREE_WIDTH_MAX, function()
				return ns:GetElementSize(storageUnit, info.key .. "Width")
			end, function(value)
				ns:SetElementSize(storageUnit, info.key .. "Width", value)
			end)
		end

		row = AddAxisRows(body, row, "Position", POSITION_MIN, POSITION_MAX,
			function()
				return ns:GetElementPosition(storageUnit, info.key)
			end, function(axis, value)
				ns:SetElementPosition(storageUnit, info.key, axis, value)
			end)

		TagRows(body, from, IsDetached)
	end

	if ns:HasElementPixelSnap(info.key) then
		local from = #body.controls + 1

		row = AddToggleRow(body, row, "Snap frame width to fit the bars", function()
			return ns:IsElementPixelSnapped(storageUnit, info.key)
		end, function(value)
			ns:SetElementPixelSnapped(storageUnit, info.key, value)
		end)

		TagRows(body, from, IsStacked)
	end

	if ns:HasElementLevel(info.key) then
		local minLevel, maxLevel = ns:GetElementLevelRange()

		row = AddSliderRow(body, row, "Frame level", minLevel, maxLevel, function()
			return ns:GetElementLevel(storageUnit, info.key)
		end, function(value)
			ns:SetElementLevel(storageUnit, info.key, value)
		end)
	end

	local offsetFrom = #body.controls + 1

	row = AddAxisRows(body, row, "Offset", OFFSET_MIN, OFFSET_MAX, function()
		return ns:GetElementOffset(storageUnit, info.key)
	end, function(axis, value)
		ns:SetElementOffset(storageUnit, info.key, axis, value)
	end)

	if ns:HasElementPlacement(info.key) then
		TagRows(body, offsetFrom, IsBelow)
	end

	if info.key == "castbar" then
		row = AddDropdownRow(body, row, "Icon side", ICON_SIDES, function()
			return ns:GetElementAnchor(storageUnit, "castbarIcon")
		end, function(point)
			ns:SetElementAnchor(storageUnit, "castbarIcon", point)
		end)

		row = AddAxisRows(body, row, "Icon offset", OFFSET_MIN, OFFSET_MAX, function()
			return ns:GetElementOffset(storageUnit, "castbarIcon")
		end, function(axis, value)
			ns:SetElementOffset(storageUnit, "castbarIcon", axis, value)
		end)

		row = AddSliderRow(body, row, "Height", SIZE_MIN, SIZE_MAX, function()
			return ns:GetElementSize(storageUnit, "castbar")
		end, function(value)
			ns:SetElementSize(storageUnit, "castbar", value)
		end)

		local widthFrom = #body.controls + 1

		row = AddSliderRow(body, row, "Width (0 = match frame)", CASTBAR_WIDTH_MIN,
			CASTBAR_WIDTH_MAX, function()
				return ns:GetElementSize(storageUnit, "castbarWidth")
			end, function(value)
				ns:SetElementSize(storageUnit, "castbarWidth", value)
			end)

		TagRows(body, widthFrom, IsBoxed)

		if storageUnit == "player" or storageUnit == ALL_KEY then
			row = AddToggleRow(body, row, "Show latency", function()
				return ns:IsElementShown(storageUnit, "castbarLatency")
			end, function(value)
				ns:SetElementShown(storageUnit, "castbarLatency", value)
			end)
		end
	end

	if info.key == "quest" then
		row = AddDropdownRow(body, row, "Icon style", ns:GetQuestIconStyles(), function()
			return ns:GetQuestIconStyle()
		end, function(value)
			ns:SetQuestIconStyle(value)
		end)
	end

	if info.key == "grouprole" then
		row = AddDropdownRow(body, row, "Icon style", ns:GetRoleIconStyles(), function()
			return ns:GetRoleIconStyle()
		end, function(value)
			ns:SetRoleIconStyle(value)
		end)
	end

	if info.key == "pvp" then
		row = AddDropdownRow(body, row, "Icon style", ns:GetPvPIconStyles(), function()
			return ns:GetPvPIconStyle()
		end, function(value)
			ns:SetPvPIconStyle(value)
		end)
	end

	if info.key ~= "castbar" and ns:HasElementSize(info.key) then
		row = AddSliderRow(body, row, info.bar and "Height" or "Size", SIZE_MIN, SIZE_MAX, function()
			return ns:GetElementSize(storageUnit, info.key)
		end, function(value)
			ns:SetElementSize(storageUnit, info.key, value)
		end)
	end

	if ns:HasElementColorMode(info.key) then
		row = AddDropdownRow(body, row, "Color", ns:GetBarColorModes(), function()
			return ns:GetElementColorMode(storageUnit, info.key)
		end, function(value)
			ns:SetElementColorMode(storageUnit, info.key, value)
		end)

		row = AddColorRow(body, row, "Custom color", function()
			return ns:GetElementColor(storageUnit, info.key)
		end, function(r, g, b)
			ns:SetElementColor(storageUnit, info.key, r, g, b)
		end)
	end

	if ns:HasElementWidth(info.key) then
		AddSliderRow(body, row, "Max width (0 = unlimited)", TEXT_WIDTH_MIN, TEXT_WIDTH_MAX,
			function()
				return ns:GetElementWidth(storageUnit, info.key)
			end, function(value)
				ns:SetElementWidth(storageUnit, info.key, value)
			end)
	end

	ReflowBody(body)

	if unit == ALL_KEY or not multiUnit then
		return
	end

	local last = #body.controls

	body.refreshers[#body.refreshers + 1] = function()
		local enabled = not ns:IsElementLinked(unit, info.key)

		for index = first, last do
			SetRowEnabled(body.controls[index], enabled)
		end
	end
end

local PREDICTION_SECTION = ns.PREDICTION_SECTION
local PREDICTION_TAB_WIDTH = 640
local ALPHA_PERCENT_MAX = 100

local PREDICTION_DESCRIPTION = "Incoming healing and absorbs are drawn inside the health bar. An "
	.. "amount that does not fit is marked at the bar's edge rather than drawn past it."

local PREDICTION_LABELS = {
	healingPlayer = "Your incoming heals",
	healingOther = "Other incoming heals",
	damageAbsorb = "Damage absorbs",
	healAbsorb = "Heal absorbs",
	tempLoss = "Max health loss",
}

local function AddDescriptionRow(body, previous, text)
	local description = ns:CreateDescription(body, PREDICTION_TAB_WIDTH - LABEL_INSET, text)
	local row = CreateRow(body, previous, nil, description:GetHeight())

	description:SetParent(row)
	description:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_INSET, 0)

	return row
end

local function AddHeaderRow(body, previous, label)
	local row = CreateRow(body, previous, nil, ROW_HEIGHT)
	local header = ns:CreateSectionHeader(row, label)

	ns:SetPoint(header, "TOPLEFT", row, "TOPLEFT", LABEL_INSET, 0)
	ns:SetPoint(header, "TOPRIGHT", row, "TOPRIGHT", -LABEL_INSET, 0)

	return row
end

local function AddPredictionRows(body, previous, unit, element)
	local row = AddHeaderRow(body, previous, PREDICTION_LABELS[element])

	row = AddToggleRow(body, row, "Show", function()
		return ns:IsElementShown(unit, element)
	end, function(value)
		ns:SetElementShown(unit, element, value)
	end)

	row = AddColorRow(body, row, "Color", function()
		return ns:GetElementColor(unit, element)
	end, function(r, g, b)
		ns:SetElementColor(unit, element, r, g, b)
	end)

	return AddSliderRow(body, row, "Opacity", 0, ALPHA_PERCENT_MAX, function()
		return Round(ns:GetElementAlpha(unit, element) * ALPHA_PERCENT_MAX)
	end, function(value)
		ns:SetElementAlpha(unit, element, value / ALPHA_PERCENT_MAX)
	end)
end

local function BuildPredictionPage(body, unit)
	local units = ns:GetElementUnits(PREDICTION_SECTION)
	local multiUnit = #units > 1
	local storageUnit = StorageUnit(unit, PREDICTION_SECTION)
	local row = AddDescriptionRow(body, nil, PREDICTION_DESCRIPTION)

	if unit == ALL_KEY then
		if multiUnit then
			row = AddLinkRow(body, row, PREDICTION_SECTION, units)
		end
	elseif multiUnit then
		row = AddToggleRow(body, row, "Use All units settings", function()
			return ns:IsElementLinked(unit, PREDICTION_SECTION)
		end, function(value)
			ns:SetElementLinked(unit, PREDICTION_SECTION, value)
			RefreshAll()
		end)
	end

	local first = #body.controls + 1

	for _, element in ipairs(ns.PREDICTION_ELEMENTS) do
		row = AddPredictionRows(body, row, storageUnit, element)
	end

	if unit == ALL_KEY or not multiUnit then
		return
	end

	local last = #body.controls

	body.refreshers[#body.refreshers + 1] = function()
		local enabled = not ns:IsElementLinked(unit, PREDICTION_SECTION)

		for index = first, last do
			SetRowEnabled(body.controls[index], enabled)
		end
	end
end

local CUSTOM_TEXT_TAB_WIDTH = 640
local DELETE_CUSTOM_TEXT_POPUP = "OUF_MANIA_DELETE_CUSTOM_TEXT"

local function CustomTextEntries()
	local entries = {
		{ key = "name", label = "Name text", locked = true },
		{ key = "health", label = "Health text", locked = true },
	}

	for _, entry in ipairs(ns:GetCustomTexts()) do
		entries[#entries + 1] = { key = entry.key, label = entry.label }
	end

	return entries
end

local function CustomTextLabel(key)
	for _, entry in ipairs(CustomTextEntries()) do
		if entry.key == key then
			return entry.label
		end
	end
end

local function GateMouseWheel(scroll)
	local onMouseWheel = scroll:GetScript("OnMouseWheel")

	scroll:SetScript("OnMouseWheel", function(self, value)
		if self.scrollable then
			onMouseWheel(self, value)
		end
	end)
end

function ReflowBody(body)
	local previous
	local visible

	body.contentHeight = 0

	for _, entry in ipairs(body.controls) do
		visible = not entry.IsVisible or entry.IsVisible()

		entry.row:SetShown(visible)

		if visible then
			entry.row:ClearAllPoints()
			PlaceRow(body, entry.row, previous)
			previous = entry.row
		end
	end

	body:SetHeight(body.contentHeight)

	if body.page then
		UpdateScrollBar(body.page.scroll, body.page.scrollBar, body)
	end
end

function UpdateScrollBar(scroll, scrollBar, content)
	local viewport = scroll:GetHeight()
	local overflow = content:GetHeight() - viewport

	if overflow <= SCROLL_TOLERANCE then
		content:SetHeight(viewport)
		scroll:SetVerticalScroll(0)
		overflow = 0
	end

	scroll.scrollable = overflow > 0
	scrollBar:SetShown(scroll.scrollable)
end

local function BuildCustomTextPage(body, unit)
	body.selectedTextKey = body.selectedTextKey or "name"
	body.fieldsByKey = body.fieldsByKey or {}

	local function ForgetFields(key)
		if body.fieldsByKey[key] then
			body.fieldsByKey[key]:Hide()
			body.fieldsByKey[key] = nil
		end
	end

	local function ShowFields()
		local key = body.selectedTextKey
		local fields = body.fieldsByKey[key]

		if not fields then
			fields = CreateFrame("Frame", nil, body)
			fields.refreshers = {}
			fields.controls = {}
			fields.contentHeight = 0
			fields:SetPoint("TOPLEFT", body.strip, "BOTTOMLEFT", 0, -PAGE_GAP)
			fields:SetPoint("RIGHT", body, "RIGHT", 0, 0)

			BuildElementPage(fields, unit, { key = key, label = CustomTextLabel(key), tag = true })
			fields:SetHeight(fields.contentHeight)

			body.fieldsByKey[key] = fields
		end

		for otherKey, other in next, body.fieldsByKey do
			other:SetShown(otherKey == key)
		end

		body.fields = fields
		RefreshPage({ content = fields })

		body.contentHeight = body.strip:GetHeight() + PAGE_GAP + fields.contentHeight
		body:SetHeight(body.contentHeight)

		if body.container then
			UpdateScrollBar(body.container.scroll, body.container.scrollBar, body)
		end
	end

	function body:Resync()
		for key in next, body.fieldsByKey do
			if not CustomTextLabel(key) then
				ForgetFields(key)
			end
		end

		if not CustomTextLabel(body.selectedTextKey) then
			body.selectedTextKey = "name"
		end

		body.strip:SetEntries(CustomTextEntries(), body.selectedTextKey)
		ShowFields()
	end

	local function SelectText(key)
		body.selectedTextKey = key
		body.strip:SetEntries(CustomTextEntries(), key)
		ShowFields()
	end

	local function CreateText(label)
		local key = ns:AddCustomTextElement(label)

		body.selectedTextKey = key
		body.strip:SetEntries(CustomTextEntries(), key)
		ShowFields()
	end

	local function RenameText(key, label)
		ns:RenameCustomTextElement(key, label)
		body.strip:SetEntries(CustomTextEntries(), body.selectedTextKey)
		ForgetFields(key)

		if body.selectedTextKey == key then
			ShowFields()
		end
	end

	local function DoDeleteText(key)
		if body.selectedTextKey == key then
			local entries = CustomTextEntries()

			for index, entry in ipairs(entries) do
				if entry.key == key then
					body.selectedTextKey = entries[index - 1] and entries[index - 1].key or "name"
					break
				end
			end
		end

		ns:RemoveCustomTextElement(key)
		ForgetFields(key)
		body.strip:SetEntries(CustomTextEntries(), body.selectedTextKey)
		ShowFields()
	end

	local function DeleteText(key)
		StaticPopup_Show(DELETE_CUSTOM_TEXT_POPUP, CustomTextLabel(key), nil, function()
			DoDeleteText(key)
		end)
	end

	body.strip = ns:CreateEditableTabStrip(body, CUSTOM_TEXT_TAB_WIDTH, SelectText, CreateText, RenameText,
		DeleteText)
	body.strip:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)

	body.refreshers[1] = function()
		for _, refresh in ipairs(body.fields.refreshers) do
			refresh()
		end
	end

	body.strip:SetEntries(CustomTextEntries(), body.selectedTextKey)
	ShowFields()
end

local PRIORITY_SECTION = ns.PRIORITY_SECTION
local PRIORITY_TAB_WIDTH = 640
local STEPPER_GAP = 4
local PRIORITY_LIST_WIDTH = TAG_BUTTON_RIGHT
local DELETE_PRIORITY_GROUP_POPUP = "OUF_MANIA_DELETE_PRIORITY_GROUP"
local PRIORITY_DESCRIPTION = "Only one indicator in a group is shown at a time. The one highest in "
	.. "the list wins, and the rest stay hidden while it is visible. Groups themselves are shared "
	.. "by every unit, but which indicators are in them, and in what order, is set per unit."

local function ElementLabel(key)
	for _, info in ipairs(ELEMENTS) do
		if info.key == key then
			return info.label
		end
	end

	return key
end

local function PriorityGroupLabel(key)
	for _, entry in ipairs(ns:GetPriorityGroups()) do
		if entry.key == key then
			return entry.label
		end
	end
end

local function ResyncPriorityPages()
	local page

	for _, info in ipairs(UNITS) do
		page = pages[info.key .. "/" .. PRIORITY_SECTION]

		if page and page.built then
			page.content:Resync()
		end
	end
end

local function BuildPriorityPage(body, unit)
	local units = ns:GetElementUnits(PRIORITY_SECTION)
	local multiUnit = #units > 1
	local groups = ns:GetPriorityGroups()

	body.selectedGroupKey = body.selectedGroupKey or (groups[1] and groups[1].key)

	local function MemberEntries()
		local entries = {}

		if body.selectedGroupKey then
			for _, element in ipairs(ns:GetPriorityMembers(unit, body.selectedGroupKey)) do
				entries[#entries + 1] = { key = element, label = ElementLabel(element) }
			end
		end

		return entries
	end

	local function Candidates()
		local options = {}

		for _, element in ipairs(ns:GetPriorityCandidates(unit)) do
			options[#options + 1] = { value = element, label = ElementLabel(element) }
		end

		return options
	end

	local function Layout()
		local hasGroup = body.selectedGroupKey ~= nil
		local candidates

		if body.pendingElement and ns:GetPriorityGroupOf(unit, body.pendingElement) then
			body.pendingElement = nil
		end

		if not body.pendingElement then
			candidates = Candidates()
			body.pendingElement = candidates[1] and candidates[1].value
		end

		body.members:SetShown(hasGroup)
		body.list:SetShown(hasGroup)
		body.list:SetEntries(MemberEntries())

		body.contentHeight = body.description:GetHeight() + PAGE_GAP + body.strip:GetHeight()
			+ PAGE_GAP + body.links:GetHeight()

		if hasGroup then
			body.contentHeight = body.contentHeight + PAGE_GAP + body.members:GetHeight()
				+ PAGE_GAP + body.list:GetHeight()
		end

		body:SetHeight(body.contentHeight)

		if body.container then
			UpdateScrollBar(body.container.scroll, body.container.scrollBar, body)
		end
	end

	local function SelectGroup(key)
		body.selectedGroupKey = key
		body.pendingElement = nil
		body.strip:SetEntries(ns:GetPriorityGroups(), key)
		Layout()
	end

	local function CreateGroup(label)
		body.selectedGroupKey = ns:AddPriorityGroup(label)
		body.pendingElement = nil
		ResyncPriorityPages()
	end

	local function RenameGroup(key, label)
		ns:RenamePriorityGroup(key, label)
		ResyncPriorityPages()
	end

	local function DoDeleteGroup(key)
		local entries = ns:GetPriorityGroups()

		if body.selectedGroupKey == key then
			for index, entry in ipairs(entries) do
				if entry.key == key then
					body.selectedGroupKey = (entries[index - 1] or entries[index + 1] or EMPTY).key
					break
				end
			end
		end

		ns:RemovePriorityGroup(key)
		ResyncPriorityPages()
		RefreshAll()
	end

	local function DeleteGroup(key)
		StaticPopup_Show(DELETE_PRIORITY_GROUP_POPUP, PriorityGroupLabel(key), nil, function()
			DoDeleteGroup(key)
		end)
	end

	body.description = ns:CreateDescription(body, PRIORITY_TAB_WIDTH - LABEL_INSET,
		PRIORITY_DESCRIPTION)
	body.description:SetPoint("TOPLEFT", body, "TOPLEFT", LABEL_INSET, 0)

	body.strip = ns:CreateEditableTabStrip(body, PRIORITY_TAB_WIDTH, SelectGroup, CreateGroup,
		RenameGroup, DeleteGroup)
	body.strip:SetPoint("TOPLEFT", body.description, "BOTTOMLEFT", -LABEL_INSET, -PAGE_GAP)

	local links = CreateFrame("Frame", nil, body)
	links.refreshers = {}
	links.controls = {}
	links.contentHeight = 0
	links:SetPoint("TOPLEFT", body.strip, "BOTTOMLEFT", 0, -PAGE_GAP)
	links:SetPoint("RIGHT", body, "RIGHT", 0, 0)
	body.links = links

	if unit == ALL_KEY then
		if multiUnit then
			AddLinkRow(links, nil, PRIORITY_SECTION, units)
		end
	elseif multiUnit then
		AddToggleRow(links, nil, "Use All units settings", function()
			return ns:IsElementLinked(unit, PRIORITY_SECTION)
		end, function(value)
			ns:SetElementLinked(unit, PRIORITY_SECTION, value)
			ResyncPriorityPages()
			RefreshAll()
		end)
	end

	links:SetHeight(links.contentHeight)

	local members = CreateFrame("Frame", nil, body)
	members.refreshers = {}
	members.controls = {}
	members.contentHeight = 0
	members:SetPoint("TOPLEFT", links, "BOTTOMLEFT", 0, -PAGE_GAP)
	members:SetPoint("RIGHT", body, "RIGHT", 0, 0)
	body.members = members

	local addButton, addDropdown, addRow

	AddControlRow(members, nil, "Add indicator", DROPDOWN_OFFSET, function(controlRow)
		local dropdown = ns:CreateDropdown(controlRow, Candidates, function()
			return body.pendingElement
		end, function(value)
			body.pendingElement = value
		end)

		addDropdown = dropdown
		addRow = controlRow

		addButton = ns:CreateButton(controlRow, "Add", function()
			if body.pendingElement and body.selectedGroupKey then
				ns:AddPriorityMember(unit, body.selectedGroupKey, body.pendingElement)
				body.pendingElement = nil
				ResyncPriorityPages()
				RefreshAll()
			end
		end)
		addButton:SetSize(LINK_BUTTON_WIDTH, BUTTON_HEIGHT)

		return dropdown
	end, function(dropdown)
		dropdown:GenerateMenu()
	end)

	addButton:SetPoint("RIGHT", addRow, "LEFT", TAG_BUTTON_RIGHT, 0)

	addDropdown:ClearAllPoints()
	addDropdown:SetPoint("RIGHT", addButton, "LEFT",
		-(TAG_BUTTON_OFFSET + STEPPER_GAP + addDropdown.IncrementButton:GetWidth()), 0)

	members:SetHeight(members.contentHeight)

	body.list = ns:CreateOrderedList(body, PRIORITY_LIST_WIDTH, function(key, delta)
		ns:MovePriorityMember(unit, body.selectedGroupKey, key, delta)
		ResyncPriorityPages()
	end, function(key)
		ns:RemovePriorityMember(unit, body.selectedGroupKey, key)
		body.pendingElement = nil
		ResyncPriorityPages()
		RefreshAll()
	end)
	body.list:SetPoint("TOP", members, "BOTTOM", 0, -PAGE_GAP)

	function body:Resync()
		if not PriorityGroupLabel(body.selectedGroupKey) then
			body.selectedGroupKey = (ns:GetPriorityGroups()[1] or EMPTY).key
		end

		body.strip:SetEntries(ns:GetPriorityGroups(), body.selectedGroupKey)
		Layout()
	end

	body.refreshers[#body.refreshers + 1] = function()
		local editable = unit == ALL_KEY or not ns:IsElementLinked(unit, PRIORITY_SECTION)

		for _, entry in ipairs(members.controls) do
			SetRowEnabled(entry, editable)
		end

		addButton:SetEnabled(editable and body.pendingElement ~= nil)
		body.list:SetEnabled(editable)

		for _, refresh in ipairs(links.refreshers) do
			refresh()
		end

		for _, refresh in ipairs(members.refreshers) do
			refresh()
		end
	end

	body.strip:SetEntries(groups, body.selectedGroupKey)
	Layout()
end

local function CreatePage(parent)
	local container = CreateFrame("Frame", nil, parent)
	container:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -PAGE_GAP)
	container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	container:Hide()

	local scroll = CreateFrame("ScrollFrame", nil, container)
	scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -SCROLL_BAR_INSET, 0)
	scroll:EnableMouseWheel(true)

	local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", SCROLL_BAR_GAP, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", SCROLL_BAR_GAP, 0)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	content.refreshers = {}
	content.controls = {}
	content.contentHeight = 0
	scroll:SetScrollChild(content)

	scroll:SetScript("OnSizeChanged", function(_, width)
		content:SetWidth(width)
	end)

	ScrollUtil.InitScrollFrameWithScrollBar(scroll, scrollBar)
	GateMouseWheel(scroll)

	container.content = content
	container.scroll = scroll
	container.scrollBar = scrollBar
	content.container = container

	return container
end

local function ShowPage(unit, section, build)
	local pageKey = unit .. "/" .. section
	local page = pages[pageKey]

	if not page then
		page = CreatePage(content)
		pages[pageKey] = page
	end

	if not page.built then
		page.built = true
		page.content.page = page
		build(page.content)
		page.content:SetHeight(page.content.contentHeight)
	end

	for _, other in next, pages do
		other:SetShown(other == page)
	end

	RefreshPage(page)
	UpdateScrollBar(page.scroll, page.scrollBar, page.content)
end

local function SelectSection(index)
	local unit = UNITS[unitIndex]
	local element = buttons[index].element

	selectedElement = element

	for position, button in ipairs(buttons) do
		button:SetSelected(position == index)
	end

	RefreshPreviewButton()

	header.Title:SetText(buttons[index].Label:GetText())

	if unit.key == ALL_KEY and not element then
		ShowPage(unit.key, FRAME_SECTION, BuildGeneralPage)
	elseif not element then
		ShowPage(unit.key, FRAME_SECTION, function(body)
			BuildFramePage(body, unit.key)
		end)
	elseif element.custom then
		ShowPage(unit.key, element.key, function(body)
			BuildCustomTextPage(body, unit.key)
		end)
	elseif element.prediction then
		ShowPage(unit.key, element.key, function(body)
			BuildPredictionPage(body, unit.key)
		end)
	elseif element.priority then
		ShowPage(unit.key, element.key, function(body)
			BuildPriorityPage(body, unit.key)
		end)
	else
		ShowPage(unit.key, element.key, function(body)
			BuildElementPage(body, unit.key, element)
		end)
	end
end

local function GetListButton(index)
	local button = buttons[index]

	if not button then
		button = ns:CreateCategoryButton(list, "", function()
			SelectSection(index)
		end)
		buttons[index] = button
	end

	return button
end

local function ListLabel(unit, entry)
	if entry.element and unit ~= ALL_KEY and ns:IsElementLinked(unit, entry.element.key) then
		return entry.label .. LINKED_MARKER
	end

	return entry.label
end

function RefreshListLabels()
	local unit = UNITS[unitIndex].key

	for _, button in ipairs(buttons) do
		if button:IsShown() then
			button.Label:SetText(ListLabel(unit, button.entry))
		end
	end
end

local function BuildList()
	local unit = UNITS[unitIndex]
	local entries = {}

	if unit.key == ALL_KEY then
		entries[1] = { label = GENERAL_LABEL }

		for _, info in ipairs(ELEMENTS) do
			entries[#entries + 1] = { label = info.label, element = info }
		end
	else
		entries[1] = { label = "Frame" }

		for _, info in ipairs(ELEMENTS) do
			if ns:HasElement(unit.key, info.key) then
				entries[#entries + 1] = { label = info.label, element = info }
			end
		end
	end

	local previous, button

	for index, entry in ipairs(entries) do
		button = GetListButton(index)
		button.entry = entry
		button.Label:SetText(ListLabel(unit.key, entry))
		button.element = entry.element
		button:ClearAllPoints()

		if previous then
			ns:SetPoint(button, "TOPLEFT", previous, "BOTTOMLEFT", 0, -LIST_SPACING)
		else
			ns:SetPoint(button, "TOPLEFT", list, "TOPLEFT", 0, 0)
		end

		button:Show()
		previous = button
	end

	for index = #entries + 1, #buttons do
		buttons[index]:Hide()
	end

	local height = #entries * button:GetHeight() + (#entries - 1) * LIST_SPACING

	ns:SetHeight(list, math.max(height, LIST_HEIGHT))
	UpdateScrollBar(listScroll, listScrollBar, list)

	SelectSection(1)
end

local function ApplyChanges(needsReload)
	ns:ApplyMedia()
	ns:ApplyHealthColorMode()
	ns:ApplyPowerColorMode()
	ns:ApplyElementColors()
	ns:UpdatePower()
	ns:UpdateElements()
	ns:UpdateTags()
	ns:DeferMethod(ns, "UpdatePixelGeometry")
	ns:DeferMethod(ns, "UpdatePositions")

	RefreshAll()

	if needsReload then
		StaticPopup_Show(RELOAD_POPUP)
	end
end

local function ResetGeneral()
	local db = ns.db

	db.texture = nil
	db.font = nil
	db.fontSize = nil
	db.iconSize = nil
	db.sync = nil
	db.questIcon = nil
	db.roleIcon = nil
	db.pvpIcon = nil
	db.healthColorMode = nil
	db.healthCustomColor = nil
	db.powerColorMode = nil
end

local RESYNC_SECTIONS = { CUSTOM_TEXT_SECTION, PRIORITY_SECTION }

local function ResetAll()
	local needsReload

	for _, info in ipairs(UNITS) do
		if info.key ~= "general" and not ns:IsUnitEnabled(info.key) then
			needsReload = true
		end
	end

	ResetGeneral()
	ns:ResetCustomTextElements()
	ns.db.units = nil
	ns:ResetPriorityGroups()

	local page

	for _, info in ipairs(UNITS) do
		for _, section in ipairs(RESYNC_SECTIONS) do
			page = pages[info.key .. "/" .. section]

			if page and page.built then
				page.content:Resync()
			end
		end
	end

	ApplyChanges(needsReload)
end

local function SelectedTextKey(unit)
	local page = pages[unit.key .. "/" .. CUSTOM_TEXT_SECTION]
	return page and page.content.selectedTextKey
end

local function ResetPage()
	local unit = UNITS[unitIndex]
	local storageUnit = unit.key
	local needsReload
	local db = ns.db
	local elementKey = selectedElement and selectedElement.key

	if selectedElement and selectedElement.custom then
		elementKey = SelectedTextKey(unit) or elementKey
	end

	if selectedElement then
		storageUnit = StorageUnit(unit.key, elementKey)
	end

	local stored = db.units and db.units[storageUnit]

	if selectedElement then
		local keys = { elementKey }

		for _, extra in ipairs(selectedElement.extra or EMPTY) do
			keys[#keys + 1] = extra
		end

		for _, group in ipairs(ns.ELEMENT_GROUPS) do
			if stored and stored[group] then
				for _, key in ipairs(keys) do
					stored[group][key] = nil
				end
			end
		end

		if elementKey == "quest" then
			db.questIcon = nil
		elseif elementKey == "grouprole" then
			db.roleIcon = nil
		elseif elementKey == "pvp" then
			db.pvpIcon = nil
		elseif elementKey == PRIORITY_SECTION then
			if stored then
				stored.groups = nil
			end

			ns:ResetPriorityMembers(storageUnit)

			local page = pages[unit.key .. "/" .. PRIORITY_SECTION]

			if page and page.built then
				page.content:Resync()
			end
		end
	elseif unit.key == ALL_KEY then
		ResetGeneral()
	elseif stored then
		needsReload = not ns:IsUnitEnabled(unit.key)

		for _, field in ipairs(FRAME_FIELDS) do
			stored[field] = nil
		end
	end

	ApplyChanges(needsReload)
end

StaticPopupDialogs[RELOAD_POPUP] = {
	text = "oUF_Mania needs the interface reloaded to apply that.",
	button1 = RELOADUI or "Reload UI",
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs[DEFAULTS_POPUP] = {
	text = "Do you want to reset all oUF_Mania settings to their defaults, or only the settings for this category?",
	button1 = ALL_SETTINGS or "All Settings",
	button2 = CANCEL,
	button3 = CURRENT_SETTINGS or "These Settings",
	OnAccept = ResetAll,
	OnAlt = ResetPage,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs[DELETE_PRIORITY_GROUP_POPUP] = {
	text = "Delete %s?",
	button1 = DELETE or "Delete",
	button2 = CANCEL,
	OnAccept = function(self)
		self.data()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs[DELETE_CUSTOM_TEXT_POPUP] = {
	text = "Delete %s?",
	button1 = DELETE or "Delete",
	button2 = CANCEL,
	OnAccept = function(self)
		self.data()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local function BuildWindow()
	local frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "DefaultPanelFlatTemplate")
	ns:SetSize(frame, WINDOW_WIDTH, WINDOW_HEIGHT)
	ns:SetPoint(frame, "CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetTitle("oUF_Mania")
	frame:Hide()

	window = frame

	frame:HookScript("OnShow", function(self)
		ns:SnapToPixelGrid(self)
	end)

	frame:HookScript("OnHide", function()
		ns:StopAllElementPreviews()
		ns:StopAllGroupPreviews()
	end)

	ns:SetFrameMoveable(frame)

	local titleClose = CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")

	local inner = ns:CreateTabContainer(frame, INNER_HEIGHT)
	inner:SetPoint("TOPLEFT", frame, "TOPLEFT", INNER_X, -INNER_Y)

	local labels = {}

	for index, info in ipairs(UNITS) do
		labels[index] = info.label
	end

	local tabs = ns:CreateTabSystem(frame, labels, function(index)
		unitIndex = index
		BuildList()
	end)
	tabs:SetPoint("TOPLEFT", frame, "TOPLEFT", TAB_X, -TAB_Y)

	listScroll = CreateFrame("ScrollFrame", nil, frame)
	ns:SetSize(listScroll, LIST_WIDTH, LIST_HEIGHT)
	ns:SetPoint(listScroll, "TOPLEFT", frame, "TOPLEFT", LIST_X, -LIST_Y)
	listScroll:EnableMouseWheel(true)

	listScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
	listScrollBar:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", -LIST_BAR_INSET, 0)
	listScrollBar:SetPoint("BOTTOMLEFT", listScroll, "BOTTOMRIGHT", -LIST_BAR_INSET, 0)

	list = CreateFrame("Frame", nil, listScroll)
	ns:SetSize(list, LIST_WIDTH, LIST_HEIGHT)
	listScroll:SetScrollChild(list)

	ScrollUtil.InitScrollFrameWithScrollBar(listScroll, listScrollBar)
	GateMouseWheel(listScroll)

	content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", CONTENT_GAP, 0)
	content:SetPoint("BOTTOMLEFT", listScroll, "BOTTOMRIGHT", CONTENT_GAP, 0)
	content:SetPoint("RIGHT", frame, "RIGHT", CONTENT_RIGHT, 0)

	header = ns:CreateSettingsHeader(content)

	local defaults = header.DefaultsButton
	defaults:Show()
	defaults:SetScript("OnClick", function()
		StaticPopup_Show(DEFAULTS_POPUP)
	end)

	previewButton = ns:CreateButton(header, PREVIEW_SHOW, TogglePreview)
	previewButton:SetSize(PREVIEW_WIDTH, BUTTON_HEIGHT)
	previewButton:SetPoint("RIGHT", defaults, "LEFT", -HEADER_BUTTON_GAP, 0)

	table.insert(UISpecialFrames, WINDOW_NAME)

	tabs:SelectTab(1)

	return frame
end

function ns:OpenOptionsWindow()
	window = window or BuildWindow()
	window:Show()
	window:Raise()
end

ns:RegisterSettings("oUF_ManiaDB", {
	{
		type = "description",
		title = "oUF_Mania is configured from its own window.",
	},
	{
		type = "custom",
		title = "Options",
		tooltip = "Opens the oUF_Mania options window.",
		createControl = function(rowFrame)
			local button = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
			button:SetSize(LAUNCH_WIDTH, BUTTON_HEIGHT)
			button:SetText("Open oUF_Mania options")
			button:SetScript("OnClick", function()
				local skipTransitionBackToOpeningPanel = true
				SettingsPanel:Close(skipTransitionBackToOpeningPanel)
				ns:OpenOptionsWindow()
			end)

			return button
		end,
	},
})

ns:RegisterSlash("/oufmania", function()
	ns:OpenOptionsWindow()
end)
