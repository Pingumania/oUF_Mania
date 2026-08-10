local _, ns = ...

ns.ALL_KEY = "all"
ns.ELEMENT_GROUPS = {
	"elements", "offsets", "anchors", "widths", "sizes", "tags", "linked", "levels",
}

local INDICATOR_SIZE = 14
local RAID_MARKER_SIZE = 20
local INDICATOR_SUBLEVEL = 2
local THREAT_PADDING = 3
local THREAT_FADE = 0.25
local THREAT_SUBLEVEL = -1
local THREAT_ATLAS = "timerunning-redbutton-backglow"

local PVP_ATLASES = {
	Alliance = "questlog-questtypeicon-alliance",
	Horde = "questlog-questtypeicon-horde",
	FFA = "UI-HUD-UnitFrame-Player-PVP-FFAIcon",
}

local function PvPPostUpdate(element, unit, status)
	local atlas = status and PVP_ATLASES[status]

	if atlas then
		element:SetAtlas(atlas, false, nil, true)
	end
end

local QUEST_ICON_STYLES = {
	{ value = "AutoQuest-Badge-Campaign", label = "Campaign badge" },
	{ value = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Quest", label = "Unit frame quest icon" },
	{ value = "QuestNormal", label = "Quest available (!)" },
}

local QUEST_ATLAS = QUEST_ICON_STYLES[1].value

function ns:GetQuestIconStyles()
	return QUEST_ICON_STYLES
end

function ns:GetQuestIconStyle()
	return ManiaUFDB.questIcon or QUEST_ATLAS
end

function ns:SetQuestIconStyle(atlas)
	ManiaUFDB.questIcon = atlas
	ns:UpdateElements()
end

function ns:ApplyQuestIcon(element)
	element:SetAtlas(ns:GetQuestIconStyle(), false, nil, true)
end

local function QuestPostUpdate(element)
	ns:ApplyQuestIcon(element)
end

local INDICATORS = {
	{ key = "leader", element = "LeaderIndicator", point = "TOPLEFT", x = 22, y = 4,
		atlas = "UI-HUD-UnitFrame-Player-Group-LeaderIcon" },
	{ key = "assistant", element = "AssistantIndicator", point = "TOPLEFT", x = 36, y = 4,
		texture = [[Interface\GroupFrame\UI-Group-AssistantIcon]] },
	{ key = "raidrole", element = "RaidRoleIndicator", point = "TOPLEFT", x = 50, y = 4,
		atlas = "RaidFrame-Icon-MainTank" },
	{ key = "raidtarget", element = "RaidTargetIndicator", point = "TOP", x = 0, y = 5,
		marker = 1 },
	{ key = "combat", element = "CombatIndicator", point = "TOPRIGHT", x = 0, y = 4,
		atlas = "UI-HUD-UnitFrame-Player-CombatIcon" },
	{ key = "phase", element = "PhaseIndicator", point = "TOPRIGHT", x = -16, y = 4,
		atlas = "RaidFrame-Icon-Phasing" },
	{ key = "grouprole", element = "GroupRoleIndicator", point = "LEFT", x = -6, y = 0,
		atlas = "UI-LFG-RoleIcon-Tank-Micro-Raid" },
	{ key = "quest", element = "QuestIndicator", point = "RIGHT", x = 6, y = 0,
		postUpdate = QuestPostUpdate },
	{ key = "pvp", element = "PvPIndicator", point = "BOTTOMLEFT", x = 0, y = -4,
		postUpdate = PvPPostUpdate, atlas = PVP_ATLASES.Alliance },
	{ key = "pvpclass", element = "PvPClassificationIndicator", point = "BOTTOMRIGHT", x = 0, y = -4,
		atlas = "nameplates-icon-flag-alliance" },
	{ key = "readycheck", element = "ReadyCheckIndicator", point = "CENTER", x = 0, y = 0,
		atlas = "UI-LFG-ReadyMark-Raid", gateUnit = "party" },
	{ key = "resurrect", element = "ResurrectIndicator", point = "CENTER", x = -18, y = 0,
		atlas = "RaidFrame-Icon-Rez" },
	{ key = "summon", element = "SummonIndicator", point = "CENTER", x = 18, y = 0,
		atlas = "RaidFrame-Icon-SummonPending" },
}

local TEXT_POINTS = { "LEFT", "CENTER", "RIGHT" }

local ANCHOR_POINTS = {
	"TOPLEFT", "TOP", "TOPRIGHT",
	"LEFT", "CENTER", "RIGHT",
	"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

local DEFAULT_ANCHORS = {}
local DEFAULT_OFFSETS = {}
local DEFAULT_ELEMENT_SIZES = {}

for _, info in ipairs(INDICATORS) do
	DEFAULT_ANCHORS[info.key] = info.point
	DEFAULT_OFFSETS[info.key] = { info.x, info.y }
	DEFAULT_ELEMENT_SIZES[info.key] = INDICATOR_SIZE
end

local PREVIEWABLE = {
	threat = true,
	resting = true,
	castbar = true,
}

for _, info in ipairs(INDICATORS) do
	PREVIEWABLE[info.key] = true
end

function ns:HasPreviewArt(element)
	return not not PREVIEWABLE[element]
end

local ELEMENT_UNITS = {
	castbar = { player = true, target = true, focus = true, boss = true },
	resting = { player = true },
	readycheck = { player = true, target = true, targettarget = true, focus = true, party = true },
	leader = { player = true, target = true, targettarget = true, focus = true, party = true },
	assistant = { player = true, target = true, targettarget = true, focus = true, party = true },
	raidrole = { player = true, target = true, targettarget = true, focus = true, party = true },
	summon = { player = true, target = true, targettarget = true, focus = true, party = true },
	quest = { target = true, targettarget = true, focus = true, boss = true },
}

local RESTING_SIZE = 20
local RESTING_INSET = 2
local RESTING_TEXTURE_RATIO = 1.5
local RESTING_ATLAS = "UI-HUD-UnitFrame-Player-Rest-Flipbook"
local RESTING_DURATION = 1.5
local RESTING_ROWS = 7
local RESTING_COLUMNS = 6
local RESTING_FRAMES = 42

local OVERLAY_LEVEL = 5
local LEVEL_MIN, LEVEL_MAX = 0, 10

local DEFAULT_LEVELS = {
	resting = OVERLAY_LEVEL,
	threat = 0,
}

for _, info in ipairs(INDICATORS) do
	DEFAULT_LEVELS[info.key] = OVERLAY_LEVEL
end

DEFAULT_ANCHORS.castbarIcon = "LEFT"
DEFAULT_ANCHORS.name = "LEFT"
DEFAULT_ANCHORS.health = "RIGHT"
DEFAULT_ANCHORS.text1 = "CENTER"
DEFAULT_ANCHORS.text2 = "CENTER"
DEFAULT_OFFSETS.text1 = { 0, 12 }
DEFAULT_OFFSETS.text2 = { 0, -12 }
DEFAULT_ANCHORS.resting = "TOPLEFT"
DEFAULT_OFFSETS.resting = { RESTING_INSET, -RESTING_INSET }
DEFAULT_ELEMENT_SIZES.resting = RESTING_SIZE
DEFAULT_ELEMENT_SIZES.threat = THREAT_PADDING
DEFAULT_ELEMENT_SIZES.raidtarget = RAID_MARKER_SIZE

local DEFAULT_TAGS = {
	name = "[difficulty][smartlevel] [name]",
	health = "[maniauf:curhp]",
	text1 = "[maniauf:leader][maniauf:assistant][maniauf:role][maniauf:raidtarget]",
	text2 = "[maniauf:combat][maniauf:resting][maniauf:pvp][maniauf:phase]",
}

ns.TEXT_ELEMENTS = { "name", "health", "text1", "text2" }

local HIDDEN_BY_DEFAULT = {
	text1 = true,
	text2 = true,
}

local UNIT_TAGS = {}

local threatAtlasExists

local function SetThreatArt(texture)
	if threatAtlasExists == nil then
		threatAtlasExists = C_Texture.GetAtlasInfo(THREAT_ATLAS) ~= nil
	end

	if threatAtlasExists then
		texture:SetAtlas(THREAT_ATLAS)
		texture:SetDesaturated(true)
	end
end

local function CreateThreatFade(texture, from, to)
	local group = texture:CreateAnimationGroup()
	group:SetToFinalAlpha(true)

	local alpha = group:CreateAnimation("Alpha")
	alpha:SetDuration(THREAT_FADE)
	alpha:SetFromAlpha(from)
	alpha:SetToAlpha(to)

	return group
end

local function ThreatPostUpdate(element, _, status)
	local active = (status or 0) > 0

	if active == element.threatActive then
		return
	end

	element.threatActive = active
	element:Show()

	if active then
		element.FadeOut:Stop()
		element.FadeIn:Play()
	else
		element.FadeIn:Stop()
		element.FadeOut:Play()
	end
end

local function StoreNested(unit, group, field, value)
	ManiaUFDB.units = ManiaUFDB.units or {}
	ManiaUFDB.units[unit] = ManiaUFDB.units[unit] or {}
	ManiaUFDB.units[unit][group] = ManiaUFDB.units[unit][group] or {}
	ManiaUFDB.units[unit][group][field] = value
end

local function ReadNested(unit, group, field)
	local stored = ManiaUFDB.units and ManiaUFDB.units[unit]
	local sub = stored and stored[group]
	return sub and sub[field]
end

function ns:GetElementUnits(element)
	local units = {}

	for _, unit in ipairs(ns.UNIT_KEYS) do
		if ns:HasElement(unit, element) then
			units[#units + 1] = unit
		end
	end

	return units
end

local function GeometryKey(unit)
	return unit ~= ns.ALL_KEY and unit or nil
end

function ns:IsElementLinked(unit, element)
	if unit == ns.ALL_KEY then
		return false
	end

	return ReadNested(unit, "linked", element) == true
end

function ns:SetElementLinked(unit, element, linked)
	StoreNested(unit, "linked", element, linked or nil)
	ns:UpdateElements()
	ns:UpdateTags()
	ns:DeferMethod(ns, "UpdatePixelGeometry", GeometryKey(unit))
end

local function StoreGeometry(unit, group, element, value)
	StoreNested(unit, group, element, value)
	ns:DeferMethod(ns, "UpdatePixelGeometry", GeometryKey(unit))
end

local function ReadElement(unit, group, element)
	if ns:IsElementLinked(unit, element) then
		return ReadNested(ns.ALL_KEY, group, element)
	end

	return ReadNested(unit, group, element)
end

function ns:HasElement(unit, element)
	local units = ELEMENT_UNITS[element]

	if not units then
		return true
	end

	return not not units[unit]
end

function ns:IsElementShown(unit, element)
	local shown = ReadElement(unit, "elements", element)

	if shown == nil then
		return not HIDDEN_BY_DEFAULT[element]
	end

	return shown
end

function ns:SetElementShown(unit, element, shown)
	StoreNested(unit, "elements", element, shown)
	ns:UpdateElements()
end

function ns:GetElementOffset(unit, element)
	local default = DEFAULT_OFFSETS[element]
	local x = default and default[1] or 0
	local y = default and default[2] or 0
	local offset = ReadElement(unit, "offsets", element)

	if offset then
		x = offset.x or x
		y = offset.y or y
	end

	return x, y
end

function ns:GetAnchorPoints(element)
	if DEFAULT_TAGS[element] then
		return TEXT_POINTS
	end

	return ANCHOR_POINTS
end

function ns:HasElementAnchor(element)
	return DEFAULT_ANCHORS[element] ~= nil
end

function ns:GetElementAnchor(unit, element)
	return ReadElement(unit, "anchors", element) or DEFAULT_ANCHORS[element]
end

function ns:SetElementAnchor(unit, element, point)
	StoreGeometry(unit, "anchors", element, point)
end

function ns:HasElementWidth(element)
	return DEFAULT_TAGS[element] ~= nil
end

function ns:GetElementWidth(unit, element)
	return ReadElement(unit, "widths", element) or 0
end

function ns:SetElementWidth(unit, element, width)
	StoreGeometry(unit, "widths", element, width)
end

function ns:HasElementLevel(element)
	return DEFAULT_LEVELS[element] ~= nil
end

function ns:GetElementLevelRange()
	return LEVEL_MIN, LEVEL_MAX
end

function ns:GetElementLevel(unit, element)
	return ReadElement(unit, "levels", element) or DEFAULT_LEVELS[element]
end

function ns:SetElementLevel(unit, element, level)
	StoreGeometry(unit, "levels", element, level)
end

function ns:HasElementSize(element)
	return DEFAULT_ELEMENT_SIZES[element] ~= nil
end

function ns:GetElementSize(unit, element)
	return ReadElement(unit, "sizes", element) or DEFAULT_ELEMENT_SIZES[element]
end

function ns:SetElementSize(unit, element, size)
	StoreGeometry(unit, "sizes", element, size)
end

function ns:SetElementOffset(unit, element, axis, value)
	local offset = ReadNested(unit, "offsets", element)

	if not offset then
		offset = {}
		StoreNested(unit, "offsets", element, offset)
	end

	offset[axis] = value
	ns:DeferMethod(ns, "UpdatePixelGeometry", GeometryKey(unit))
end

function ns:GetElementTag(unit, element)
	local stored = ReadElement(unit, "tags", element)

	if stored then
		return stored
	end

	local defaults = UNIT_TAGS[unit]

	return defaults and defaults[element] or DEFAULT_TAGS[element]
end

function ns:SetElementTag(unit, element, tagString)
	StoreNested(unit, "tags", element, tagString)
	ns:UpdateTags()
end

local function RestingPostUpdate(element, isResting)
	if isResting then
		element.Anim:Play()
	else
		element.Anim:Stop()
	end
end

function ns:CreateRestingIndicator(frame)
	local indicator = CreateFrame("Frame", nil, frame.borderOverlay)
	ns:SetSize(indicator, RESTING_SIZE, RESTING_SIZE)

	local texture = indicator:CreateTexture(nil, "OVERLAY")
	texture:SetAtlas(RESTING_ATLAS)
	texture:SetPoint("CENTER", indicator, "CENTER", 0, 0)
	indicator.Texture = texture

	local group = indicator:CreateAnimationGroup()
	group:SetLooping("REPEAT")

	local flipBook = group:CreateAnimation("FlipBook")
	flipBook:SetTarget(texture)
	flipBook:SetSmoothing("NONE")
	flipBook:SetOrder(1)
	flipBook:SetDuration(RESTING_DURATION)
	flipBook:SetFlipBookRows(RESTING_ROWS)
	flipBook:SetFlipBookColumns(RESTING_COLUMNS)
	flipBook:SetFlipBookFrames(RESTING_FRAMES)
	flipBook:SetFlipBookFrameWidth(0)
	flipBook:SetFlipBookFrameHeight(0)

	indicator.Anim = group
	indicator.PostUpdate = RestingPostUpdate

	return indicator
end

function ns:CreateIndicators(frame)
	local indicator

	for _, info in ipairs(INDICATORS) do
		indicator = frame.borderOverlay:CreateTexture(nil, "OVERLAY", nil, INDICATOR_SUBLEVEL)
		ns:SetSize(indicator, INDICATOR_SIZE, INDICATOR_SIZE)

		indicator.PostUpdate = info.postUpdate

		frame[info.element] = indicator
		frame.elements[info.key] = indicator
	end

	local threat = frame:CreateTexture(nil, "BACKGROUND", nil, THREAT_SUBLEVEL)
	SetThreatArt(threat)
	threat:SetBlendMode("ADD")
	threat.threatActive = false
	threat.PostUpdate = ThreatPostUpdate
	threat.FadeIn = CreateThreatFade(threat, 0, 1)
	threat.FadeOut = CreateThreatFade(threat, 1, 0)

	threat.FadeOut:SetScript("OnFinished", function()
		threat:Hide()
		threat:SetAlpha(1)
	end)

	frame.ThreatIndicator = threat
	frame.elements.threat = threat
end

function ns:SetOUFElement(frame, element, shown, gateUnit)
	if shown then
		if not frame:IsElementEnabled(element) then
			frame[element]:Hide()
			frame:EnableElement(element, gateUnit)

			if frame:IsElementEnabled(element) then
				frame[element]:ForceUpdate()
			end
		end
	else
		frame:DisableElement(element)
		frame[element]:Hide()
	end
end

function ns:ApplyElementText(frame)
	local unit = frame.unitKey
	local elements = frame.elements

	for _, element in ipairs(ns.TEXT_ELEMENTS) do
		elements[element]:SetShown(ns:IsElementShown(unit, element))
	end
end

function ns:ApplyElements(frame)
	local unit = frame.unitKey
	local elements = frame.elements

	ns:ApplyElementText(frame)

	if not frame.elementsReady then
		return
	end

	if elements.castbar then
		if ns:ShouldPreview(unit, "castbar") then
			ns:StartCastPreview(frame)
		else
			ns:StopCastPreview(frame)
			ns:SetOUFElement(frame, "Castbar", ns:IsElementShown(unit, "castbar"))
		end

		elements.castbar.SafeZone:SetShown(ns:IsElementShown(unit, "castbarLatency"))
	end

	for _, info in ipairs(INDICATORS) do
		if ns:ShouldPreview(unit, info.key) and ns:HasElement(unit, info.key) then
			ns:ShowIndicatorPreview(frame, info)
		else
			ns:SetOUFElement(frame, info.element,
				ns:HasElement(unit, info.key) and ns:IsElementShown(unit, info.key), info.gateUnit)
		end
	end

	if elements.quest and frame:IsElementEnabled("QuestIndicator") then
		elements.quest:ForceUpdate()
	end

	SetThreatArt(elements.threat)

	if ns:ShouldPreview(unit, "threat") then
		ns:ShowThreatPreview(frame)
	else
		ns:SetOUFElement(frame, "ThreatIndicator", ns:IsElementShown(unit, "threat"))
	end

	if elements.resting then
		if ns:ShouldPreview(unit, "resting") then
			ns:ShowRestingPreview(frame)
		else
			ns:SetOUFElement(frame, "RestingIndicator", ns:IsElementShown(unit, "resting"))
		end
	end
end

function ns:ApplyTags(frame)
	local unit = frame.unitKey

	for _, element in ipairs(ns.TEXT_ELEMENTS) do
		frame:Tag(frame.elements[element], ns:GetElementTag(unit, element))
	end

	if frame.__unit then
		frame:UpdateTags()
	end
end

local function GetLevelHolder(frame, level)
	if level == 0 then
		return frame
	end

	frame.levelHolders = frame.levelHolders or {}

	local holder = frame.levelHolders[level]

	if not holder then
		holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints()
		holder:SetFrameLevel(frame:GetFrameLevel() + level)
		frame.levelHolders[level] = holder
	end

	return holder
end

local function ApplyLevel(frame, region, unit, element)
	local holder = GetLevelHolder(frame, ns:GetElementLevel(unit, element))

	if region:GetParent() ~= holder then
		region:SetParent(holder)
	end
end

local function PlaceIcon(frame, region, unit, element)
	local point = ns:GetElementAnchor(unit, element)
	local x, y = ns:GetElementOffset(unit, element)
	local size = ns:GetElementSize(unit, element)

	ApplyLevel(frame, region, unit, element)
	region:ClearAllPoints()
	ns:SetPoint(region, point, frame, point, x, y)
	ns:SetSize(region, size, size)

	return size
end

local function TextInset(point)
	if point == "LEFT" then
		return ns.TEXT_PADDING
	elseif point == "RIGHT" then
		return -ns.TEXT_PADDING
	end

	return 0
end

local function PlaceText(frame, text, unit, element)
	local point = ns:GetElementAnchor(unit, element)
	local x, y = ns:GetElementOffset(unit, element)
	local width = ns:GetElementWidth(unit, element)

	text:ClearAllPoints()
	text:SetJustifyH(point)
	ns:SetPoint(text, point, frame.Health, point, TextInset(point) + x, y)

	if width > 0 then
		ns:SetWidth(text, width)
	else
		text:SetWidth(0)
	end

	return point, width
end

function ns:PlaceElements(frame)
	local unit = frame.unitKey
	local elements = frame.elements
	local x, y

	local healthPoint = PlaceText(frame, elements.health, unit, "health")
	local namePoint, nameWidth = PlaceText(frame, elements.name, unit, "name")

	PlaceText(frame, elements.text1, unit, "text1")
	PlaceText(frame, elements.text2, unit, "text2")

	if nameWidth == 0 and namePoint == "LEFT" and healthPoint == "RIGHT" then
		ns:SetPoint(elements.name, "RIGHT", elements.health, "LEFT", -ns.TEXT_PADDING, 0)
	end

	if elements.resting then
		local size = PlaceIcon(frame, elements.resting, unit, "resting")
		ns:SetSize(elements.resting.Texture, size * RESTING_TEXTURE_RATIO,
			size * RESTING_TEXTURE_RATIO)
	end

	for _, info in ipairs(INDICATORS) do
		PlaceIcon(frame, elements[info.key], unit, info.key)
	end

	local padding = ns:GetElementSize(unit, "threat")
	x, y = ns:GetElementOffset(unit, "threat")
	ApplyLevel(frame, elements.threat, unit, "threat")
	elements.threat:ClearAllPoints()
	ns:SetPoint(elements.threat, "TOPLEFT", frame, "TOPLEFT", -padding + x, padding + y)
	ns:SetPoint(elements.threat, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding + x, -padding + y)
end
