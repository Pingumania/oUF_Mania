local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "TOPLEFT", UIParent, "TOPLEFT", 30, -220 }
local SPACING = 4
local GROUPS = "1,2,3,4,5,6,7,8"
local UNITS_PER_COLUMN = 5

function ns:OnLogin()
	local width, height = ns:GetUnitSize("raid")

	local raid = oUF:SpawnHeader("ManiaUFRaid", nil,
		"showRaid", true,
		"showParty", false,
		"showSolo", false,
		"groupFilter", GROUPS,
		"groupBy", "GROUP",
		"groupingOrder", GROUPS,
		"sortMethod", "INDEX",
		"maxColumns", 8,
		"unitsPerColumn", UNITS_PER_COLUMN,
		"columnSpacing", SPACING,
		"columnAnchorPoint", "LEFT",
		"point", "TOP",
		"yOffset", -SPACING,
		"oUF-initialConfigFunction", ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
		]]):format(width, height)
	)

	ns:SetPoint(raid, unpack(ANCHOR))
	raid:SetVisibility("raid")
end
