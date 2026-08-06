local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "TOPLEFT", UIParent, "TOPLEFT", 30, -220 }
local SPACING = 6

function ns:OnLogin()
	local width, height = ns:GetUnitSize("party")

	local party = oUF:SpawnHeader("ManiaUFParty", nil,
		"showParty", true,
		"showPlayer", false,
		"showSolo", false,
		"point", "TOP",
		"yOffset", -SPACING,
		"oUF-initialConfigFunction", ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
		]]):format(width, height)
	)

	ns:SetPoint(party, unpack(ANCHOR))
	party:SetVisibility("party")
end
