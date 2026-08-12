local _, ns = ...
local oUF = ns.oUF

local LSM = LibStub("LibSharedMedia-3.0")

local DEFAULT_PROFILE = "Default"

local KNOWN_ROOT_KEYS = {
	profiles = true,
	profileKeys = true,
}

local function PruneUnknownKeys()
	for key in pairs(oUF_ManiaDB) do
		if not KNOWN_ROOT_KEYS[key] then
			oUF_ManiaDB[key] = nil
		end
	end
end

function ns:OnLoad()
	oUF_ManiaDB = oUF_ManiaDB or {}
	oUF_ManiaDB.profiles = oUF_ManiaDB.profiles or {}
	oUF_ManiaDB.profileKeys = oUF_ManiaDB.profileKeys or {}
	PruneUnknownKeys()

	local charKey = UnitName("player") .. " - " .. GetRealmName()
	local profileName = oUF_ManiaDB.profileKeys[charKey] or DEFAULT_PROFILE

	oUF_ManiaDB.profileKeys[charKey] = profileName
	oUF_ManiaDB.profiles[profileName] = oUF_ManiaDB.profiles[profileName] or {}
	ns.db = oUF_ManiaDB.profiles[profileName]

	oUF:RegisterStyle("oUF_Mania", ns.Style)
	oUF:SetActiveStyle("oUF_Mania")
end

oUF:RegisterInitCallback(function(frame)
	ns:OnFrameInitialized(frame)
end)

function ns:OnLogin()
	LSM.RegisterCallback(ns, "LibSharedMedia_Registered", function(_, mediaType)
		if mediaType == "font" or mediaType == "statusbar" then
			ns:ApplyMedia()
		end
	end)

	ns:RegisterEvent("UI_SCALE_CHANGED", ns.UpdatePixelGeometry)
	ns:RegisterEvent("DISPLAY_SIZE_CHANGED", ns.UpdatePixelGeometry)
	ns:RegisterEvent("PLAYER_ROLES_ASSIGNED", ns.UpdatePower)
	ns:RegisterEvent("GROUP_ROSTER_UPDATE", ns.UpdatePower)
	ns:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", ns.UpdatePower)
end

local INDICATOR_SIZE = 14
ns.INDICATOR_SIZE = INDICATOR_SIZE

local RESTING_SIZE = 20
ns.RESTING_SIZE = RESTING_SIZE

local OVERLAY_LEVEL = 5

