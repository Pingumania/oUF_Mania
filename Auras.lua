local _, ns = ...

local EMPTY = {}
local aurasSecret

local AURA_SECTION = "auras"
local AURA_PREFIX = "aura"
local MAIN_GROUP = "main"
local OTHERS_GROUP = "others"
local SWAP_KEY = "aurasSwap"
local COUNT_KEY = "auraCount"
local DURATION_KEY = "auraDuration"
local ICON_ZOOM = 0.08
local GLOW_TEXTURE = [[Interface\TargetingFrame\UI-TargetingFrame-Stealable]]
local GLOW_OUTSET = 3
local SWIPE_TEXTURE = [[Interface\Buttons\WHITE8X8]]
local SWIPE_ALPHA = 0.7
local CORNER_REACH = math.sqrt(2)
local EDGE_MEDIA = [[Interface\AddOns\oUF_Mania\Media\cooldown-edge-]]
local DEFAULT_EDGE = [[Interface\Cooldown\UI-HUD-ActionBar-SecondaryCooldown]]
local CANCEL_BUTTONS = "RightButtonUp"
local TOOLTIP_ANCHOR = "ANCHOR_BOTTOMLEFT"

ns.AURA_SECTION = AURA_SECTION
ns.AURA_COUNT_KEY = COUNT_KEY
ns.AURA_DURATION_KEY = DURATION_KEY
ns.AURA_SWAP_KEY = SWAP_KEY

ns.AURA_EDGES = {
	{ value = "off", label = "Off" },
	{ value = "default", label = "Default" },
	{ value = "line", label = "Line" },
	{ value = "thin", label = "Thin line" },
	{ value = "wedge", label = "Wedge" },
}

ns.AURA_FILTERS = {
	{ token = "PLAYER", label = "Cast by me" },
	{ token = "RAID", label = "Raid (castable or dispellable)" },
	{ token = "RAID_PLAYER_DISPELLABLE", label = "Raid can dispel" },
	{ token = "RAID_IN_COMBAT", label = "Raid frames in combat" },
	{ token = "DISPELLABLE", label = "Dispellable" },
	{ token = "CANCELABLE", label = "Cancelable" },
	{ token = "CROWD_CONTROL", label = "Crowd control" },
	{ token = "BIG_DEFENSIVE", label = "Big defensive" },
	{ token = "EXTERNAL_DEFENSIVE", label = "External defensive" },
	{ token = "IMPORTANT", label = "Important" },
}

local GROUP_DEFAULTS = {
	type = "HELPFUL",
	shown = true,
	point = "BOTTOMLEFT",
	x = 0,
	y = 0,
	vertical = false,
	size = 17,
	max = 16,
	perRow = 6,
	spacing = 3,
	rowSpacing = 3,
	sort = AuraContainerSortMethod.Default,
	reverse = false,
	cooldown = true,
	edge = "line",
	edgeColor = { 1, 0.82, 0 },
	border = true,
	stealable = true,
	tooltip = true,
	cancel = false,
	count = true,
	duration = false,
	bar = "off",
	barHeight = 3,
	barColorMode = "custom",
	barColor = { 1, 0.82, 0 },
	pandemic = false,
	hideOthers = true,
	onlyDispellable = true,
}

local TARGET_GROUPS = {
	{ id = 1, label = "Buffs", type = "HELPFUL", max = 32, size = 20 },
	{ id = 2, label = "Debuffs", type = "HARMFUL", max = 16, attach = 1, size = 20 },
}

local MEMBER_GROUPS = {
	{ id = 1, label = "Debuffs", type = "HARMFUL", max = 4, size = 15, spacing = 2, perRow = 4,
		point = "RIGHT" },
}

local UNIT_GROUPS = {
	[ns.ALL_KEY] = TARGET_GROUPS,
	target = TARGET_GROUPS,
	focus = TARGET_GROUPS,
	pet = MEMBER_GROUPS,
	party = MEMBER_GROUPS,
}

