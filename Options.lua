local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local WINDOW_NAME = "ManiaUFOptionsFrame"
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
local LIST_ROW_HEIGHT = 20
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
local POSITION_MIN, POSITION_MAX = -1000, 1000
local SIZE_MIN, SIZE_MAX = 0, 64
local TEXT_WIDTH_MIN, TEXT_WIDTH_MAX = 0, 300
local CASTBAR_WIDTH_MIN, CASTBAR_WIDTH_MAX = 0, 400

local SCROLL_BAR_INSET = 22
local SCROLL_BAR_GAP = 8

local SLIDER_WIDTH = 250
local SLIDER_INPUT_OFFSET = 25
local TAG_INPUT_OFFSET = 8
local TAG_BUTTON_OFFSET = 8
local TAG_INPUT_WIDTH = SLIDER_WIDTH + SLIDER_INPUT_OFFSET - TAG_INPUT_OFFSET - TAG_BUTTON_OFFSET

local PREVIEW_SHOW = "Preview"
local PREVIEW_ALL = "Preview all"
local PREVIEW_GROUP = "Preview group"
local PREVIEW_HIDE = "Stop preview"
local PREVIEW_WIDTH = 110
local HEADER_BUTTON_GAP = 6

local RELOAD_POPUP = "MANIAUF_RELOAD"
local DEFAULTS_POPUP = "MANIAUF_DEFAULTS"
local FRAME_SECTION = "frame"

