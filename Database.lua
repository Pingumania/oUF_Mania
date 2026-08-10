local _, ns = ...

ns.DEFAULT_ICON_SIZE = 12
ns.DEFAULT_FONT_SIZE = 12

local INDICATOR_SIZE = 14
ns.INDICATOR_SIZE = INDICATOR_SIZE

local RESTING_SIZE = 20
ns.RESTING_SIZE = RESTING_SIZE

local OVERLAY_LEVEL = 5

ns.DEFAULT_ANCHORS = {
	castbarIcon = { default = "LEFT", target = "RIGHT" },
	name = { default = "LEFT" },
	health = { default = "RIGHT" },
	text1 = { default = "CENTER" },
	text2 = { default = "CENTER" },
	resting = { default = "TOPLEFT" },
	leader = { default = "TOPLEFT" },
	assistant = { default = "TOPLEFT" },
	raidrole = { default = "TOPLEFT" },
	raidtarget = { default = "TOP" },
	combat = { default = "BOTTOM" },
	phase = { default = "CENTER" },
	grouprole = { default = "LEFT" },
	quest = { default = "RIGHT" },
	pvp = { default = "BOTTOMLEFT" },
	pvpclass = { default = "BOTTOMRIGHT" },
	readycheck = { default = "CENTER" },
	resurrect = { default = "CENTER" },
	summon = { default = "CENTER" },
}

ns.DEFAULT_OFFSETS = {
	text1 = { 0, 12 },
	text2 = { 0, -12 },
	resting = { 3, 8 },
	leader = { 22, 4 },
	assistant = { 36, 4 },
	raidrole = { 50, 4 },
	raidtarget = { 0, 5 },
	combat = { 0, -5 },
	phase = { 0, 16 },
	grouprole = { -3, 0 },
	quest = { 6, 0 },
	pvp = { 0, -4 },
	pvpclass = { 0, -4 },
	readycheck = { 0, 0 },
	resurrect = { -18, 0 },
	summon = { 18, 0 },
}

ns.DEFAULT_ELEMENT_SIZES = {
	castbar = { default = 16 },
	castbarWidth = { default = 0 },
	resting = { default = RESTING_SIZE },
	threat = { default = 3 },
	raidtarget = { default = 20 },
	readycheck = { default = 32, targettarget = 18 },
	leader = { default = INDICATOR_SIZE },
	assistant = { default = INDICATOR_SIZE },
	raidrole = { default = INDICATOR_SIZE },
	combat = { default = 16, pet = 14, targettarget = 14 },
	phase = { default = 32, pet = 22, targettarget = 22 },
	grouprole = { default = INDICATOR_SIZE },
	quest = { default = INDICATOR_SIZE },
	pvp = { default = INDICATOR_SIZE },
	pvpclass = { default = INDICATOR_SIZE },
	resurrect = { default = 32, pet = 22, targettarget = 22 },
	summon = { default = 32, pet = 22, targettarget = 22 },
}

ns.DEFAULT_LEVELS = {
	resting = OVERLAY_LEVEL,
	threat = 0,
	leader = OVERLAY_LEVEL,
	assistant = OVERLAY_LEVEL,
	raidrole = OVERLAY_LEVEL,
	raidtarget = OVERLAY_LEVEL,
	combat = OVERLAY_LEVEL,
	phase = OVERLAY_LEVEL,
	grouprole = OVERLAY_LEVEL,
	quest = OVERLAY_LEVEL,
	pvp = OVERLAY_LEVEL,
	pvpclass = OVERLAY_LEVEL,
	readycheck = OVERLAY_LEVEL,
	resurrect = OVERLAY_LEVEL,
	summon = OVERLAY_LEVEL,
}

ns.DEFAULT_TAGS = {
	name = { default = "[difficulty][maniauf:smartlevel<$ ][name]", pet = "[name]", focus = "[name]",
		boss = "[name]", targettarget = "[name]" },
	health = { default = "[maniauf:curhp]" },
	text1 = { default = "[maniauf:leader][maniauf:assistant][maniauf:role][maniauf:raidtarget]" },
	text2 = { default = "[maniauf:combat][maniauf:resting][maniauf:pvp][maniauf:phase]" },
}

ns.HIDDEN_BY_DEFAULT = {
	text1 = { default = true },
	text2 = { default = true },
	combat = { default = false, party = true, boss = true },
}

ns.ELEMENT_UNITS = {
	castbar = { player = true, target = true, focus = true, boss = true },
	resting = { player = true },
	readycheck = { player = true, target = true, targettarget = true, focus = true, party = true },
	leader = { player = true, target = true, targettarget = true, focus = true, party = true },
	assistant = { player = true, target = true, targettarget = true, focus = true, party = true },
	raidrole = { player = true, target = true, targettarget = true, focus = true, party = true },
	grouprole = { player = true, target = true, targettarget = true, focus = true, party = true },
	summon = { player = true, target = true, targettarget = true, focus = true, party = true },
	quest = { target = true, targettarget = true, focus = true, boss = true },
}

ns.PREVIEWABLE = {
	threat = true,
	resting = true,
	castbar = true,
	leader = true,
	assistant = true,
	raidrole = true,
	raidtarget = true,
	combat = true,
	phase = true,
	grouprole = true,
	quest = true,
	pvp = true,
	pvpclass = true,
	readycheck = true,
	resurrect = true,
	summon = true,
}

local SIZE_ORDER = { "targettarget", "player", "target", "focus", "pet", "party", "boss" }

ns.UNIT_KEYS = { "player", "target", "targettarget", "focus", "pet", "party", "boss" }

