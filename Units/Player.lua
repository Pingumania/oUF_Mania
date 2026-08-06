local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "BOTTOM", UIParent, "BOTTOM", -260, 280 }

function ns:OnLogin()
	local player = oUF:Spawn("player", "ManiaUFPlayer")
	ns:SetPoint(player, unpack(ANCHOR))
end