local FLIPPED = {
	TOPLEFT = "BOTTOMLEFT",
	TOP = "BOTTOM",
	TOPRIGHT = "BOTTOMRIGHT",
	LEFT = "RIGHT",
	CENTER = "CENTER",
	RIGHT = "LEFT",
	BOTTOMLEFT = "TOPLEFT",
	BOTTOM = "TOP",
	BOTTOMRIGHT = "TOPRIGHT",
}

local function GroupKey(id)
	return AURA_PREFIX .. id
end

local function StorageUnit(unit)
	if ns:IsElementLinked(unit, AURA_SECTION) then
		return ns.ALL_KEY
	end

	return unit
end

local function StoredGroups(unit)
	local stored = ns.db.units and ns.db.units[StorageUnit(unit)]
	return stored and stored.auras
end

local function Groups(unit)
	return StoredGroups(unit) or UNIT_GROUPS[StorageUnit(unit)] or EMPTY
end

local function WritableGroups(unit)
	local groups = StoredGroups(unit)
	local key

	if not groups then
		key = StorageUnit(unit)
		groups = CopyTable(UNIT_GROUPS[key] or EMPTY)

		ns.db.units = ns.db.units or {}
		ns.db.units[key] = ns.db.units[key] or {}
		ns.db.units[key].auras = groups
	end

	return groups
end

local function FindGroup(groups, key)
	for index, group in ipairs(groups) do
		if GroupKey(group.id) == key then
			return group, index
		end
	end
end

local function Value(group, field)
	local value = group[field]

	if value == nil then
		return GROUP_DEFAULTS[field]
	end

	return value
end

local function Snap(frame, value)
	local unit = ns:PixelSize(frame)
	return Round(value / unit) * unit
end

local function ButtonSize(frame, group)
	return Snap(frame, Value(group, "size") + 2 * ns.BAR_INSET)
end

local function Spacing(frame, group, field)
	return Snap(frame, Value(group, field) - 2 * ns.BORDER_SHADOW)
end