local DEFAULT_SIZES = {
	player = { 200, 46 },
	target = { 200, 46 },
	focus = { 160, 36 },
	targettarget = { 120, 28 },
	pet = { 120, 28 },
	party = { 150, 36 },
	boss = { 160, 36 },
}

local DEFAULT_SPACINGS = {
	party = 6,
	boss = 30,
}

local DEFAULT_SIZE = { 160, 36 }
local DEFAULT_POWER_HEIGHT = 10

local MIRROR_SYNC = "mirrorPosition"
local MIRROR_LEADER = "player"

local MIRROR_PAIR = {
	player = "target",
	target = "player",
}

local HIDDEN_POWER_UNITS = {
	pet = true,
	focus = true,
	targettarget = true,
}

local SYNC_GROUPS = {
	playerParty = { "player", "party" },
	smallFrames = { "pet", "focus", "targettarget" },
}

function ns:GetUnitKey(unit)
	for _, prefix in ipairs(SIZE_ORDER) do
		if unit:match("^" .. prefix) then
			return prefix
		end
	end
end

function ns:GetUnitSizeDefaults(key)
	local defaults = DEFAULT_SIZES[key] or DEFAULT_SIZE
	return defaults[1], defaults[2], DEFAULT_POWER_HEIGHT
end

function ns:GetUnitSizes(key)
	local width, height, power = ns:GetUnitSizeDefaults(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]

	if stored then
		width = stored.width or width
		height = stored.height or height
		power = stored.power or power
	end

	return width, height, power
end

local function Store(key, field, value)
	ManiaUFDB.units = ManiaUFDB.units or {}
	ManiaUFDB.units[key] = ManiaUFDB.units[key] or {}
	ManiaUFDB.units[key][field] = value
end

function ns:IsSyncEnabled(name)
	return not not (ManiaUFDB.sync and ManiaUFDB.sync[name])
end

function ns:GetSyncedKeys(key)
	local members

	for name, units in next, SYNC_GROUPS do
		if ns:IsSyncEnabled(name) then
			for _, member in ipairs(units) do
				if member == key then
					members = units
					break
				end
			end
		end
	end

	return members
end

function ns:SetUnitSize(key, field, value)
	local members = ns:GetSyncedKeys(key)

	if members then
		for _, member in ipairs(members) do
			Store(member, field, value)
		end
	else
		Store(key, field, value)
	end

	ns:DeferMethod(ns, "UpdatePixelGeometry", not members and key or nil)
end

function ns:SetSyncEnabled(name, enabled)
	ManiaUFDB.sync = ManiaUFDB.sync or {}
	ManiaUFDB.sync[name] = enabled

	if name == MIRROR_SYNC then
		if enabled then
			local x, y = ns:GetUnitOffset(MIRROR_LEADER)

			Store(MIRROR_PAIR[MIRROR_LEADER], "posX", -x)
			Store(MIRROR_PAIR[MIRROR_LEADER], "posY", y)
		end

		ns:DeferMethod(ns, "UpdatePositions")
		return
	end

	if enabled then
		local units = SYNC_GROUPS[name]
		local width, height, power = ns:GetUnitSizes(units[1])

		for index = 2, #units do
			Store(units[index], "width", width)
			Store(units[index], "height", height)
			Store(units[index], "power", power)
		end
	end

	ns:DeferMethod(ns, "UpdatePixelGeometry")
end

function ns:IsUnitPowerShown(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]
	local shown = stored and stored.showPower

	if shown == nil then
		return not HIDDEN_POWER_UNITS[key]
	end

	return shown
end

function ns:SetUnitPowerEnabled(key, enabled)
	Store(key, "showPower", enabled)
	ns:UpdatePower()
end

function ns:IsHealerPowerOnly(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]
	return not not (stored and stored.healerPower)
end

function ns:SetHealerPowerOnly(key, enabled)
	Store(key, "healerPower", enabled)
	ns:UpdatePower()
end

function ns:GetUnitOffset(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]

	if not stored then
		return 0, 0
	end

	return stored.posX or 0, stored.posY or 0
end

function ns:SetUnitOffset(key, axis, value)
	local field = axis == "x" and "posX" or "posY"
	local mirrored = ns:IsSyncEnabled(MIRROR_SYNC) and MIRROR_PAIR[key]

	Store(key, field, value)

	if mirrored then
		Store(mirrored, field, axis == "x" and -value or value)
	end

	ns:DeferMethod(ns, "UpdatePositions")
end

function ns:HasUnitSpacing(key)
	return DEFAULT_SPACINGS[key] ~= nil
end

function ns:GetUnitSpacing(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]
	return stored and stored.spacing or DEFAULT_SPACINGS[key]
end

function ns:SetUnitSpacing(key, value)
	Store(key, "spacing", value)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsPartyVertical()
	local stored = ManiaUFDB.units and ManiaUFDB.units.party
	return not stored or stored.vertical ~= false
end

function ns:SetPartyVertical(vertical)
	Store("party", "vertical", vertical)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsPartyPlayerShown()
	local stored = ManiaUFDB.units and ManiaUFDB.units.party
	return not not (stored and stored.showPlayer)
end

function ns:SetPartyPlayerShown(shown)
	Store("party", "showPlayer", shown)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsUnitEnabled(key)
	local stored = ManiaUFDB.units and ManiaUFDB.units[key]
	return not stored or stored.enabled ~= false
end

function ns:SetUnitEnabled(key, enabled)
	Store(key, "enabled", enabled)
end

function ns:GetUnitSize(unit)
	local width, height = ns:GetUnitSizes(ns:GetUnitKey(unit))
	return width, height
end
