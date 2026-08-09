local _, ns = ...

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
