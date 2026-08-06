local _, ns = ...
local oUF = ns.oUF

local ANCHOR = { "RIGHT", UIParent, "RIGHT", -60, 160 }
local SPACING = 30

function ns:OnLogin()
	local previous

	for index = 1, MAX_BOSS_FRAMES do
		local boss = oUF:Spawn("boss" .. index, "ManiaUFBoss" .. index)

		if previous then
			ns:SetPoint(boss, "TOP", previous, "BOTTOM", 0, -SPACING)
		else
			ns:SetPoint(boss, unpack(ANCHOR))
		end

		previous = boss
	end
end