local FRAME_FIELDS = {
	"enabled", "width", "height", "power", "showPower", "posX", "posY",
	"spacing", "vertical", "showPlayer", "healerPower",
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

local ELEMENTS = {
	{ key = "name", label = "Name text", tag = true },
	{ key = "health", label = "Health text", tag = true },
	{ key = "custom1", label = "Custom text 1", tag = true },
	{ key = "custom2", label = "Custom text 2", tag = true },
	{ key = "castbar", label = "Cast bar", extra = { "castbarIcon", "castbarLatency", "castbarWidth" } },
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
}

local LINK_COLUMNS = 4
local LINK_COLUMN_WIDTH = 150
local LINK_LINE_HEIGHT = 26
local LINK_BUTTON_WIDTH = 60
local LINK_BUTTON_GAP = 6
local LINK_LABEL_Y = 6
local LINK_LABEL_HEIGHT = 12
local LINK_INSET = 30
local LINK_LABEL_WIDTH = 110
local LINK_BUTTON_RIGHT = 14
local LINK_DIVIDER_GAP = 10
local DIVIDER_PIXELS = 1

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

local function CreateRow(body, previous, label, height)
	local row = CreateFrame("Frame", nil, body)
	height = height or ROW_HEIGHT
	body.contentHeight = body.contentHeight + height + ROW_SPACING
	row:SetHeight(height)
	row:SetPoint("LEFT", body, "LEFT", 0, 0)
	row:SetPoint("RIGHT", body, "RIGHT", 0, 0)

	if previous then
		row:SetPoint("TOP", previous, "BOTTOM", 0, -ROW_SPACING)
	else
		row:SetPoint("TOP", body, "TOP", 0, 0)
	end

	local text = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("LEFT", row, "LEFT", LABEL_INSET, 0)
	text:SetPoint("RIGHT", row, "LEFT", CONTROL_COLUMN - LABEL_GAP, 0)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	text:SetText(label)
	row.Label = text

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
			return ManiaUFDB[field] or LSM:GetDefault(mediaType)
		end, function(name)
			ManiaUFDB[field] = name
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
		ManiaUFDB.fontSize = value
		ns:ApplyMedia()
	end)

	row = AddSliderRow(body, row, "Icon tag size", ICON_SIZE_MIN, ICON_SIZE_MAX, function()
		return ns:GetIconTagSize()
	end, function(value)
		ns:SetIconTagSize(value)
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
			return select(index, ns:GetUnitSizes(unit))
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
	local lines = math.ceil(#units / LINK_COLUMNS)
	local row = CreateRow(body, previous, "Units using these settings",
		(lines + 1) * LINK_LINE_HEIGHT + 2 * LINK_DIVIDER_GAP)

	row.Label:ClearAllPoints()
	row.Label:SetPoint("TOPLEFT", row, "TOPLEFT", LABEL_INSET, -LINK_LABEL_Y)

	local divider = row:CreateTexture(nil, "ARTWORK")
	divider:SetAtlas("Options_HorizontalDivider")
	ns:SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", LABEL_INSET, LINK_DIVIDER_GAP)
	ns:SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", -LINK_BUTTON_RIGHT, LINK_DIVIDER_GAP)

	body.refreshers[#body.refreshers + 1] = function()
		ns:SetHeight(divider, ns:PixelSize(divider, DIVIDER_PIXELS))
	end

	local toggles = {}
	local toggle, column, line

	for index, key in ipairs(units) do
		column = (index - 1) % LINK_COLUMNS
		line = math.floor((index - 1) / LINK_COLUMNS)

		toggle = ns:CreateToggle(row, UNIT_LABELS[key], function()
			return ns:IsElementLinked(key, element)
		end, function(value)
			ns:SetElementLinked(key, element, value)
			RefreshAll()
		end)
		toggle:SetPoint("TOPLEFT", row, "TOPLEFT",
			LINK_INSET + LINK_LABEL_WIDTH + column * LINK_COLUMN_WIDTH,
			-(line + 1) * LINK_LINE_HEIGHT)

		toggles[index] = toggle
	end

	local function SetAll(linked)
		for _, key in ipairs(units) do
			ns:SetElementLinked(key, element, linked)
		end

		RefreshAll()
	end

	local none = ns:CreateButton(row, "None", function()
		SetAll(false)
	end)
	none:SetSize(LINK_BUTTON_WIDTH, BUTTON_HEIGHT)
	none:SetPoint("RIGHT", row, "TOPRIGHT", -LINK_BUTTON_RIGHT,
		-(LINK_LABEL_Y + LINK_LABEL_HEIGHT / 2))

	local all = ns:CreateButton(row, "All", function()
		SetAll(true)
	end)
	all:SetSize(LINK_BUTTON_WIDTH, BUTTON_HEIGHT)
	all:SetPoint("RIGHT", none, "LEFT", -LINK_BUTTON_GAP, 0)

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

	if ns:HasElementLevel(info.key) then
		local minLevel, maxLevel = ns:GetElementLevelRange()

		row = AddSliderRow(body, row, "Frame level", minLevel, maxLevel, function()
			return ns:GetElementLevel(storageUnit, info.key)
		end, function(value)
			ns:SetElementLevel(storageUnit, info.key, value)
		end)
	end

	row = AddAxisRows(body, row, "Offset", OFFSET_MIN, OFFSET_MAX, function()
		return ns:GetElementOffset(storageUnit, info.key)
	end, function(axis, value)
		ns:SetElementOffset(storageUnit, info.key, axis, value)
	end)

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

		row = AddSliderRow(body, row, "Width (0 = match frame)", CASTBAR_WIDTH_MIN,
			CASTBAR_WIDTH_MAX, function()
				return ns:GetElementSize(storageUnit, "castbarWidth")
			end, function(value)
				ns:SetElementSize(storageUnit, "castbarWidth", value)
			end)

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

	if info.key ~= "castbar" and ns:HasElementSize(info.key) then
		row = AddSliderRow(body, row, "Size", SIZE_MIN, SIZE_MAX, function()
			return ns:GetElementSize(storageUnit, info.key)
		end, function(value)
			ns:SetElementSize(storageUnit, info.key, value)
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

	container.content = content
	container.scroll = scroll
	container.scrollBar = scrollBar

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
		build(page.content)
		page.content:SetHeight(page.content.contentHeight)
	end

	for _, other in next, pages do
		other:SetShown(other == page)
	end

	RefreshPage(page)
	page.scrollBar:SetShown(page.content:GetHeight() > page.scroll:GetHeight() + 1)
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
			button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -LIST_SPACING)
		else
			button:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
		end

		button:Show()
		previous = button
	end

	for index = #entries + 1, #buttons do
		buttons[index]:Hide()
	end

	local height = #entries * (LIST_ROW_HEIGHT + LIST_SPACING)

	list:SetHeight(math.max(height, LIST_HEIGHT))
	listScrollBar:SetShown(height > LIST_HEIGHT)

	SelectSection(1)
end

local function ApplyChanges(needsReload)
	ns:ApplyMedia()
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
	ManiaUFDB.texture = nil
	ManiaUFDB.font = nil
	ManiaUFDB.fontSize = nil
	ManiaUFDB.iconSize = nil
	ManiaUFDB.sync = nil
	ManiaUFDB.questIcon = nil
	ManiaUFDB.roleIcon = nil
end

local function ResetAll()
	local needsReload

	for _, info in ipairs(UNITS) do
		if info.key ~= "general" and not ns:IsUnitEnabled(info.key) then
			needsReload = true
		end
	end

	ResetGeneral()
	ManiaUFDB.units = nil

	ApplyChanges(needsReload)
end

local function ResetPage()
	local unit = UNITS[unitIndex]
	local storageUnit = unit.key
	local needsReload

	if selectedElement then
		storageUnit = StorageUnit(unit.key, selectedElement.key)
	end

	local stored = ManiaUFDB.units and ManiaUFDB.units[storageUnit]

	if selectedElement then
		local keys = { selectedElement.key }

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

		if selectedElement.key == "quest" then
			ManiaUFDB.questIcon = nil
		elseif selectedElement.key == "grouprole" then
			ManiaUFDB.roleIcon = nil
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
	text = "ManiaUF needs the interface reloaded to apply that.",
	button1 = RELOADUI or "Reload UI",
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs[DEFAULTS_POPUP] = {
	text = "Do you want to reset all ManiaUF settings to their defaults, or only the settings for this category?",
	button1 = ALL_SETTINGS or "All Settings",
	button2 = CANCEL,
	button3 = CURRENT_SETTINGS or "These Settings",
	OnAccept = ResetAll,
	OnAlt = ResetPage,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local function BuildWindow()
	local frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "DefaultPanelFlatTemplate")
	frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetTitle("ManiaUF")
	frame:Hide()

	window = frame

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
	listScroll:SetSize(LIST_WIDTH, LIST_HEIGHT)
	listScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", LIST_X, -LIST_Y)
	listScroll:EnableMouseWheel(true)

	listScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
	listScrollBar:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", -LIST_BAR_INSET, 0)
	listScrollBar:SetPoint("BOTTOMLEFT", listScroll, "BOTTOMRIGHT", -LIST_BAR_INSET, 0)

	list = CreateFrame("Frame", nil, listScroll)
	list:SetSize(LIST_WIDTH, LIST_HEIGHT)
	listScroll:SetScrollChild(list)

	ScrollUtil.InitScrollFrameWithScrollBar(listScroll, listScrollBar)

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

ns:RegisterSettings("ManiaUFDB", {
	{
		type = "description",
		title = "ManiaUF is configured from its own window.",
	},
	{
		type = "custom",
		title = "Options",
		tooltip = "Opens the ManiaUF options window.",
		createControl = function(rowFrame)
			local button = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
			button:SetSize(LAUNCH_WIDTH, BUTTON_HEIGHT)
			button:SetText("Open ManiaUF options")
			button:SetScript("OnClick", function()
				local skipTransitionBackToOpeningPanel = true
				SettingsPanel:Close(skipTransitionBackToOpeningPanel)
				ns:OpenOptionsWindow()
			end)

			return button
		end,
	},
})

ns:RegisterSlash("/maniauf", function()
	ns:OpenOptionsWindow()
end)
