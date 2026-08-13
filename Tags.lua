local _, ns = ...
local oUF = ns.oUF

local issecretvalue = issecretvalue

local BREAKPOINTS = {
	{
		breakpoint = 1e12,
		abbreviation = "B",
		significandDivisor = 1e7,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e11,
		abbreviation = "B",
		significandDivisor = 1e9,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e10,
		abbreviation = "B",
		significandDivisor = 1e8,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e9,
		abbreviation = "B",
		significandDivisor = 1e7,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e8,
		abbreviation = "M",
		significandDivisor = 1e6,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e7,
		abbreviation = "M",
		significandDivisor = 1e5,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e6,
		abbreviation = "M",
		significandDivisor = 1e4,
		fractionDivisor = 100,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e5,
		abbreviation = "K",
		significandDivisor = 1000,
		fractionDivisor = 1,
		abbreviationIsGlobal = false,
	},
	{
		breakpoint = 1e4,
		abbreviation = "K",
		significandDivisor = 100,
		fractionDivisor = 10,
		abbreviationIsGlobal = false,
	}
}

local options = { config = CreateAbbreviateConfig(BREAKPOINTS) }

local function FormatNumber(value)
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

local RAID_MARKER_SHEET = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local RAID_MARKER_COLUMNS = 4
local RESTING_SHEET = [[Interface\CharacterFrame\UI-StateIcon]]

function ns:GetIconTagSize()
	return ns.db.iconSize or ns.Defaults.iconSize
end

function ns:SetIconTagSize(size)
	ns.db.iconSize = size
	ns:UpdateTags()
end

oUF.Tags.Methods["mania:reset"] = function()
	return "|r"
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

local function ReadLeaderIcon(unit)
	if UnitIsGroupLeader(unit) then
		return Icon("UI-HUD-UnitFrame-Player-Group-LeaderIcon")
	end
end

local function ReadAssistantIcon(unit)
	if UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit) then
		return Icon("UI-HUD-UnitFrame-Player-Group-GuideIcon")
	end
end

local function ReadRoleIcon(unit)
	local atlas = ns:GetRoleIcon(UnitGroupRolesAssigned(unit))

	if atlas then
		return Icon(atlas)
	end
end

local function ReadCombatIcon(unit)
	if UnitAffectingCombat(unit) then
		return Icon("UI-HUD-UnitFrame-Player-CombatIcon")
	end
end

local function ReadRestingIcon(unit)
	if unit == "player" and IsResting() then
		local size = ns:GetIconTagSize()
		return ("|T%s:%d:%d:0:0:64:64:0:32:0:27|t"):format(RESTING_SHEET, size, size)
	end
end

local function ReadPvPIcon(unit)
	if not UnitIsPVP(unit) then
		return
	end

	local atlas = ns:GetPvPIcon(UnitFactionGroup(unit))

	if atlas then
		return Icon(atlas)
	end
end

local function ReadQuestIcon(unit)
	if UnitIsQuestBoss(unit) then
		return Icon(ns:GetQuestIconStyle())
	end
end

local function ReadPhaseIcon(unit)
	if UnitPhaseReason(unit) then
		return Icon("RaidFrame-Icon-Phasing")
	end
end

local function ReadResurrectIcon(unit)
	if UnitHasIncomingResurrection(unit) then
		return Icon("RaidFrame-Icon-Rez")
	end
end

local function ReadSummonIcon(unit)
	if C_IncomingSummon.HasIncomingSummon(unit) then
		return Icon("RaidFrame-Icon-SummonPending")
	end
end

local function ReadRaidTargetIcon(unit)
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
end

IconTag("leader", "UNIT_FLAGS PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE", ReadLeaderIcon)
IconTag("assistant", "GROUP_ROSTER_UPDATE", ReadAssistantIcon)
IconTag("role", "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE", ReadRoleIcon)
IconTag("combat", "UNIT_FLAGS", ReadCombatIcon)
IconTag("resting", "PLAYER_UPDATE_RESTING", ReadRestingIcon)
IconTag("pvp", "UNIT_FACTION", ReadPvPIcon)
IconTag("quest", "UNIT_CLASSIFICATION_CHANGED", ReadQuestIcon)
IconTag("phase", "UNIT_PHASE", ReadPhaseIcon)
IconTag("resurrect", "INCOMING_RESURRECT_CHANGED", ReadResurrectIcon)
IconTag("summon", "INCOMING_SUMMON_CHANGED", ReadSummonIcon)
IconTag("raidtarget", "RAID_TARGET_UPDATE", ReadRaidTargetIcon)
