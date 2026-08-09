local _, ns = ...
local oUF = ns.oUF

local LSM = LibStub("LibSharedMedia-3.0")

oUF:RegisterStyle("ManiaUF", ns.Style)
oUF:SetActiveStyle("ManiaUF")

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
