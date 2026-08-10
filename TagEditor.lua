local _, ns = ...

local WINDOW_NAME = "ManiaUFTagEditorFrame"
local WINDOW_WIDTH = 600

local INNER_X, INNER_Y = 20, 48
local INNER_RIGHT, INNER_BOTTOM = 20, 20

local EDITBOX_HEIGHT = 90
local EDITBOX_INSET = 18

local PREVIEW_HEIGHT = 20
local PREVIEW_GAP = 10
local EMPTY_PREVIEW = "-"

local BUTTON_WIDTH = 90
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 8
local BUTTON_ROW_GAP = 10
local LIST_TOGGLE_WIDTH = 130
local SHOW_LIST_TEXT = "Show Tag List"
local HIDE_LIST_TEXT = "Hide Tag List"

local LIST_GAP = 12
local LIST_AREA_HEIGHT = 260
local LIST_TAG_WIDTH = 200
local LIST_ROW_HEIGHT = 18
local LIST_ROW_SPACING = 2
local HEADER_ROW_HEIGHT = 26

local SCROLL_BAR_INSET = 22
local SCROLL_BAR_GAP = 8

local TITLE_PREFIX = "Edit Tag - "

local COLLAPSED_HEIGHT = INNER_Y + EDITBOX_HEIGHT + PREVIEW_GAP + PREVIEW_HEIGHT
	+ BUTTON_ROW_GAP + BUTTON_HEIGHT + INNER_BOTTOM
local EXPANDED_HEIGHT = COLLAPSED_HEIGHT + LIST_GAP + LIST_AREA_HEIGHT

local SAMPLE_ICON_SIZE = 16
local RAID_MARKER_SHEET = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local RESTING_SHEET = [[Interface\CharacterFrame\UI-StateIcon]]

local function Icon(atlas)
	return CreateAtlasMarkup(atlas, SAMPLE_ICON_SIZE, SAMPLE_ICON_SIZE)
end

local RAID_MARKER_SAMPLE = ("|T%s:%d:%d:0:0:256:256:0:64:0:64|t"):format(
	RAID_MARKER_SHEET, SAMPLE_ICON_SIZE, SAMPLE_ICON_SIZE)
local RESTING_SAMPLE = ("|T%s:%d:%d:0:0:64:64:0:32:0:27|t"):format(
	RESTING_SHEET, SAMPLE_ICON_SIZE, SAMPLE_ICON_SIZE)

local ICON_TAGS = {
	{ tag = "[maniauf:leader]", text = "Group leader crown",
		sample = Icon("UI-HUD-UnitFrame-Player-Group-LeaderIcon") },
	{ tag = "[maniauf:assistant]", text = "Raid assistant",
		sample = Icon("UI-HUD-UnitFrame-Player-Group-GuideIcon") },
	{ tag = "[maniauf:role]", text = "Assigned role",
		sample = Icon("UI-LFG-RoleIcon-Tank-Micro-Raid") },
	{ tag = "[maniauf:raidtarget]", text = "Raid target marker", sample = RAID_MARKER_SAMPLE },
	{ tag = "[maniauf:combat]", text = "In combat",
		sample = Icon("UI-HUD-UnitFrame-Player-CombatIcon") },
	{ tag = "[maniauf:resting]", text = "Resting (player only)", sample = RESTING_SAMPLE },
	{ tag = "[maniauf:pvp]", text = "PvP flagged", sample = Icon("questlog-questtypeicon-alliance") },
	{ tag = "[maniauf:quest]", text = "Quest objective", sample = Icon("questlog-questtypeicon-quest") },
	{ tag = "[maniauf:phase]", text = "Phased", sample = Icon("RaidFrame-Icon-Phasing") },
	{ tag = "[maniauf:resurrect]", text = "Incoming resurrect", sample = Icon("RaidFrame-Icon-Rez") },
	{ tag = "[maniauf:summon]", text = "Incoming summon", sample = Icon("RaidFrame-Icon-SummonPending") },
}

