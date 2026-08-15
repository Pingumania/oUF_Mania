local _, ns = ...

local EMPTY = {}

ns.ALL_KEY = "all"
ns.ELEMENT_GROUPS = {
	"elements", "offsets", "anchors", "widths", "sizes", "tags", "linked", "levels",
}

local INDICATOR_SIZE = ns.INDICATOR_SIZE
local INDICATOR_SUBLEVEL = 2
local THREAT_FADE = 0.25
local THREAT_SUBLEVEL = -1
local THREAT_ATLAS = "timerunning-redbutton-backglow"

local PVP_FFA_ATLAS = "UI-HUD-UnitFrame-Player-PVP-FFAIcon"

local PVP_ICON_STYLES = {
	{ value = "questlog", label = "Quest log",
		Alliance = "questlog-questtypeicon-alliance", Horde = "questlog-questtypeicon-horde",
		FFA = PVP_FFA_ATLAS },
	{ value = "unitframe", label = "Unit frame icon",
		Alliance = "UI-HUD-UnitFrame-Player-PVP-AllianceIcon",
		Horde = "UI-HUD-UnitFrame-Player-PVP-HordeIcon", FFA = PVP_FFA_ATLAS },
	{ value = "questportrait", label = "Quest portrait",
		Alliance = "QuestPortraitIcon-Alliance-small", Horde = "QuestPortraitIcon-Horde-small",
		FFA = PVP_FFA_ATLAS },
	{ value = "warfront", label = "Warfront banner",
		Alliance = "AllianceWarfrontMapBanner", Horde = "HordeWarfrontMapBanner",
		FFA = PVP_FFA_ATLAS },
	{ value = "symbol", label = "Faction symbol",
		Alliance = "AllianceSymbol", Horde = "HordeSymbol", FFA = PVP_FFA_ATLAS },
}

local PVP_STYLE_DEFAULT = PVP_ICON_STYLES[1].value

function ns:GetPvPIconStyles()
	return PVP_ICON_STYLES
end

function ns:GetPvPIconStyle()
	return ns.db.pvpIcon or PVP_STYLE_DEFAULT
end

function ns:SetPvPIconStyle(value)
	ns.db.pvpIcon = value
	ns:UpdateElements()
	ns:UpdateTags()
end

local pvpAtlasExists = {}

function ns:GetPvPIcon(status)
	if not status then
		return nil
	end

	local value = ns:GetPvPIconStyle()
	local atlas

	for _, style in ipairs(PVP_ICON_STYLES) do
		if style.value == value then
			atlas = style[status]
			break
		end
	end

	if not atlas then
		return nil
	end

	if pvpAtlasExists[atlas] == nil then
		pvpAtlasExists[atlas] = C_Texture.GetAtlasInfo(atlas) ~= nil
	end

	return pvpAtlasExists[atlas] and atlas or nil
end

local function PvPPostUpdate(element, unit, status)
	local atlas = ns:GetPvPIcon(status)

	if atlas then
		element:SetAtlas(atlas, false, nil, true)
	end
end

local PVP_PREVIEW_ORDER = { "Alliance", "Horde", "FFA" }

