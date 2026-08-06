local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "BOTTOM", UIParent, "BOTTOM", 260, 280 }

function ns:OnLogin()
	local target = oUF:Spawn("target", "ManiaUFTarget")
	ns:SetPoint(target, unpack(ANCHOR))
end
