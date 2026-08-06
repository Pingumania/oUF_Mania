local _, ns = ...
local oUF = ns.oUF

oUF:RegisterStyle("ManiaUF", ns.Style)
oUF:SetActiveStyle("ManiaUF")

function ns:OnLogin()
	ns:RegisterOptionCallback("fontSize", function()
		ns:ApplyMedia()
	end)

	ns:RegisterEvent("UI_SCALE_CHANGED", ns.UpdatePixelGeometry)
	ns:RegisterEvent("DISPLAY_SIZE_CHANGED", ns.UpdatePixelGeometry)
end