local NUMBER_TAGS = {
	{ tag = "[maniauf:curhp]", text = "Current health, abbreviated (57.2k)", sample = "57.2k" },
	{ tag = "[maniauf:maxhp]", text = "Maximum health, abbreviated", sample = "58.0k" },
	{ tag = "[maniauf:curpp]", text = "Current power, abbreviated", sample = "850" },
	{ tag = "[maniauf:maxpp]", text = "Maximum power, abbreviated", sample = "1.0k" },
}

local GENERAL_TAGS = {
	{ tag = "[affix]", text = "\"Affix\" if the unit carries the minus classification",
		sample = "Affix" },
	{ tag = "[arcanecharges]", text = "Current arcane charges (Arcane mage, if any)", sample = "4" },
	{ tag = "[arenaspec]", text = "Opponent's spec name, during arena prep", sample = "Fire Mage" },
	{ tag = "[chi]", text = "Current chi (Windwalker monk, if any)", sample = "3" },
	{ tag = "[class]", text = "Class name", sample = "Warrior" },
	{ tag = "[classification]", text = "Rare / Rare Elite / Elite / Boss / Affix",
		sample = "Rare Elite" },
	{ tag = "[cpoints]", text = "Combo points (if any)", sample = "5" },
	{ tag = "[creature]", text = "Creature family or type", sample = "Beast" },
	{ tag = "[curhp]", text = "Current health, raw number", sample = "57200" },
	{ tag = "[curmana]", text = "Current mana", sample = "8500" },
	{ tag = "[curpp]", text = "Current power, raw number", sample = "850" },
	{ tag = "[dead]", text = "\"Dead\" or \"Ghost\"", sample = "Dead" },
	{ tag = "[difficulty]", text = "Color prefix: enemy level difficulty",
		sample = "|cffff2020Example|r" },
	{ tag = "[faction]", text = "Alliance or Horde", sample = "Alliance" },
	{ tag = "[group]", text = "Raid subgroup number", sample = "3" },
	{ tag = "[holypower]", text = "Current holy power (Retribution paladin, if any)", sample = "3" },
	{ tag = "[leader]", text = "\"L\" if group leader", sample = "L" },
	{ tag = "[leaderlong]", text = "\"Leader\" if group leader", sample = "Leader" },
	{ tag = "[level]", text = "Unit level", sample = "70" },
	{ tag = "[maxhp]", text = "Maximum health", sample = "58000" },
	{ tag = "[maxmana]", text = "Maximum mana", sample = "10000" },
	{ tag = "[maxpp]", text = "Maximum power", sample = "1000" },
	{ tag = "[missinghp]", text = "Health missing, blank if full", sample = "800" },
	{ tag = "[missingpp]", text = "Power missing, blank if full", sample = "150" },
	{ tag = "[name]", text = "Unit name", sample = "Thrall" },
	{ tag = "[offline]", text = "\"Offline\" if disconnected", sample = "Offline" },
	{ tag = "[perhp]", text = "Health percent, no % sign", sample = "76" },
	{ tag = "[perpp]", text = "Power percent, no % sign", sample = "85" },
	{ tag = "[plus]", text = "\"+\" if elite or rare elite", sample = "+" },
	{ tag = "[powercolor]", text = "Color prefix: current power type",
		sample = "|cff0070ddExample|r" },
	{ tag = "[pvp]", text = "\"PvP\" if flagged", sample = "PvP" },
	{ tag = "[race]", text = "Race name", sample = "Orc" },
	{ tag = "[raidcolor]", text = "Color prefix: class color", sample = "|cffc79c6eExample|r" },
	{ tag = "[rare]", text = "\"Rare\" if rare or rare elite", sample = "Rare" },
	{ tag = "[resting]", text = "\"zzz\" if the player is resting", sample = "zzz" },
	{ tag = "[runes]", text = "Ready Death Knight runes", sample = "4" },
	{ tag = "[sex]", text = "\"Male\" or \"Female\"", sample = "Male" },
	{ tag = "[shortclassification]", text = "Abbreviated classification (R, R+, +, B, -)",
		sample = "R+" },
	{ tag = "[smartclass]", text = "Creature type for NPCs, class for players", sample = "Beast" },
	{ tag = "[smartlevel]", text = "Level, \"Boss\", or level with a \"+\"", sample = "70+" },
	{ tag = "[soulshards]", text = "Current soul shards (Warlock, if any)", sample = "3" },
	{ tag = "[status]", text = "Dead / Ghost / Offline / resting, combined", sample = "Dead" },
	{ tag = "[threat]", text = "\"++\" / \"--\" / \"Aggro\"", sample = "Aggro" },
	{ tag = "[threatcolor]", text = "Color prefix: threat situation", sample = "|cffff2020Example|r" },
}

