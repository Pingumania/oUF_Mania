local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "BOTTOMRIGHT", "ManiaUFPlayer", "TOPRIGHT", 0, 6 }

function ns:OnLogin()
	local pet = oUF:Spawn("pet", "ManiaUFPet")
	ns:SetPoint(pet, unpack(ANCHOR))
end
