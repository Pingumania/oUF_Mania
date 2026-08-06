local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "BOTTOMLEFT", "ManiaUFTarget", "TOPLEFT", 0, 6 }

function ns:OnLogin()
	local targetOfTarget = oUF:Spawn("targettarget", "ManiaUFTargetTarget")
	ns:SetPoint(targetOfTarget, unpack(ANCHOR))
end