local function GetPvPPreviewVariants()
	local variants = {}

	for _, status in ipairs(PVP_PREVIEW_ORDER) do
		local atlas = ns:GetPvPIcon(status)

		if atlas then
			variants[#variants + 1] = atlas
		end
	end

	return variants
end

local RAIDROLE_ATLASES = { "RaidFrame-Icon-MainTank", "RaidFrame-Icon-MainAssist" }

local function GetRaidRolePreviewVariants()
	return RAIDROLE_ATLASES
end

local LFG_ROLE_STRINGS = {
	[Enum.LFGRole.Tank] = "TANK",
	[Enum.LFGRole.Healer] = "HEALER",
	[Enum.LFGRole.Damage] = "DAMAGER",
}

local ROLE_ICON_STYLES = {
	{ value = "raid", label = "Raid frame",
		TANK = "UI-LFG-RoleIcon-Tank-Micro-Raid", HEALER = "UI-LFG-RoleIcon-Healer-Micro-Raid",
		DAMAGER = "UI-LFG-RoleIcon-DPS-Micro-Raid" },
	{ value = "group", label = "Group finder",
		TANK = "UI-LFG-RoleIcon-Tank-Micro", HEALER = "UI-LFG-RoleIcon-Healer-Micro",
		DAMAGER = "UI-LFG-RoleIcon-DPS-Micro" },
	{ value = "compact", label = "Compact raid frame",
		TANK = "GM-icon-role-tank", HEALER = "GM-icon-role-healer", DAMAGER = "GM-icon-role-dps" },
	{ value = "journal", label = "Encounter journal",
		TANK = "icons_16x16_tank", HEALER = "icons_16x16_healer", DAMAGER = "icons_16x16_damage" },
	{ value = "premade", label = "Premade groups",
		TANK = "groupfinder-icon-role-micro-tank", HEALER = "groupfinder-icon-role-micro-heal",
		DAMAGER = "groupfinder-icon-role-micro-dps" },
}

local ROLE_STYLE_DEFAULT = ROLE_ICON_STYLES[1].value

function ns:GetRoleIconStyles()
	return ROLE_ICON_STYLES
end

function ns:GetRoleIconStyle()
	return ns.db.roleIcon or ROLE_STYLE_DEFAULT
end

function ns:SetRoleIconStyle(value)
	ns.db.roleIcon = value
	ns:UpdateElements()
	ns:UpdateTags()
end

local roleAtlasExists = {}

function ns:GetRoleIcon(roleString)
	if not roleString then
		return nil
	end

	local value = ns:GetRoleIconStyle()
	local atlas

	for _, style in ipairs(ROLE_ICON_STYLES) do
		if style.value == value then
			atlas = style[roleString]
			break
		end
	end

	if not atlas then
		return nil
	end

	if roleAtlasExists[atlas] == nil then
		roleAtlasExists[atlas] = C_Texture.GetAtlasInfo(atlas) ~= nil
	end

	return roleAtlasExists[atlas] and atlas or nil
end

local function RoleIndicatorPostUpdate(element, role)
	local atlas = ns:GetRoleIcon(LFG_ROLE_STRINGS[role])

	if atlas then
		element:SetAtlas(atlas, false, nil, true)
	end
end

local ROLE_PREVIEW_ORDER = { "TANK", "HEALER", "DAMAGER" }

local function GetRolePreviewVariants()
	local variants = {}

	for _, role in ipairs(ROLE_PREVIEW_ORDER) do
		local atlas = ns:GetRoleIcon(role)

		if atlas then
			variants[#variants + 1] = atlas
		end
	end

	return variants
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
	return ns.db.questIcon or QUEST_ATLAS
end

function ns:SetQuestIconStyle(atlas)
	ns.db.questIcon = atlas
	ns:UpdateElements()
end

function ns:ApplyQuestIcon(element)
	element:SetAtlas(ns:GetQuestIconStyle(), false, nil, true)
end

local function QuestPostUpdate(element)
	ns:ApplyQuestIcon(element)
end

local INDICATORS = {
	{ key = "leader", element = "LeaderIndicator",
		atlas = "UI-HUD-UnitFrame-Player-Group-LeaderIcon" },
	{ key = "assistant", element = "AssistantIndicator",
		texture = [[Interface\GroupFrame\UI-Group-AssistantIcon]] },
	{ key = "raidrole", element = "RaidRoleIndicator",
		previewVariants = GetRaidRolePreviewVariants },
	{ key = "raidtarget", element = "RaidTargetIndicator",
		marker = 1 },
	{ key = "combat", element = "CombatIndicator",
		atlas = "UI-HUD-UnitFrame-Player-CombatIcon" },
	{ key = "phase", element = "PhaseIndicator",
		atlas = "RaidFrame-Icon-Phasing" },
	{ key = "grouprole", element = "GroupRoleIndicator",
		postUpdate = RoleIndicatorPostUpdate, previewVariants = GetRolePreviewVariants },
	{ key = "quest", element = "QuestIndicator",
		postUpdate = QuestPostUpdate },
	{ key = "pvp", element = "PvPIndicator",
		postUpdate = PvPPostUpdate, previewVariants = GetPvPPreviewVariants },
	{ key = "pvpclass", element = "PvPClassificationIndicator",
		atlas = "nameplates-icon-flag-alliance" },
	{ key = "readycheck", element = "ReadyCheckIndicator",
		atlas = "UI-LFG-ReadyMark-Raid", gateUnit = "party" },
	{ key = "resurrect", element = "ResurrectIndicator",
		atlas = "RaidFrame-Icon-Rez" },
	{ key = "summon", element = "SummonIndicator",
		atlas = "RaidFrame-Icon-SummonPending" },
}

local TEXT_POINTS = { "LEFT", "CENTER", "RIGHT" }

local ANCHOR_POINTS = {
	"TOPLEFT", "TOP", "TOPRIGHT",
	"LEFT", "CENTER", "RIGHT",
	"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

function ns:HasPreviewArt(element)
	return not not ns.PREVIEWABLE[element]
end

local RESTING_SIZE = ns.RESTING_SIZE
local RESTING_TEXTURE_RATIO = 1.5
local RESTING_ATLAS = "UI-HUD-UnitFrame-Player-Rest-Flipbook"
local RESTING_DURATION = 1.5
local RESTING_ROWS = 7
local RESTING_COLUMNS = 6
local RESTING_FRAMES = 42

local LEVEL_MIN, LEVEL_MAX = 0, 10

local CUSTOM_TEXT_PREFIX = "customText"

local function CustomTextKey(id)
	return CUSTOM_TEXT_PREFIX .. id
end

local function FindCustomTextIndex(key)
	for index, entry in ipairs(ns.db.customTexts or EMPTY) do
		if CustomTextKey(entry.id) == key then
			return index
		end
	end
end

local function CustomTextDefaults()
	return {
		anchor = { default = "CENTER" },
		offset = { 0, 0 },
		tag = { default = "" },
		hidden = { default = true },
	}
end

ns.TEXT_ELEMENTS = { "name", "health" }
ns.CUSTOM_TEXT_ELEMENTS = {}

function ns:RebuildTextElements()
	local custom = ns.CUSTOM_TEXT_ELEMENTS
	local all = ns.TEXT_ELEMENTS
	local key

	for index = #custom, 1, -1 do
		custom[index] = nil
	end

	for index = #all, 1, -1 do
		all[index] = nil
	end

	all[1], all[2] = "name", "health"

	for _, entry in ipairs(ns.db.customTexts or EMPTY) do
		key = CustomTextKey(entry.id)
		custom[#custom + 1] = key
		all[#all + 1] = key
		ns.Defaults.elements[key] = ns.Defaults.elements[key] or CustomTextDefaults()
	end
end

function ns:GetCustomTexts()
	local entries = {}

	for _, entry in ipairs(ns.db.customTexts or EMPTY) do
		entries[#entries + 1] = { key = CustomTextKey(entry.id), label = entry.label }
	end

	return entries
end

function ns:AddCustomTextElement(label)
	local db = ns.db
	local id = (db.nextCustomTextId or 0) + 1
	local key = CustomTextKey(id)

	db.nextCustomTextId = id
	db.customTexts = db.customTexts or {}
	db.customTexts[#db.customTexts + 1] = { id = id, label = label }

	ns:RebuildTextElements()
	ns:CreateLiveTextElement(key)

	return key
end

function ns:RenameCustomTextElement(key, label)
	local index = FindCustomTextIndex(key)

	if index then
		ns.db.customTexts[index].label = label
	end
end

function ns:RemoveCustomTextElement(key)
	local db = ns.db
	local index = FindCustomTextIndex(key)

	if index then
		table.remove(db.customTexts, index)
	end

	ns.Defaults.elements[key] = nil

	for _, stored in next, db.units or EMPTY do
		for _, group in ipairs(ns.ELEMENT_GROUPS) do
			if stored[group] then
				stored[group][key] = nil
			end
		end
	end

	ns:RebuildTextElements()
	ns:RemoveLiveTextElement(key)
end

function ns:ResetCustomTextElements()
	local db = ns.db

	for _, key in ipairs(ns.CUSTOM_TEXT_ELEMENTS) do
		ns.Defaults.elements[key] = nil
		ns:RemoveLiveTextElement(key)
	end

	db.customTexts = nil
	db.nextCustomTextId = nil

	ns:RebuildTextElements()
end

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
	local db = ns.db

	db.units = db.units or {}
	db.units[unit] = db.units[unit] or {}
	db.units[unit][group] = db.units[unit][group] or {}
	db.units[unit][group][field] = value
end

local function ReadNested(unit, group, field)
	local db = ns.db
	local stored = db.units and db.units[unit]
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
	local units = ns.ELEMENT_UNITS[element]

	if not units then
		return true
	end

	return not not units[unit]
end

function ns:IsElementShown(unit, element)
	local shown = ReadElement(unit, "elements", element)

	if shown == nil then
		local info = ns.Defaults.elements[element]
		local hidden = info and info.hidden

		if not hidden then
			return true
		end

		local value = hidden[unit]

		if value == nil then
			value = hidden.default
		end

		return not value
	end

	return shown
end

function ns:SetElementShown(unit, element, shown)
	StoreNested(unit, "elements", element, shown)
	ns:UpdateElements()
end

function ns:GetElementOffset(unit, element)
	local info = ns.Defaults.elements[element]
	local default = info and info.offset
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
	local info = ns.Defaults.elements[element]

	if info and info.tag then
		return TEXT_POINTS
	end

	return ANCHOR_POINTS
end

function ns:HasElementAnchor(element)
	local info = ns.Defaults.elements[element]
	return not not (info and info.anchor)
end

function ns:GetElementAnchor(unit, element)
	local stored = ReadElement(unit, "anchors", element)

	if stored then
		return stored
	end

	local info = ns.Defaults.elements[element]
	local anchors = info and info.anchor

	return anchors and (anchors[unit] or anchors.default)
end

function ns:SetElementAnchor(unit, element, point)
	StoreGeometry(unit, "anchors", element, point)
end

function ns:HasElementWidth(element)
	local info = ns.Defaults.elements[element]
	return not not (info and info.tag)
end

function ns:GetElementWidth(unit, element)
	return ReadElement(unit, "widths", element) or 0
end

function ns:SetElementWidth(unit, element, width)
	StoreGeometry(unit, "widths", element, width)
end

function ns:HasElementLevel(element)
	local info = ns.Defaults.elements[element]
	return info and info.level ~= nil
end

function ns:GetElementLevelRange()
	return LEVEL_MIN, LEVEL_MAX
end

function ns:GetElementLevel(unit, element)
	local info = ns.Defaults.elements[element]
	return ReadElement(unit, "levels", element) or (info and info.level)
end

function ns:SetElementLevel(unit, element, level)
	StoreGeometry(unit, "levels", element, level)
end

function ns:HasElementSize(element)
	local info = ns.Defaults.elements[element]
	return not not (info and info.size)
end

function ns:GetElementSize(unit, element)
	local stored = ReadElement(unit, "sizes", element)

	if stored then
		return stored
	end

	local info = ns.Defaults.elements[element]
	local sizes = info and info.size

	return sizes and (sizes[unit] or sizes.default)
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

	local info = ns.Defaults.elements[element]
	local tags = info and info.tag

	return tags and (tags[unit] or tags.default)
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
			ns:ClearIndicatorPreview(elements[info.key])
			ns:SetOUFElement(frame, info.element,
				ns:HasElement(unit, info.key) and ns:IsElementShown(unit, info.key), info.gateUnit)
		end
	end

	if elements.quest and frame:IsElementEnabled("QuestIndicator") then
		elements.quest:ForceUpdate()
	end

	if elements.pvp and frame:IsElementEnabled("PvPIndicator") then
		elements.pvp:ForceUpdate()
	end

	if elements.grouprole and frame:IsElementEnabled("GroupRoleIndicator") then
		elements.grouprole:ForceUpdate()
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

	for _, key in ipairs(ns.CUSTOM_TEXT_ELEMENTS) do
		PlaceText(frame, elements[key], unit, key)
	end

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