ns.Defaults = {
	iconSize = 12,
	fontSize = 12,
	barColorMode = "class",
	powerColorMode = "blizzard",
	barCustomColor = { 1, 1, 1 },
	powerHeight = 10,

	units = {
		player = { width = 200, height = 46 },
		target = { width = 200, height = 46 },
		focus = { width = 160, height = 36 },
		targettarget = { width = 120, height = 28 },
		pet = { width = 120, height = 28 },
		party = { width = 150, height = 36, spacing = 6 },
		boss = { width = 160, height = 36, spacing = 30 },
	},
	unitFallback = { width = 160, height = 36 },

	elements = {
		castbarIcon = { anchor = { default = "LEFT", target = "RIGHT" } },
		name = {
			anchor = { default = "LEFT" },
			tag = { default = "[difficulty][mania:smartlevel<$ ][name]", pet = "[name]", focus = "[name]",
				boss = "[name]", targettarget = "[name]" },
		},
		health = {
			anchor = { default = "RIGHT" },
			tag = { default = "[mania:curhp]" },
		},
		custom1 = {
			anchor = { default = "CENTER" },
			offset = { 0, 12 },
			tag = { default = "[group][mania:leader][mania:assistant]" },
			hidden = { default = true },
		},
		custom2 = {
			anchor = { default = "CENTER" },
			offset = { 0, -12 },
			tag = { default = "[mania:combat][mania:resting][mania:pvp][mania:phase]" },
			hidden = { default = true },
		},
		custom3 = {
			anchor = { default = "CENTER" },
			offset = { 0, 36 },
			tag = { default = "" },
			hidden = { default = true },
		},
		custom4 = {
			anchor = { default = "CENTER" },
			offset = { 0, -36 },
			tag = { default = "" },
			hidden = { default = true },
		},
		custom5 = {
			anchor = { default = "CENTER" },
			offset = { 0, 0 },
			tag = { default = "" },
			hidden = { default = true },
		},
		resting = {
			anchor = { default = "TOPLEFT" },
			offset = { 3, 8 },
			size = { default = RESTING_SIZE },
			level = OVERLAY_LEVEL,
		},
		leader = {
			anchor = { default = "TOPLEFT" },
			offset = { 22, 4 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		assistant = {
			anchor = { default = "TOPLEFT" },
			offset = { 36, 4 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		raidrole = {
			anchor = { default = "TOPLEFT" },
			offset = { 50, 4 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		raidtarget = {
			anchor = { default = "TOP" },
			offset = { 0, 5 },
			size = { default = 20 },
			level = OVERLAY_LEVEL,
		},
		combat = {
			anchor = { default = "BOTTOM" },
			offset = { 0, -5 },
			size = { default = 16, pet = 14, targettarget = 14 },
			level = OVERLAY_LEVEL,
			hidden = { default = false, party = true, boss = true },
		},
		phase = {
			anchor = { default = "CENTER" },
			offset = { 0, 16 },
			size = { default = 32, pet = 22, targettarget = 22 },
			level = OVERLAY_LEVEL,
		},
		grouprole = {
			anchor = { default = "LEFT" },
			offset = { -3, 0 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		quest = {
			anchor = { default = "RIGHT" },
			offset = { 6, 0 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		pvp = {
			anchor = { default = "BOTTOMLEFT" },
			offset = { 0, -4 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		pvpclass = {
			anchor = { default = "BOTTOMRIGHT" },
			offset = { 0, -4 },
			size = { default = INDICATOR_SIZE },
			level = OVERLAY_LEVEL,
		},
		readycheck = {
			anchor = { default = "CENTER" },
			offset = { 0, 0 },
			size = { default = 32, targettarget = 18 },
			level = OVERLAY_LEVEL,
		},
		resurrect = {
			anchor = { default = "CENTER" },
			offset = { -18, 0 },
			size = { default = 32, pet = 22, targettarget = 22 },
			level = OVERLAY_LEVEL,
		},
		summon = {
			anchor = { default = "CENTER" },
			offset = { 18, 0 },
			size = { default = 32, pet = 22, targettarget = 22 },
			level = OVERLAY_LEVEL,
		},
		castbar = { size = { default = 16 } },
		castbarWidth = { size = { default = 0 } },
		threat = { size = { default = 3 }, level = 0 },
	},
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
	local defaults = ns.Defaults.units[key] or ns.Defaults.unitFallback
	return defaults.width, defaults.height, ns.Defaults.powerHeight
end

function ns:GetUnitSizes(key)
	local width, height, power = ns:GetUnitSizeDefaults(key)
	local db = ns.db
	local stored = db.units and db.units[key]

	if stored then
		width = stored.width or width
		height = stored.height or height
		power = stored.power or power
	end

	return width, height, power
end

local function Store(key, field, value)
	local db = ns.db

	db.units = db.units or {}
	db.units[key] = db.units[key] or {}
	db.units[key][field] = value
end

function ns:IsSyncEnabled(name)
	local db = ns.db

	return not not (db.sync and db.sync[name])
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
	local db = ns.db

	db.sync = db.sync or {}
	db.sync[name] = enabled

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
	local db = ns.db
	local stored = db.units and db.units[key]
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
	local db = ns.db
	local stored = db.units and db.units[key]
	return not not (stored and stored.healerPower)
end

function ns:SetHealerPowerOnly(key, enabled)
	Store(key, "healerPower", enabled)
	ns:UpdatePower()
end

function ns:IsHidingFriendlyNPCPower(key)
	local db = ns.db
	local stored = db.units and db.units[key]
	return not not (stored and stored.hideFriendlyNPCPower)
end

function ns:SetHideFriendlyNPCPower(key, enabled)
	Store(key, "hideFriendlyNPCPower", enabled)
	ns:UpdatePower()
end

function ns:GetUnitOffset(key)
	local db = ns.db
	local stored = db.units and db.units[key]

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
	return ns.Defaults.units[key] and ns.Defaults.units[key].spacing ~= nil
end

function ns:GetUnitSpacing(key)
	local db = ns.db
	local stored = db.units and db.units[key]
	local defaults = ns.Defaults.units[key]
	return stored and stored.spacing or (defaults and defaults.spacing)
end

function ns:SetUnitSpacing(key, value)
	Store(key, "spacing", value)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsPartyVertical()
	local db = ns.db
	local stored = db.units and db.units.party
	return not stored or stored.vertical ~= false
end

function ns:SetPartyVertical(vertical)
	Store("party", "vertical", vertical)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsPartyPlayerShown()
	local db = ns.db
	local stored = db.units and db.units.party
	return not not (stored and stored.showPlayer)
end

function ns:SetPartyPlayerShown(shown)
	Store("party", "showPlayer", shown)
	ns:DeferMethod(ns, "ApplyGroupLayout")
end

function ns:IsUnitEnabled(key)
	local db = ns.db
	local stored = db.units and db.units[key]
	return not stored or stored.enabled ~= false
end

function ns:SetUnitEnabled(key, enabled)
	Store(key, "enabled", enabled)
end

function ns:GetUnitSize(unit)
	local width, height = ns:GetUnitSizes(ns:GetUnitKey(unit))
	return width, height
end