local TAG_GROUPS = {
	{ title = "ManiaUF icons", tags = ICON_TAGS },
	{ title = "ManiaUF numbers", tags = NUMBER_TAGS },
	{ title = "General", tags = GENERAL_TAGS },
}

local SAMPLE_LOOKUP = {}

for _, group in ipairs(TAG_GROUPS) do
	for _, info in ipairs(group.tags) do
		SAMPLE_LOOKUP[info.tag:sub(2, -2)] = info.sample
	end
end

local BRACKET_PATTERN = "%[([^%[%]]+)%]"

local function RenderTag(tagString)
	if not tagString or tagString == "" then
		return nil
	end

	return (tagString:gsub(BRACKET_PATTERN, function(name)
		return SAMPLE_LOOKUP[name] or ("[" .. name .. "]")
	end))
end

local window
local editBox
local previewText
local currentSetValue

local function RefreshEditBoxPreview()
	previewText:SetText(RenderTag(editBox:GetText()) or EMPTY_PREVIEW)
end

local function CloseEditor()
	window:Hide()
end

local function CommitAndClose()
	if currentSetValue then
		currentSetValue(editBox:GetText())
	end

	ns:RefreshOptionsWindow()
	CloseEditor()
end

local function InsertTag(tag)
	editBox:SetText((editBox:GetText() or "") .. tag)
	editBox:SetFocus()
	editBox:SetCursorPosition(#editBox:GetText())
end

local function CreateHeaderRow(parent, previous, title)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(HEADER_ROW_HEIGHT)
	row:SetPoint("LEFT", parent, "LEFT", 0, 0)
	row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

	if previous then
		row:SetPoint("TOP", previous, "BOTTOM", 0, -LIST_ROW_SPACING)
	else
		row:SetPoint("TOP", parent, "TOP", 0, 0)
	end

	local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	label:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
	label:SetText(title)

	return row
end

local function CreateReferenceRow(parent, previous, info)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(LIST_ROW_HEIGHT)
	row:SetPoint("LEFT", parent, "LEFT", 0, 0)
	row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

	if previous then
		row:SetPoint("TOP", previous, "BOTTOM", 0, -LIST_ROW_SPACING)
	else
		row:SetPoint("TOP", parent, "TOP", 0, 0)
	end

	row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")
	row:SetScript("OnClick", function()
		InsertTag(info.tag)
	end)
	row:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(info.tag, 1, 1, 1)
		GameTooltip:AddLine(info.text, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)

	local tagText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tagText:SetPoint("LEFT", row, "LEFT", 4, 0)
	tagText:SetJustifyH("LEFT")
	tagText:SetWordWrap(false)
	tagText:SetText(info.tag)

	local preview = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	preview:SetPoint("LEFT", row, "LEFT", LIST_TAG_WIDTH, 0)
	preview:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	preview:SetJustifyH("LEFT")
	preview:SetWordWrap(false)
	preview:SetText(info.sample or EMPTY_PREVIEW)

	return row
end

local function BuildReferenceList(content)
	local row
	local height = 0

	for _, group in ipairs(TAG_GROUPS) do
		row = CreateHeaderRow(content, row, group.title)
		height = height + row:GetHeight() + LIST_ROW_SPACING

		for _, info in ipairs(group.tags) do
			row = CreateReferenceRow(content, row, info)
			height = height + row:GetHeight() + LIST_ROW_SPACING
		end
	end

	content:SetHeight(height)
end

local function BuildWindow()
	local frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "DefaultPanelFlatTemplate")
	frame:SetSize(WINDOW_WIDTH, COLLAPSED_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:Hide()

	window = frame

	ns:SetFrameMoveable(frame)

	local function SetWindowHeight(newHeight)
		local top = frame:GetTop()

		frame:SetHeight(newHeight)

		if top then
			frame:AdjustPointsOffset(0, top - frame:GetTop())
		end
	end

	CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")

	local editBoxScroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
	editBoxScroll:SetSize(WINDOW_WIDTH - INNER_X - INNER_RIGHT, EDITBOX_HEIGHT)
	editBoxScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", INNER_X, -INNER_Y)
	editBoxScroll.CharCount:Hide()

	editBox = editBoxScroll.EditBox
	editBox:SetWidth(editBoxScroll:GetWidth() - EDITBOX_INSET)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetScript("OnEscapePressed", CloseEditor)
	editBox:HookScript("OnTextChanged", RefreshEditBoxPreview)

	previewText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	previewText:SetHeight(PREVIEW_HEIGHT)
	previewText:SetPoint("TOPLEFT", editBoxScroll, "BOTTOMLEFT", 4, -PREVIEW_GAP)
	previewText:SetPoint("RIGHT", editBoxScroll, "RIGHT", 0, 0)
	previewText:SetJustifyH("LEFT")
	previewText:SetWordWrap(false)

	local scroll, scrollBar, listToggle

	local function ToggleReferenceList()
		local shown = not scroll:IsShown()

		scroll:SetShown(shown)
		scrollBar:SetShown(shown)
		listToggle:SetText(shown and HIDE_LIST_TEXT or SHOW_LIST_TEXT)
		SetWindowHeight(shown and EXPANDED_HEIGHT or COLLAPSED_HEIGHT)
	end

	listToggle = ns:CreateButton(frame, SHOW_LIST_TEXT, ToggleReferenceList)
	listToggle:SetSize(LIST_TOGGLE_WIDTH, BUTTON_HEIGHT)
	listToggle:SetPoint("TOPLEFT", previewText, "BOTTOMLEFT", 0, -BUTTON_ROW_GAP)

	local cancel = ns:CreateButton(frame, "Cancel", CloseEditor)
	cancel:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	cancel:SetPoint("TOPRIGHT", previewText, "BOTTOMRIGHT", 0, -BUTTON_ROW_GAP)

	local ok = ns:CreateButton(frame, "OK", CommitAndClose)
	ok:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	ok:SetPoint("RIGHT", cancel, "LEFT", -BUTTON_GAP, 0)

	scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOP", listToggle, "BOTTOM", 0, -LIST_GAP)
	scroll:SetPoint("LEFT", frame, "LEFT", INNER_X, 0)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
		-(INNER_RIGHT + SCROLL_BAR_INSET), INNER_BOTTOM)
	scroll:EnableMouseWheel(true)
	scroll:Hide()

	scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", SCROLL_BAR_GAP, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", SCROLL_BAR_GAP, 0)
	scrollBar:Hide()

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)

	scroll:SetScript("OnSizeChanged", function(_, width)
		content:SetWidth(width)
	end)

	ScrollUtil.InitScrollFrameWithScrollBar(scroll, scrollBar)

	BuildReferenceList(content)

	table.insert(UISpecialFrames, WINDOW_NAME)

	return frame
end

function ns:OpenTagEditor(label, getValue, setValue)
	window = window or BuildWindow()

	currentSetValue = setValue

	window:SetTitle(TITLE_PREFIX .. label)
	editBox:SetText((getValue and getValue()) or "")
	editBox:SetCursorPosition(0)
	RefreshEditBoxPreview()

	window:Show()
	window:Raise()
end