function ns:GetAuraGroups(unit)
	local entries = {}

	for _, group in ipairs(Groups(unit)) do
		entries[#entries + 1] = { key = GroupKey(group.id), label = group.label }
	end

	return entries
end

function ns:GetAuraGroupLabel(unit, key)
	local group = FindGroup(Groups(unit), key)
	return group and group.label
end

function ns:GetAuraValue(unit, key, field)
	local group = FindGroup(Groups(unit), key)
	return Value(group or EMPTY, field)
end

function ns:SetAuraValue(unit, key, field, value)
	local group = FindGroup(WritableGroups(unit), key)

	if group then
		group[field] = value
		ns:DeferMethod(ns, "UpdateAuras")
	end
end

function ns:GetAuraAttach(unit, key)
	local group = FindGroup(Groups(unit), key)
	return group and group.attach and GroupKey(group.attach)
end

function ns:SetAuraAttach(unit, key, parentKey)
	local groups = WritableGroups(unit)
	local group = FindGroup(groups, key)
	local parent = parentKey and FindGroup(groups, parentKey)

	if group then
		group.attach = parent and parent.id or nil
		ns:DeferMethod(ns, "UpdateAuras")
	end
end

function ns:GetAuraAttachCandidates(unit, key)
	local groups = Groups(unit)
	local candidates = {}
	local parent, cyclic

	for _, group in ipairs(groups) do
		parent = group
		cyclic = false

		while parent do
			if GroupKey(parent.id) == key then
				cyclic = true
				break
			end

			parent = parent.attach and FindGroup(groups, GroupKey(parent.attach))
		end

		if not cyclic then
			candidates[#candidates + 1] = { key = GroupKey(group.id), label = group.label }
		end
	end

	return candidates
end

function ns:GetAuraFilter(unit, key, token)
	local group = FindGroup(Groups(unit), key)
	return group and group.filters and group.filters[token]
end

function ns:SetAuraFilter(unit, key, token, mode)
	local group = FindGroup(WritableGroups(unit), key)

	if group then
		group.filters = group.filters or {}
		group.filters[token] = mode
		ns:DeferMethod(ns, "UpdateAuras")
	end
end

function ns:AddAuraGroup(unit, label)
	local groups = WritableGroups(unit)
	local id = 0

	for _, group in ipairs(groups) do
		id = math.max(id, group.id)
	end

	id = id + 1
	groups[#groups + 1] = { id = id, label = label }
	ns:DeferMethod(ns, "UpdateAuras")

	return GroupKey(id)
end

function ns:RenameAuraGroup(unit, key, label)
	local group = FindGroup(WritableGroups(unit), key)

	if group then
		group.label = label
	end
end

function ns:RemoveAuraGroup(unit, key)
	local groups = WritableGroups(unit)
	local group, index = FindGroup(groups, key)

	if not group then
		return
	end

	table.remove(groups, index)

	for _, other in ipairs(groups) do
		if other.attach == group.id then
			other.attach = group.attach
		end
	end

	ns:DeferMethod(ns, "UpdateAuras")
end

local function FilterString(group, frame)
	local tokens = { Value(group, "type") }
	local filters = group.filters or EMPTY
	local mode
	local harmful = tokens[1] == "HARMFUL"

	for _, info in ipairs(ns.AURA_FILTERS) do
		mode = filters[info.token]

		if mode == "only" then
			tokens[#tokens + 1] = info.token
		elseif mode == "exclude" then
			tokens[#tokens + 1] = "!" .. info.token
		end
	end

	if harmful then
		tokens[#tokens + 1] = "INCLUDE_NAME_PLATE_ONLY"

		if Value(group, "onlyDispellable") and not filters.RAID and frame.auraAssist then
			tokens[#tokens + 1] = "RAID"
		end
	end

	return table.concat(tokens, "|"), harmful
end

local BORDER_DISPEL = {
	style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
	showWhenHarmful = true,
	showWithoutDispelType = true,
}

local DURATION_HIDDEN = 60
local DURATION_WARNING = 10
local DURATION_URGENT = 5

local durationOptions

local function DurationOptions()
	if durationOptions then
		return durationOptions
	end

	local formatter = C_StringUtil.CreateNumericRuleFormatter()
	formatter:AddBreakpoint({ threshold = 0, step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%d" })

	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	curve:AddPoint(0, RED_FONT_COLOR)
	curve:AddPoint(DURATION_URGENT, YELLOW_FONT_COLOR)
	curve:AddPoint(DURATION_WARNING, WHITE_FONT_COLOR)
	curve:AddPoint(DURATION_HIDDEN, CreateColor(1, 1, 1, 0))

	durationOptions = {
		textFormatter = formatter,
		textColor = { curve = curve, property = Enum.DurationTextBindingProperty.RemainingDuration },
	}

	return durationOptions
end

local STEALABLE_DISPEL = {
	style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
	showWhenHelpful = true,
	showWithoutDispelType = true,
	stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
}

local function ConfigureButton(container, button)
	local group = container.group
	local frame = container.frame
	local size = ButtonSize(frame, group)
	local harmful = Value(group, "type") == "HARMFUL"

	button:ClearDurationCooldown()
	button:ClearApplicationCount()
	button:ClearDurationText()
	button:ClearDurationBar()
	button:ClearPandemicRegions()
	button:ClearDispelTypeTextures()

	button:SetSize(size, size)
	ns:SetBorderPanelSize(button.Frame, size - 2 * ns.BAR_INSET)
	ns:SetAuraTextFont(button.Count, frame.unitKey)
	ns:SetAuraTextFont(button.Time, frame.unitKey)
	button:EnableMouse(Value(group, "tooltip"))
	button:SetCancelAuraButtons(Value(group, "cancel") and frame.unitKey == "player" and CANCEL_BUTTONS
		or nil)

	if Value(group, "cooldown") then
		local cooldownSize = (size - 2 * ns.BAR_INSET) * CORNER_REACH
		local edge = Value(group, "edge")

		button.Cooldown:SetSize(cooldownSize, cooldownSize)
		button.Cooldown:SetDrawEdge(edge ~= "off")

		if edge == "default" then
			button.Cooldown:SetEdgeTexture(DEFAULT_EDGE)
			button.Cooldown:SetEdgeColor(1, 1, 1, 1)
		else
			button.Cooldown:SetEdgeTexture(EDGE_MEDIA .. edge)
			button.Cooldown:SetEdgeColor(unpack(Value(group, "edgeColor")))
		end
		button:SetDurationCooldown(button.Cooldown)
	else
		button.Cooldown:Hide()
	end

	if Value(group, "count") then
		button:SetApplicationCount(button.Count, EMPTY)
	else
		button.Count:Hide()
	end

	button.Time:SetShown(Value(group, "duration"))

	if Value(group, "duration") then
		button:SetDurationText(button.Time, DurationOptions())
	end

	button.Bar:SetShown(Value(group, "bar") ~= "off")

	if Value(group, "bar") ~= "off" then
		local edge = Value(group, "bar") == "top" and "TOP" or "BOTTOM"

		button.Bar:ClearAllPoints()
		button.Bar:SetPoint(edge .. "LEFT", button.Icon, edge .. "LEFT", 0, 0)
		button.Bar:SetPoint(edge .. "RIGHT", button.Icon, edge .. "RIGHT", 0, 0)
		ns:SetHeight(button.Bar, Value(group, "barHeight"))
		button.Bar:SetStatusBarTexture(ns:GetTexture())

		if Value(group, "barColorMode") == "dispel" then
			button:AddDispelTypeTexture(button.Bar:GetStatusBarTexture(), {
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				showWhenHarmful = true,
				showWhenHelpful = true,
				showWithoutDispelType = true,
				customDispelColorMap = frame.colors.dispel,
			})
		else
			button.Bar:SetStatusBarColor(unpack(Value(group, "barColor")))
		end

		button:SetDurationBar(button.Bar, EMPTY)
	end

	if Value(group, "pandemic") then
		button:AddPandemicRegion(button.Pandemic)
	else
		button.Pandemic:Hide()
	end

	for _, texture in ipairs(button.BorderTextures) do
		if harmful and Value(group, "border") then
			button:AddDispelTypeTexture(texture, BORDER_DISPEL)
		else
			texture:SetVertexColor(1, 1, 1)
			texture:Show()
		end
	end

	if not harmful and Value(group, "stealable") then
		button:AddDispelTypeTexture(button.Stealable, STEALABLE_DISPEL)
	else
		button.Stealable:Hide()
	end
end

function ns:GetAuraFilterString(unit, key)
	local group = FindGroup(Groups(unit), key)
	return group and (FilterString(group, EMPTY))
end

local function CreateGlow(overlay, button)
	local glow = overlay:CreateTexture(nil, "OVERLAY")
	glow:SetPoint("TOPLEFT", button, "TOPLEFT", -GLOW_OUTSET, GLOW_OUTSET)
	glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", GLOW_OUTSET, -GLOW_OUTSET)
	glow:SetTexture(GLOW_TEXTURE)
	glow:SetBlendMode("ADD")
	return glow
end

local function CreateButton(container, button)
	button:SetTooltipAnchorPoint(TOOLTIP_ANCHOR, 0, 0)

	local holder = CreateFrame("Frame", nil, button)
	holder:SetAllPoints()
	ns:CreateBorder(holder)
	button.Frame = holder
	button.BorderTextures = {}

	for _, texture in ipairs(holder.borderTextures) do
		if texture:IsShown() then
			button.BorderTextures[#button.BorderTextures + 1] = texture
		end
	end

	local icon = holder:CreateTexture(nil, "ARTWORK")
	ns:SetPoint(icon, "TOPLEFT", holder, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
	ns:SetPoint(icon, "BOTTOMRIGHT", holder, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
	icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
	button:SetIcon(icon)
	button.Icon = icon

	local clip = CreateFrame("Frame", nil, holder)
	clip:SetAllPoints(icon)
	clip:SetFrameLevel(holder:GetFrameLevel() + 1)
	clip:SetClipsChildren(true)

	local cooldown = CreateFrame("Cooldown", nil, clip, "CooldownFrameTemplate")
	cooldown:ClearAllPoints()
	cooldown:SetPoint("CENTER", icon, "CENTER", 0, 0)
	cooldown:SetSwipeTexture(SWIPE_TEXTURE)
	cooldown:SetSwipeColor(0, 0, 0, SWIPE_ALPHA)
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(true)
	button.Cooldown = cooldown

	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(holder.borderOverlay:GetFrameLevel() + 1)

	local count = overlay:CreateFontString(nil, "OVERLAY")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
	count.fontKey = COUNT_KEY
	button.Count = count

	local time = overlay:CreateFontString(nil, "OVERLAY")
	time:SetPoint("CENTER", button, "CENTER", 0, 0)
	time.fontKey = DURATION_KEY
	button.Time = time

	local bar = CreateFrame("StatusBar", nil, overlay)
	button.Bar = bar

	local barBackground = bar:CreateTexture(nil, "BACKGROUND")
	barBackground:SetAllPoints()
	barBackground:SetColorTexture(0, 0, 0, 1)

	button.Stealable = CreateGlow(overlay, button)
	button.Pandemic = CreateGlow(overlay, button)
	button.Pandemic:SetVertexColor(ORANGE_FONT_COLOR:GetRGB())

	ConfigureButton(container, button)
end

local function GroupOptions(container, group, maxCount)
	local frame = container.frame

	return {
		maxFrameCount = maxCount,
		sortMethod = Value(group, "sort"),
		sortDirection = Value(group, "reverse") and AuraContainerSortDirection.Reverse
			or AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			CreateButton(container, button)
		end,
		layout = {
			elementSpacing = Spacing(frame, group, "spacing"),
			lineSpacing = Spacing(frame, group, "rowSpacing"),
			groupSpacing = Spacing(frame, group, "spacing"),
			groupLineSpacing = Spacing(frame, group, "rowSpacing"),
			elementWidth = ButtonSize(frame, group),
			elementHeight = ButtonSize(frame, group),
		},
	}
end

local function ConfigureGroup(container, groupKey, filter, maxCount, candidates)
	local group = container.group
	local options = GroupOptions(container, group, maxCount)

	if not container:HasAuraGroup(groupKey) then
		options.candidateFilters = candidates
		container:AddAuraGroup(groupKey, filter, options)
		return
	end

	container:SetAuraGroupFilterString(groupKey, filter)
	container:SetAuraGroupMaxFrameCount(groupKey, maxCount)
	container:SetAuraGroupCandidateFilters(groupKey, candidates)
	container:SetAuraGroupSortMethod(groupKey, options.sortMethod, options.sortDirection)
	container:SetAuraGroupLayout(groupKey, options.layout)
end

local NOT_FROM_PLAYERS = { isFromPlayerOrPlayerPet = false }

local function ConfigureFilters(container)
	local group = container.group
	local frame = container.frame
	local filter, harmful = FilterString(group, frame)
	local maxCount = Value(group, "max")
	local ownMode = (group.filters or EMPTY).PLAYER
	local split = harmful and Value(group, "hideOthers") and frame.auraHostileNPC

	if split and ownMode == "exclude" then
		ConfigureGroup(container, MAIN_GROUP, filter, maxCount, NOT_FROM_PLAYERS)
	elseif split and not ownMode then
		ConfigureGroup(container, MAIN_GROUP, filter .. "|PLAYER", maxCount)
		ConfigureGroup(container, OTHERS_GROUP, filter .. "|!PLAYER", maxCount, NOT_FROM_PLAYERS)
		return
	else
		ConfigureGroup(container, MAIN_GROUP, filter, maxCount)
	end

	if container:HasAuraGroup(OTHERS_GROUP) or (harmful and Value(group, "hideOthers")) then
		ConfigureGroup(container, OTHERS_GROUP, filter, 0)
	end
end

local function ConfigureLayout(container)
	local group = container.group
	local point = FLIPPED[Value(group, "point")]
	local vertical = point:match("BOTTOM") or "TOP"
	local horizontal = point:match("RIGHT") or "LEFT"
	local size = ButtonSize(container.frame, group)
	local spacing = Spacing(container.frame, group, "spacing")
	local perRow = Value(group, "perRow")

	container:SetFlowLayoutAxis(Value(group, "vertical") and AnchorUtil.FlowLayoutAxis.Vertical
		or AnchorUtil.FlowLayoutAxis.Horizontal)
	container:SetFlowLayoutAnchorPoint(vertical .. horizontal)
	container:SetFlowLayoutGrowthDirection(
		horizontal == "RIGHT" and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,
		vertical == "BOTTOM" and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down)
	container:SetFlowLayoutMaximumLineSize(perRow * size + (perRow - 1) * spacing)
end

local FONT_KEYS = { COUNT_KEY, DURATION_KEY }
local GROUP_KEYS = { MAIN_GROUP, OTHERS_GROUP }

local function ButtonSignature(frame, group)
	local unit = frame.unitKey
	local harmful = Value(group, "type") == "HARMFUL"
	local parts = {
		ButtonSize(frame, group),
		ns:GetShadeSize(),
		Value(group, "cooldown"),
		Value(group, "edge"),
		table.concat(Value(group, "edgeColor"), ","),
		Value(group, "count"),
		Value(group, "duration"),
		Value(group, "bar") ~= "off" and Value(group, "bar") .. Value(group, "barHeight") .. ns:GetTexture(),
		Value(group, "bar") ~= "off" and Value(group, "barColorMode") .. table.concat(Value(group, "barColor"), ","),
		Value(group, "pandemic"),
		Value(group, "tooltip"),
		Value(group, "cancel") and unit == "player",
		harmful and Value(group, "border"),
		not harmful and Value(group, "stealable"),
	}

	for _, key in ipairs(FONT_KEYS) do
		parts[#parts + 1] = ns:GetTextFont(unit, key)
		parts[#parts + 1] = ns:GetTextFontSize(unit, key)
		parts[#parts + 1] = ns:GetTextOutline(unit, key)
		parts[#parts + 1] = ns:HasTextShadow(unit, key)
		parts[#parts + 1] = ns:IsTextSmooth(unit, key)
	end

	for index, part in ipairs(parts) do
		parts[index] = tostring(part)
	end

	return table.concat(parts, ":")
end

local function ResetContainer(_, container)
	container:SetEnabled(false)
	container:Hide()
	container:ClearAllPoints()
end

local function ConfigureButtons(container)
	for _, groupKey in ipairs(GROUP_KEYS) do
		for index = 1, container:GetAuraGroupFrameCount(groupKey) do
			ConfigureButton(container, container:GetAuraGroupFrame(groupKey, index))
		end
	end
end

local function IsHostile(frame)
	return not frame.auraFriendly
end

local function SwappedRoot(frame, groups)
	if not (IsHostile(frame) and ns:IsElementShown(frame.unitKey, SWAP_KEY)) then
		return
	end

	for _, root in ipairs(groups) do
		if not root.attach and Value(root, "type") == "HELPFUL" and Value(root, "shown") then
			for _, child in ipairs(groups) do
				if child.attach == root.id and Value(child, "type") == "HARMFUL" and Value(child, "shown") then
					return root, child
				end
			end
		end
	end
end

local function PlaceContainer(frame, container, group, parent)
	local point = Value(group, "point")
	local x, y = Value(group, "x"), Value(group, "y")
	local overlap = 2 * ns.BORDER_SHADOW + 1

	if point:match("BOTTOM") then
		y = y + overlap
	elseif point:match("TOP") then
		y = y - overlap
	elseif point == "RIGHT" then
		x = x - overlap
	elseif point == "LEFT" then
		x = x + overlap
	end

	container:ClearAllPoints()
	ns:SetPoint(container, FLIPPED[point], parent, point, x, y)
end

local function PlaceAuras(frame, groups)
	local containers = frame.auraContainers
	local root, child = SwappedRoot(frame, groups)
	local container, parent

	for _, group in ipairs(groups) do
		container = containers[GroupKey(group.id)]

		if container and container:IsShown() then
			parent = group.attach and containers[GroupKey(group.attach)]

			if group == child then
				PlaceContainer(frame, container, root, frame)
			elseif group == root then
				PlaceContainer(frame, container, child, containers[GroupKey(child.id)])
			else
				PlaceContainer(frame, container, group,
					parent and parent:IsShown() and parent or frame)
			end
		end
	end
end

local function UpdateUnitState(frame)
	local unit = frame.__unit
	local exists = unit and UnitExists(unit)
	local friendly = not not (exists and UnitIsFriend("player", unit))
	local hostileNPC = not not (exists and not friendly and not UnitIsPlayer(unit)
		and not UnitIsOtherPlayersPet(unit))
	local assist = not not (exists and UnitCanAssist("player", unit))
	local changed = friendly ~= frame.auraFriendly or hostileNPC ~= frame.auraHostileNPC
		or assist ~= frame.auraAssist

	frame.auraFriendly = friendly
	frame.auraHostileNPC = hostileNPC
	frame.auraAssist = assist

	return changed
end

local function ApplyAuraFrame(frame)
	local groups = Groups(frame.unitKey)
	local containers = frame.auraContainers or {}
	local wanted = {}
	local key, container, active, signature

	frame.auraContainers = containers
	frame.auraPool = frame.auraPool
		or CreateFramePool("AuraContainer", frame, "CustomAuraContainerTemplate", ResetContainer)
	UpdateUnitState(frame)

	for _, group in ipairs(groups) do
		key = GroupKey(group.id)

		if Value(group, "shown") then
			wanted[key] = true
			active = true
			signature = ButtonSignature(frame, group)
			container = containers[key]

			if not container then
				container = frame.auraPool:Acquire()
				container.frame = frame
				containers[key] = container
			end

			container.group = group

			if container.signature ~= signature and not ns:AreAurasSecret() then
				container.signature = signature
				ConfigureButtons(container)
			end

			ConfigureLayout(container)
			ConfigureFilters(container)

			if frame.__unit and container:GetUnit() ~= frame.__unit then
				container:SetUnit(frame.__unit)
			end

			container:SetEnabled(true)
			container:Show()
		end
	end

	for groupKey, other in next, containers do
		if not wanted[groupKey] then
			frame.auraPool:Release(other)
			containers[groupKey] = nil
		end
	end

	frame.aurasActive = active

	if active then
		frame:RegisterEvent("UNIT_FACTION", ns.RefreshAuraState)
	elseif frame.UNIT_FACTION then
		frame:UnregisterEvent("UNIT_FACTION", ns.RefreshAuraState)
	end

	PlaceAuras(frame, groups)
end

function ns:ApplyAuras(frame)
	if not ns:HasElement(frame.unitKey, AURA_SECTION) then
		return
	end

	if frame.aurasActive or #Groups(frame.unitKey) > 0 then
		ApplyAuraFrame(frame)
	end
end

function ns.RefreshAuraState(frame)
	if not (frame.aurasActive and frame.__unit) then
		return
	end

	local containers = frame.auraContainers
	local container

	if UpdateUnitState(frame) then
		ApplyAuraFrame(frame)
		return
	end

	for _, group in ipairs(Groups(frame.unitKey)) do
		container = containers[GroupKey(group.id)]

		if container and container:IsShown() then
			if container:GetUnit() ~= frame.__unit then
				container:SetUnit(frame.__unit)
			else
				container:UpdateAllAuras()
			end
		end
	end
end

function ns:AreAurasSecret()
	return aurasSecret or C_Secrets.ShouldAurasBeSecret()
end

function ns:ApplyAuraRestriction(restriction, state)
	if restriction == Enum.AddOnRestrictionType.Chat then
		return
	end

	aurasSecret = state ~= Enum.AddOnRestrictionState.Inactive or C_Secrets.ShouldAurasBeSecret()

	if not aurasSecret then
		ns:DeferMethod(ns, "UpdateAuras")
	end

	ns:RefreshOptionsWindow()
end
