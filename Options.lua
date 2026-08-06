local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

ns:RegisterSettings("ManiaUFDB", {
	{
		type = "custom",
		title = "Bar texture",
		tooltip = "The texture the health, power and cast bars are drawn with.",
		createControl = function(rowFrame)
			return ns:CreateMediaDropdown(rowFrame, "statusbar", function()
				return ManiaUFDB.texture or LSM:GetDefault("statusbar")
			end, function(name)
				ManiaUFDB.texture = name
				ns:ApplyMedia()
			end)
		end,
		onDefaults = function()
			ManiaUFDB.texture = nil
			ns:ApplyMedia()
		end,
	},
	{
		type = "custom",
		title = "Font",
		tooltip = "The font all unit frame text is drawn with.",
		createControl = function(rowFrame)
			return ns:CreateMediaDropdown(rowFrame, "font", function()
				return ManiaUFDB.font or LSM:GetDefault("font")
			end, function(name)
				ManiaUFDB.font = name
				ns:ApplyMedia()
			end)
		end,
		onDefaults = function()
			ManiaUFDB.font = LSM:GetDefault("font")
			ns:ApplyMedia()
		end,
	},
	{
		key = "fontSize",
		type = "slider",
		title = "Font size",
		default = 12,
		minValue = 8,
		maxValue = 20,
	},
})

ns:RegisterSettingsSlash("/maniauf")
