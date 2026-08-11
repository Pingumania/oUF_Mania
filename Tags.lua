local _, ns = ...
local oUF = ns.oUF

local issecretvalue = issecretvalue

local BREAKPOINTS = {
	{
		breakpoint = 1e12,
		abbreviation = "B", -- B
		significandDivisor = 1e10,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e11,
		abbreviation = "B", -- B
		significandDivisor = 1e9,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e10,
		abbreviation = "B", -- B
		significandDivisor = 1e8,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e9,
		abbreviation = "B", -- B
		significandDivisor = 1e7,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e8,
		abbreviation = "M", -- M
		significandDivisor = 1e6,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e7,
		abbreviation = "M", -- M
		significandDivisor = 1e5,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e6,
		abbreviation = "M", -- M
		significandDivisor = 1e4,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e5,
		abbreviation = "K", -- K
		significandDivisor = 1000,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e4,
		abbreviation = "K", -- K
		significandDivisor = 100,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	}
}

local options = { breakpointData = BREAKPOINTS }
local resolved

local function FormatNumber(value)
	if not resolved then
		resolved = true

		if C_AbbreviateConfig and C_AbbreviateConfig.CreateAbbreviateConfig then
			local ok, config = pcall(C_AbbreviateConfig.CreateAbbreviateConfig, BREAKPOINTS)

			if ok and config then
				options = { config = config }
			end
		end
	end

	return AbbreviateNumbers(value, options)
end

ns.FormatNumber = FormatNumber

oUF.Tags.Methods["mania:curhp"] = function(unit)
	return FormatNumber(UnitHealth(unit))
end

oUF.Tags.Events["mania:curhp"] = "UNIT_HEALTH UNIT_MAXHEALTH"

oUF.Tags.Methods["mania:maxhp"] = function(unit)
	return FormatNumber(UnitHealthMax(unit))
end

oUF.Tags.Events["mania:maxhp"] = "UNIT_MAXHEALTH"

oUF.Tags.Methods["mania:curpp"] = function(unit)
	return FormatNumber(UnitPower(unit))
end

oUF.Tags.Events["mania:curpp"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"

oUF.Tags.Methods["mania:maxpp"] = function(unit)
	return FormatNumber(UnitPowerMax(unit))
end

oUF.Tags.Events["mania:maxpp"] = "UNIT_MAXPOWER"

local FACTION_ATLASES = {
	Alliance = "questlog-questtypeicon-alliance",
	Horde = "questlog-questtypeicon-horde",
}

local RAID_MARKER_SHEET = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local RAID_MARKER_COLUMNS = 4
local RESTING_SHEET = [[Interface\CharacterFrame\UI-StateIcon]]

function ns:GetIconTagSize()
	return oUF_ManiaDB.iconSize or ns.DEFAULT_ICON_SIZE
end

function ns:SetIconTagSize(size)
	oUF_ManiaDB.iconSize = size
	ns:UpdateTags()
end

local smartLevel = oUF.Tags.Methods["smartlevel"]

oUF.Tags.Methods["mania:smartlevel"] = function(unit)
	if UnitClassification(unit) ~= "worldboss"
		and UnitEffectiveLevel(unit) >= (GetMaxPlayerLevel() or 0) then
		return ""
	end

	return smartLevel(unit)
end

oUF.Tags.Events["mania:smartlevel"] = oUF.Tags.Events["smartlevel"]

local function Icon(atlas)
	local size = ns:GetIconTagSize()
	return CreateAtlasMarkup(atlas, size, size)
end

local function IconTag(name, event, Read)
	oUF.Tags.Methods["mania:" .. name] = function(unit)
		if issecretvalue(unit) then
			return ""
		end

		return Read(unit) or ""
	end

	oUF.Tags.Events["mania:" .. name] = event
end

IconTag("leader", "UNIT_FLAGS PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE", function(unit)
	if UnitIsGroupLeader(unit) then
		return Icon("UI-HUD-UnitFrame-Player-Group-LeaderIcon")
	end
end)

IconTag("assistant", "GROUP_ROSTER_UPDATE", function(unit)
	if UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit) then
		return Icon("UI-HUD-UnitFrame-Player-Group-GuideIcon")
	end
end)

IconTag("role", "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE", function(unit)
	local atlas = ns:GetRoleIcon(UnitGroupRolesAssigned(unit))

	if atlas then
		return Icon(atlas)
	end
end)

IconTag("combat", "UNIT_FLAGS", function(unit)
	if UnitAffectingCombat(unit) then
		return Icon("UI-HUD-UnitFrame-Player-CombatIcon")
	end
end)

IconTag("resting", "PLAYER_UPDATE_RESTING", function(unit)
	if unit == "player" and IsResting() then
		local size = ns:GetIconTagSize()
		return ("|T%s:%d:%d:0:0:64:64:0:32:0:27|t"):format(RESTING_SHEET, size, size)
	end
end)

IconTag("pvp", "UNIT_FACTION", function(unit)
	if not UnitIsPVP(unit) then
		return
	end

	local atlas = FACTION_ATLASES[UnitFactionGroup(unit)]

	if atlas then
		return Icon(atlas)
	end
end)

IconTag("quest", "UNIT_CLASSIFICATION_CHANGED", function(unit)
	if UnitIsQuestBoss(unit) then
		return Icon(ns:GetQuestIconStyle())
	end
end)

IconTag("phase", "UNIT_PHASE", function(unit)
	if UnitPhaseReason(unit) then
		return Icon("RaidFrame-Icon-Phasing")
	end
end)

IconTag("resurrect", "INCOMING_RESURRECT_CHANGED", function(unit)
	if UnitHasIncomingResurrection(unit) then
		return Icon("RaidFrame-Icon-Rez")
	end
end)

IconTag("summon", "INCOMING_SUMMON_CHANGED", function(unit)
	if C_IncomingSummon.HasIncomingSummon(unit) then
		return Icon("RaidFrame-Icon-SummonPending")
	end
end)

IconTag("raidtarget", "RAID_TARGET_UPDATE", function(unit)
	local index = GetRaidTargetIndex(unit)

	if not index then
		return
	end

	local size = ns:GetIconTagSize()
	local column = (index - 1) % RAID_MARKER_COLUMNS
	local row = math.floor((index - 1) / RAID_MARKER_COLUMNS)
	local left = column * 64
	local top = row * 64

	return ("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t"):format(RAID_MARKER_SHEET, size, size,
		left, left + 64, top, top + 64)
end)
