local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local issecretvalue = issecretvalue

local FONT_SIZE_MIN = 8
local FONT_SIZE_MAX = 20

local PREVIEW_UNIT = "player"
local SPARK_ATLAS = "ui-castingbar-pip-2x"
local SPARK_RATIO = 0.4
local ICON_ZOOM = 0.08

local SWING_TIMER_KEY = "swingtimer"
local SWING_COMBAT_KEY = "swingtimerCombat"
local SWING_TIME_KEY = "swingtimerTime"
local SWING_SEPARATE_KEY = "swingtimerSeparate"
local SWING_GAP_KEY = "swingtimerGap"
local SWING_BAR_KEYS = { "MainHand", "OffHand", "Ranged" }

ns.SWING_BAR_KEYS = SWING_BAR_KEYS

local PREDICTION_LEVEL = 1
local ABSORB_LEVEL = 2
local HEALTH_OVERLAY_LEVEL = 3
local OVER_INDICATOR_WIDTH = 6
local OVER_INDICATOR_ALPHA = 0.8
local MAX_HEALTH_LOSS = 0.95

local SMOOTHING = Enum.StatusBarInterpolation.ExponentialEaseOut
local SMOOTHED_BARS = { "Health", "Power", "AdditionalPower", "Stagger" }

local styled = setmetatable({}, { __mode = "k" })

ns.TEXT_PADDING = 4

function ns:GetFontFile()
	return LSM:Fetch("font", ns.db.font or LSM:GetDefault("font"))
end

function ns:GetTexture()
	return LSM:Fetch("statusbar", ns.db.texture or ns.Defaults.texture)
end

function ns:GetFontSize()
	return ns.db.fontSize or ns.Defaults.fontSize
end

function ns:GetFontSizeRange()
	return FONT_SIZE_MIN, FONT_SIZE_MAX
end

local BAR_COLOR_MODES = {
	{ value = "class", label = "Class color" },
	{ value = "blizzard", label = "Blizzard (default)" },
	{ value = "custom", label = "Custom color" },
}

local POWER_COLOR_MODES = {
	{ value = "class", label = "Class color" },
	{ value = "blizzard", label = "Blizzard (default)" },
}

function ns:GetBarColorModes()
	return BAR_COLOR_MODES
end

function ns:GetPowerColorModes()
	return POWER_COLOR_MODES
end

function ns:GetHealthColorMode()
	return ns.db.healthColorMode or ns.Defaults.barColorMode
end

function ns:GetHealthCustomColor()
	local color = ns.db.healthCustomColor or ns.Defaults.barCustomColor
	return color[1], color[2], color[3]
end

function ns:GetPowerColorMode()
	return ns.db.powerColorMode or ns.Defaults.powerColorMode
end

local function HealthPostUpdateColor(element)
	if ns:GetHealthColorMode() == "custom" then
		element:SetStatusBarColor(ns:GetHealthCustomColor())
	end
end

function ns:ApplyHealthWidth(frame, boxWidth)
	boxWidth = boxWidth or frame.healthBox:GetWidth()

	if not boxWidth or boxWidth <= 0 then
		return
	end

	ns:SetWidth(frame.Health, boxWidth * (1 - (frame.healthLossPerc or 0)))
end

local function HealthPostUpdate(element, _, _, _, lossPerc)
	local frame = element.__owner

	lossPerc = math.max(0, math.min(lossPerc or 0, MAX_HEALTH_LOSS))

	if frame.healthLossPerc == lossPerc then
		return
	end

	frame.healthLossPerc = lossPerc
	ns:ApplyHealthWidth(frame)
end

local function ApplyHealthColorFlags(frame)
	local health = frame.Health
	local mode = ns:GetHealthColorMode()

	health.colorClass = mode == "class"
	health.colorReaction = mode == "class"
	health.colorHealth = mode ~= "class"
end

local function ApplyPowerColorFlags(frame)
	local power = frame.Power

	if not power then
		return
	end

	local mode = ns:GetPowerColorMode()

	power.colorClass = mode == "class"
	power.colorPower = mode == "blizzard"
end

function ns:ApplyHealthColorMode()
	for frame in next, styled do
		ApplyHealthColorFlags(frame)
		frame.Health:ForceUpdate()
	end
end

function ns:ApplyPowerColorMode()
	for frame in next, styled do
		ApplyPowerColorFlags(frame)

		if frame.Power then
			frame.Power:ForceUpdate()
		end
	end
end

function ns:SetHealthColorMode(value)
	ns.db.healthColorMode = value
	ns:ApplyHealthColorMode()
end

function ns:SetHealthCustomColor(r, g, b)
	ns.db.healthCustomColor = { r, g, b }
	ns:ApplyHealthColorMode()
end

function ns:SetPowerColorMode(value)
	ns.db.powerColorMode = value
	ns:ApplyPowerColorMode()
end

local function SetTextFont(text, font, size)
	if font and text:SetFont(font, size, "OUTLINE") then
		return
	end

	text:SetFont(GameFontNormal:GetFont(), size, "OUTLINE")
end

local function CreateText(parent, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	SetTextFont(text, ns:GetFontFile(), ns:GetFontSize())
	text:SetJustifyH(justify)
	text:SetWordWrap(false)
	return text
end

local function CreateBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(ns:GetTexture())
	return bar
end

local function SwingTimerPostUpdate(element)
	local frame = element.__owner
	local count = 0

	for _, key in ipairs(SWING_BAR_KEYS) do
		if element[key]:IsShown() then
			count = count + 1
		end
	end

	if frame.swingCount ~= count then
		frame.swingCount = count
		ns:DeferMethod(ns, "UpdatePixelGeometry", frame.unitKey)
	end
end

local swingFormatter

local function CreateSwingFormatter()
	local formatter = C_StringUtil.CreateSecondsFormatter()
	formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
	formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
	formatter:SetMillisecondsThreshold(60)
	return formatter
end

local function CreateSwingBox(swingTimer)
	local box = CreateFrame("Frame", nil, swingTimer)
	box:SetFrameLevel(swingTimer:GetFrameLevel())
	ns:CreateBorder(box)
	return box
end

local function CreateSwingTimer(frame)
	local swingTimer = CreateFrame("Frame", nil, frame)
	swingTimer:SetFrameLevel(frame:GetFrameLevel())
	swingTimer:Hide()

	swingTimer.box = CreateSwingBox(swingTimer)
	swingTimer.box:SetAllPoints()

	swingFormatter = swingFormatter or CreateSwingFormatter()

	local bar, time

	for _, key in ipairs(SWING_BAR_KEYS) do
		bar = CreateBar(swingTimer)
		bar:SetFrameLevel(swingTimer:GetFrameLevel() + 1)
		bar:SetMinMaxValues(0, 1)
		bar.box = CreateSwingBox(swingTimer)
		bar.box:Hide()

		time = CreateText(bar, "RIGHT")
		time:SetPoint("RIGHT", bar, "RIGHT", -ns.TEXT_PADDING, 0)
		time:Hide()
		time.binding = C_DurationUtil.CreateDurationTextBinding()
		time.binding:SetFormatter(swingFormatter)
		time.binding:SetFontString(time)
		time.binding:SetEnabled(false)
		bar.timeText = time

		swingTimer[key] = bar
	end

	swingTimer.PostUpdate = SwingTimerPostUpdate

	return swingTimer
end

local function UpdateSwingTimerShown(frame)
	local unit = frame.unitKey
	local allowed = frame.swingInCombat
		or not ns:IsElementShown(unit, SWING_COMBAT_KEY)
		or ns:ShouldPreview(unit, SWING_TIMER_KEY)

	frame.SwingTimer:SetShown(frame.swingPlaced and allowed)
end

local function OnSwingCombatChanged(frame, event)
	frame.swingInCombat = event == "PLAYER_REGEN_DISABLED"
	UpdateSwingTimerShown(frame)
end

function ns:ApplySwingTimerCombat(frame)
	local unit = frame.unitKey

	if ns:IsElementShown(unit, SWING_TIMER_KEY) and ns:IsElementShown(unit, SWING_COMBAT_KEY) then
		frame.swingInCombat = UnitAffectingCombat("player")
		frame:RegisterEvent("PLAYER_REGEN_DISABLED", OnSwingCombatChanged, true)
		frame:RegisterEvent("PLAYER_REGEN_ENABLED", OnSwingCombatChanged, true)
	else
		frame.swingInCombat = nil
		frame:UnregisterEvent("PLAYER_REGEN_DISABLED", OnSwingCombatChanged)
		frame:UnregisterEvent("PLAYER_REGEN_ENABLED", OnSwingCombatChanged)
	end

	UpdateSwingTimerShown(frame)
end

function ns:ApplySwingTimerTime(frame)
	local shown = ns:IsElementShown(frame.unitKey, SWING_TIME_KEY)

	if frame.swingTimeShown == shown then
		return
	end

	frame.swingTimeShown = shown
	frame.swingCount = nil
	frame:DisableElement("SwingTimer")

	local bar

	for _, key in ipairs(SWING_BAR_KEYS) do
		bar = frame.SwingTimer[key]
		bar.Time = shown and bar.timeText or nil
		bar.timeText:SetShown(shown)

		if not shown then
			bar.timeText.binding:SetEnabled(false)
		end
	end
end

function ns:ApplySwingTimerSeparate(frame)
	local separate = ns:IsElementShown(frame.unitKey, SWING_SEPARATE_KEY)

	if frame.swingSeparate == separate then
		return
	end

	frame.swingSeparate = separate
	ns:DeferMethod(ns, "UpdatePixelGeometry", frame.unitKey)
end

local function GetSwingTimerHeight(frame)
	local height = frame.swingCount * ns:GetElementSize(frame.unitKey, SWING_TIMER_KEY)

	if frame.swingSeparate then
		height = height + (frame.swingCount - 1)
			* (ns.BAR_INSET + ns:GetElementSize(frame.unitKey, SWING_GAP_KEY))
	end

	return height
end

local function ApplySwingTimerColors(frame)
	local unit = frame.unitKey

	for _, key in ipairs(SWING_BAR_KEYS) do
		frame.SwingTimer[key]:SetStatusBarColor(ns:GetElementColor(unit, SWING_TIMER_KEY .. key))
	end
end

local function CreatePredictionBar(health, level)
	local bar = CreateBar(health)
	bar:SetFrameLevel(health:GetFrameLevel() + level)
	bar:SetPoint("TOP", health, "TOP", 0, 0)
	bar:SetPoint("BOTTOM", health, "BOTTOM", 0, 0)
	return bar
end

local function CreateOverIndicator(parent, health, side, offset)
	local texture = parent:CreateTexture(nil, "OVERLAY")
	texture:SetPoint("TOP", health, "TOP", 0, 0)
	texture:SetPoint("BOTTOM", health, "BOTTOM", 0, 0)
	texture:SetPoint(side, health, side, offset, 0)
	texture:SetWidth(OVER_INDICATOR_WIDTH)
	texture:SetAlpha(0)
	return texture
end

local function ApplyPredictionBar(bar, unit, element, shown)
	local r, g, b = ns:GetElementColor(unit, element)

	bar:SetStatusBarColor(r, g, b)
	bar:SetAlpha(ns:GetElementAlpha(unit, element))

	if not shown then
		bar:SetValue(0)
	end
end

function ns:ApplyPredictionVisuals(frame)
	local health = frame.Health
	local regions = frame.predictionRegions
	local unit = frame.unitKey
	local r, g, b

	local player = ns:IsElementShown(unit, "healingPlayer")
	local other = ns:IsElementShown(unit, "healingOther")
	local damage = ns:IsElementShown(unit, "damageAbsorb")
	local heal = ns:IsElementShown(unit, "healAbsorb")

	ApplyPredictionBar(regions.healingPlayer, unit, "healingPlayer", player)
	ApplyPredictionBar(regions.healingOther, unit, "healingOther", other)
	ApplyPredictionBar(regions.damageAbsorb, unit, "damageAbsorb", damage)
	ApplyPredictionBar(regions.healAbsorb, unit, "healAbsorb", heal)
	ApplyPredictionBar(frame.healthBox, unit, "tempLoss", ns:IsElementShown(unit, "tempLoss"))

	r, g, b = ns:GetElementColor(unit, "healingOther")
	regions.overHeal:SetColorTexture(r, g, b, OVER_INDICATOR_ALPHA)

	r, g, b = ns:GetElementColor(unit, "damageAbsorb")
	regions.overDamageAbsorb:SetColorTexture(r, g, b, OVER_INDICATOR_ALPHA)

	r, g, b = ns:GetElementColor(unit, "healAbsorb")
	regions.overHealAbsorb:SetColorTexture(r, g, b, OVER_INDICATOR_ALPHA)

	health:Show()
	frame.healthBox:Show()
	regions.healingPlayer:SetShown(player)
	regions.healingOther:SetShown(other)
	regions.damageAbsorb:SetShown(damage)
	regions.healAbsorb:SetShown(heal)
	regions.overHeal:SetShown(player or other)
	regions.overDamageAbsorb:SetShown(damage)
	regions.overHealAbsorb:SetShown(heal)
end

local function ApplyPrediction(frame)
	local health = frame.Health
	local regions = frame.predictionRegions
	local unit = frame.unitKey

	local player = ns:IsElementShown(unit, "healingPlayer")
	local other = ns:IsElementShown(unit, "healingOther")
	local damage = ns:IsElementShown(unit, "damageAbsorb")
	local heal = ns:IsElementShown(unit, "healAbsorb")
	local loss = ns:IsElementShown(unit, "tempLoss")

	health.HealingPlayer = player and regions.healingPlayer or nil
	health.HealingOther = other and regions.healingOther or nil
	health.OverHealIndicator = (player or other) and regions.overHeal or nil
	health.DamageAbsorb = damage and regions.damageAbsorb or nil
	health.OverDamageAbsorbIndicator = damage and regions.overDamageAbsorb or nil
	health.HealAbsorb = heal and regions.healAbsorb or nil
	health.OverHealAbsorbIndicator = heal and regions.overHealAbsorb or nil
	health.TempLoss = loss and frame.healthBox or nil

	local state = (player and 1 or 0) + (other and 2 or 0) + (damage and 4 or 0)
		+ (heal and 8 or 0) + (loss and 16 or 0)
	local changed = frame.predictionState ~= state
	local previewed = frame.elementsReady
		and ns:ShouldPreview(unit, ns.PREDICTION_SECTION)

	frame.predictionState = state

	if changed and frame.elementsReady and not previewed then
		frame:DisableElement("Health")
		frame:EnableElement("Health")
		health:ForceUpdate()
	end

	if previewed then
		ns:ShowPredictionPreview(frame)
	else
		ns:ApplyPredictionVisuals(frame)
	end
end

function ns:ApplyElementColors()
	for frame in next, styled do
		ApplyPrediction(frame)
		ns:ApplyResourceColors(frame)
		ns:ApplyThreatColor(frame)

		if frame.SwingTimer then
			ApplySwingTimerColors(frame)
		end
	end
end

local function UpdateTooltip(frame)
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)

	if GameTooltip:SetUnit(frame.__unit) then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
		GameTooltip:Show()

		frame.UpdateTooltip = UpdateTooltip
	else
		frame.UpdateTooltip = nil
	end
end

local function OnEnter(frame)
	if GameTooltip:IsForbidden() or not frame.__unit then
		return
	end

	UpdateTooltip(frame)
end

local function OnLeave(frame)
	if GameTooltip:IsForbidden() then
		return
	end

	frame.UpdateTooltip = nil
	GameTooltip:FadeOut()
end

local function IsHealer(unit)
	if not unit or issecretvalue(unit) then
		return
	end

	local role = UnitGroupRolesAssigned(unit)

	if issecretvalue(role) then
		return
	end

	if role == "NONE" and UnitIsUnit(unit, "player") then
		local spec = C_SpecializationInfo.GetSpecialization()

		role = spec and GetSpecializationRole(spec) or role
	end

	return role == "HEALER"
end

local function IsFriendlyNPC(unit)
	if not unit or issecretvalue(unit) then
		return false
	end

	return not UnitIsPlayer(unit) and UnitIsFriend("player", unit)
end

local function PowerPostUpdate(element, unit, _, _, max)
	local key = element.__owner.unitKey
	local shown

	if not ns:IsUnitPowerShown(key) then
		shown = false
	elseif ns:IsHealerPowerOnly(key) and IsHealer(unit) == false then
		shown = false
	elseif ns:IsHidingFriendlyNPCPower(key) and IsFriendlyNPC(unit) then
		shown = false
	elseif issecretvalue(max) then
		shown = true
	else
		shown = (max or 0) > 0
	end

	ns:SetPowerShown(element.__owner, shown)
end

local function CastbarSlot(frame)
	local unit = frame.unitKey

	if not frame.Castbar then
		return nil
	elseif not ns:IsElementShown(unit, "castbar") and not ns:ShouldPreview(unit, "castbar") then
		return nil
	end

	return frame.Castbar, ns:GetElementSize(unit, "castbar")
end

local function PlaceCastbar(frame, placement, stackY)
	local castbar = frame.Castbar

	if not castbar then
		return
	end

	local border = frame.castbarBorder
	local detached = placement == ns.PLACEMENT_FREE
	local boxed = detached or placement == ns.PLACEMENT_OUTSIDE

	frame.castbarOutside = boxed

	if not boxed then
		border:Hide()
	end

	if not placement then
		return
	end

	local unit = frame.unitKey
	local height = ns:GetElementSize(unit, "castbar")
	local iconBorder = frame.castbarIconBorder
	local iconX, iconY = ns:GetElementOffset(unit, "castbarIcon")
	local iconGap = ns:GetElementSize(unit, "castbarIconGap") - 2 * ns.BORDER_SHADOW
	local rightSide = ns:GetElementAnchor(unit, "castbarIcon") == "RIGHT"
	local matchIcon = ns:IsElementShown(unit, "castbarIconMatch")
	local shield = castbar.Shield
	local iconSize

	castbar:ClearAllPoints()
	iconBorder:ClearAllPoints()
	shield:ClearAllPoints()

	if boxed then
		local width = ns:GetElementSize(unit, "castbarWidth")
		local matchWidth = ns:IsElementShown(unit, "castbarWidthMatch")

		border:ClearAllPoints()

		if detached then
			local x, y = ns:GetElementPosition(unit, "castbar")

			ns:SetPoint(border, "BOTTOM", UIParent, "BOTTOM", x, y)
			ns:SetWidth(border, matchWidth and ns:GetUnitSizes(unit) or width)
		else
			local x, y = ns:GetElementOffset(unit, "castbar")

			ns:SetPoint(border, "TOPLEFT", frame, "BOTTOMLEFT", x, stackY + y)

			if matchWidth then
				ns:SetPoint(border, "TOPRIGHT", frame, "BOTTOMRIGHT", x, stackY + y)
			else
				ns:SetWidth(border, width)
			end
		end

		ns:SetHeight(border, height + 2 * ns.BAR_INSET)

		if detached then
			ns:SnapToPixelGrid(border)
		end

		border:SetShown(castbar:IsShown())

		ns:SetPoint(castbar, "TOPLEFT", border, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(castbar, "BOTTOMRIGHT", border, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)

		iconSize = height
		shield:SetAllPoints(border)

		if rightSide then
			ns:SetPoint(iconBorder, "LEFT", border, "RIGHT", iconGap + iconX, iconY)
		else
			ns:SetPoint(iconBorder, "RIGHT", border, "LEFT", -iconGap + iconX, iconY)
		end
	else
		iconSize = height
		shield:SetAllPoints(castbar)

		if rightSide then
			ns:SetPoint(iconBorder, "LEFT", castbar, "RIGHT",
				ns.BAR_INSET + iconGap + iconX, iconY)
		else
			ns:SetPoint(iconBorder, "RIGHT", castbar, "LEFT",
				-(ns.BAR_INSET + iconGap) + iconX, iconY)
		end
	end

	if not matchIcon then
		iconSize = ns:GetElementSize(unit, "castbarIcon")
	end

	iconSize = iconSize + 2 * ns.BAR_INSET
	ns:SetSize(iconBorder, iconSize, iconSize)

	ns:SetSize(castbar.Spark, height * SPARK_RATIO, height)
end

local function ResourceSlot(frame, key)
	if not ns:IsResourceSlotFilled(frame, key) then
		return nil
	end

	return ns:GetResourceSlotRegion(frame, key), ns:GetElementSize(frame.unitKey, key)
end

local function AdditionalPowerSlot(frame)
	return ResourceSlot(frame, ns.POWER_SLOT)
end

local function PlaceAdditionalPower(frame, placement, stackY)
	ns:PlaceResourceSlot(frame, ns.POWER_SLOT, placement, stackY)
end

local function ClassResourceSlot(frame)
	return ResourceSlot(frame, ns.CLASS_SLOT)
end

local function PlaceClassResource(frame, placement, stackY)
	ns:PlaceResourceSlot(frame, ns.CLASS_SLOT, placement, stackY)
end

local function SwingTimerSlot(frame)
	local unit = frame.unitKey

	if not frame.SwingTimer or not frame.swingCount or frame.swingCount == 0 then
		return nil
	elseif not ns:IsElementShown(unit, SWING_TIMER_KEY) and not ns:ShouldPreview(unit, SWING_TIMER_KEY) then
		return nil
	end

	return frame.SwingTimer, GetSwingTimerHeight(frame)
end

local swingAnchors = {}

local function PlaceSwingTimer(frame, placement, stackY)
	local swingTimer = frame.SwingTimer

	if not swingTimer then
		return
	elseif not placement then
		frame.swingPlaced = false
		swingTimer:Hide()
		return
	end

	local unit = frame.unitKey
	local height = ns:GetElementSize(unit, SWING_TIMER_KEY)
	local separate = frame.swingSeparate
	local gap = ns:GetElementSize(unit, SWING_GAP_KEY) - ns.BAR_INSET
	local count = 0
	local x, y, previous, bar, box

	swingTimer:ClearAllPoints()

	if placement == ns.PLACEMENT_FREE then
		x, y = ns:GetElementPosition(unit, SWING_TIMER_KEY)
		ns:SetPoint(swingTimer, "BOTTOM", UIParent, "BOTTOM", x, y)
		ns:SetWidth(swingTimer, ns:GetElementSize(unit, SWING_TIMER_KEY .. "Width"))
	elseif placement == ns.PLACEMENT_ABOVE then
		x, y = ns:GetElementOffset(unit, SWING_TIMER_KEY)
		ns:SetPoint(swingTimer, "BOTTOMLEFT", frame, "TOPLEFT", x, ns.BORDER_GAP + y)
		ns:SetPoint(swingTimer, "BOTTOMRIGHT", frame, "TOPRIGHT", x, ns.BORDER_GAP + y)
	else
		x, y = ns:GetElementOffset(unit, SWING_TIMER_KEY)
		ns:SetPoint(swingTimer, "TOPLEFT", frame, "BOTTOMLEFT", x, stackY + y)
		ns:SetPoint(swingTimer, "TOPRIGHT", frame, "BOTTOMRIGHT", x, stackY + y)
	end

	ns:SetHeight(swingTimer, GetSwingTimerHeight(frame) + 2 * ns.BAR_INSET)

	if placement == ns.PLACEMENT_FREE then
		ns:SnapToPixelGrid(swingTimer)
	end

	swingTimer.box:SetShown(not separate)

	for _, key in ipairs(SWING_BAR_KEYS) do
		bar = swingTimer[key]
		box = bar.box
		box:SetShown(separate and bar:IsShown())

		if bar:IsShown() and separate then
			bar:ClearAllPoints()
			box:ClearAllPoints()

			if previous then
				ns:SetPoint(box, "TOPLEFT", previous, "BOTTOMLEFT", 0, -gap)
				ns:SetPoint(box, "TOPRIGHT", previous, "BOTTOMRIGHT", 0, -gap)
			else
				ns:SetPoint(box, "TOPLEFT", swingTimer, "TOPLEFT", 0, 0)
				ns:SetPoint(box, "TOPRIGHT", swingTimer, "TOPRIGHT", 0, 0)
			end

			ns:SetHeight(box, height + 2 * ns.BAR_INSET)
			ns:SetPoint(bar, "TOPLEFT", box, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
			ns:SetPoint(bar, "TOPRIGHT", box, "TOPRIGHT", -ns.BAR_INSET, -ns.BAR_INSET)
			ns:SetHeight(bar, height)
			ns:SetBorderDividers(box)
			previous = box
		elseif bar:IsShown() then
			bar:ClearAllPoints()

			if previous then
				ns:SetPoint(bar, "TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
				ns:SetPoint(bar, "TOPRIGHT", previous, "BOTTOMRIGHT", 0, 0)
			else
				ns:SetPoint(bar, "TOPLEFT", swingTimer, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
				ns:SetPoint(bar, "TOPRIGHT", swingTimer, "TOPRIGHT", -ns.BAR_INSET, -ns.BAR_INSET)
			end

			ns:SetHeight(bar, height)
			count = count + 1
			swingAnchors[count] = bar
			previous = bar
		end
	end

	ns:SetBorderDividers(swingTimer.box, swingAnchors, count - 1)
	frame.swingPlaced = true
	UpdateSwingTimerShown(frame)
end

local STACK = {
	{ key = ns.POWER_SLOT, Slot = AdditionalPowerSlot, Place = PlaceAdditionalPower },
	{ key = ns.CLASS_SLOT, Slot = ClassResourceSlot, Place = PlaceClassResource },
	{ key = "castbar", Slot = CastbarSlot, Place = PlaceCastbar },
	{ key = SWING_TIMER_KEY, Slot = SwingTimerSlot, Place = PlaceSwingTimer },
}

local stackRegions = {}
local stackHeights = {}
local stackAnchors = {}

local function ChainInside(frame, count)
	local healthBox = frame.healthBox
	local previous, region

	for index = count, 1, -1 do
		region = stackRegions[index]
		ns:SetHeight(region, stackHeights[index])

		if previous then
			ns:SetPoint(region, "BOTTOMLEFT", previous, "TOPLEFT", 0, 0)
			ns:SetPoint(region, "BOTTOMRIGHT", previous, "TOPRIGHT", 0, 0)
		else
			ns:SetPoint(region, "BOTTOMLEFT", frame, "BOTTOMLEFT", ns.BAR_INSET, ns.BAR_INSET)
			ns:SetPoint(region, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
		end

		previous = region
	end

	ns:SetPoint(healthBox, "TOPLEFT", frame, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
	ns:SetPoint(healthBox, "TOPRIGHT", frame, "TOPRIGHT", -ns.BAR_INSET, -ns.BAR_INSET)

	if previous then
		ns:SetPoint(healthBox, "BOTTOMLEFT", previous, "TOPLEFT", 0, 0)
		ns:SetPoint(healthBox, "BOTTOMRIGHT", previous, "TOPRIGHT", 0, 0)
	else
		ns:SetPoint(healthBox, "BOTTOMLEFT", frame, "BOTTOMLEFT", ns.BAR_INSET, ns.BAR_INSET)
		ns:SetPoint(healthBox, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
	end

	stackAnchors[1] = healthBox

	for index = 2, count do
		stackAnchors[index] = stackRegions[index - 1]
	end

	ns:SetBorderDividers(frame, stackAnchors, count)
end

local function ApplyBarStack(frame)
	local unit = frame.unitKey
	local count = 0
	local stackY = 0
	local region, height, placement

	frame.Power:SetShown(not not frame.powerShown)

	if frame.powerShown then
		count = count + 1
		stackRegions[count] = frame.Power
		stackHeights[count] = select(3, ns:GetUnitSizes(unit))
	end

	for _, entry in ipairs(STACK) do
		region, height = entry.Slot(frame)
		placement = region and ns:GetElementPlacement(unit, entry.key) or nil

		if placement == ns.PLACEMENT_INSIDE then
			count = count + 1
			stackRegions[count] = region
			stackHeights[count] = height
		elseif placement == ns.PLACEMENT_OUTSIDE then
			stackY = stackY - ns.BORDER_GAP
		end

		entry.Place(frame, placement, stackY)

		if placement == ns.PLACEMENT_OUTSIDE then
			stackY = stackY - height - 2 * ns.BAR_INSET
		end
	end

	ChainInside(frame, count)
	ns:LayoutResourceBars(frame)
end

function ns:SetPowerShown(frame, shown)
	if frame.powerShown == shown then
		return
	end

	frame.powerShown = shown
	ApplyBarStack(frame)
end

local function IsInsideReserved(unit, key)
	if not ns:HasElement(unit, key) then
		return false
	elseif ns:GetElementPlacement(unit, key) ~= ns.PLACEMENT_INSIDE then
		return false
	end

	return ns:IsElementShown(unit, key) or ns:ShouldPreview(unit, key)
end

local function InsideHeight(frame)
	local unit = frame.unitKey
	local total = 0

	for _, entry in ipairs(STACK) do
		if IsInsideReserved(unit, entry.key) then
			total = total + ns:GetElementSize(unit, entry.key)
		end
	end

	return total
end

local function LayoutFrame(frame)
	local width, height = ns:GetUnitSizes(frame.unitKey)

	if not InCombatLockdown() then
		ns:SetSize(frame, width, height + InsideHeight(frame))

		if frame.standalone then
			ns:SnapToPixelGrid(frame)
		end
	end

	ApplyBarStack(frame)
	ns:ApplyHealthWidth(frame, width - 2 * ns.BAR_INSET)
	ns:PlaceElements(frame)
end

local function SetBarSmoothing(frame, smoothing)
	local bar

	for _, key in ipairs(SMOOTHED_BARS) do
		bar = frame[key]

		if bar then
			bar.smoothing = smoothing
		end
	end
end

local function FramePreUpdate(frame, event)
	if event ~= "OnUpdate" then
		frame.barsSnapped = true
		SetBarSmoothing(frame, Enum.StatusBarInterpolation.Immediate)
	end
end

local function FramePostUpdate(frame)
	if frame.barsSnapped then
		frame.barsSnapped = nil
		SetBarSmoothing(frame, SMOOTHING)
	end
end

local function Style(self, unit)
	unit = unit or ""

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self.unitKey = ns:GetUnitKey(unit)
	self.PreUpdate = FramePreUpdate
	self.PostUpdate = FramePostUpdate

	local power = CreateBar(self)
	power.smoothing = SMOOTHING
	power.frequentUpdates = unit == "player"
	power.colorTapping = true
	power.colorDisconnected = true
	power.PostUpdate = PowerPostUpdate
	self.Power = power

	local healthBox = CreateBar(self)
	healthBox:SetReverseFill(true)
	healthBox:SetMinMaxValues(0, 1)
	self.healthBox = healthBox

	local health = CreateBar(self)
	health.smoothing = SMOOTHING
	health.colorTapping = true
	health.colorDisconnected = true
	health.incomingHealOverflow = 1
	health.PostUpdate = HealthPostUpdate
	health.PostUpdateColor = HealthPostUpdateColor
	health:SetPoint("TOPLEFT", healthBox, "TOPLEFT", 0, 0)
	health:SetPoint("BOTTOMLEFT", healthBox, "BOTTOMLEFT", 0, 0)
	self.Health = health

	local healingPlayer = CreatePredictionBar(health, PREDICTION_LEVEL)
	healingPlayer:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT", 0, 0)

	local healingOther = CreatePredictionBar(health, PREDICTION_LEVEL)
	healingOther:SetPoint("LEFT", healingPlayer:GetStatusBarTexture(), "RIGHT", 0, 0)

	local damageAbsorb = CreatePredictionBar(health, ABSORB_LEVEL)
	damageAbsorb:SetPoint("LEFT", healingOther:GetStatusBarTexture(), "RIGHT", 0, 0)

	local healAbsorb = CreatePredictionBar(health, ABSORB_LEVEL)
	healAbsorb:SetReverseFill(true)
	healAbsorb:SetPoint("RIGHT", health:GetStatusBarTexture(), "RIGHT", 0, 0)

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetAllPoints()
	healthOverlay:SetFrameLevel(health:GetFrameLevel() + HEALTH_OVERLAY_LEVEL)
	self.healthOverlay = healthOverlay

	self.predictionRegions = {
		healingPlayer = healingPlayer,
		healingOther = healingOther,
		damageAbsorb = damageAbsorb,
		healAbsorb = healAbsorb,
		overHeal = CreateOverIndicator(healthOverlay, health, "RIGHT", 0),
		overDamageAbsorb = CreateOverIndicator(healthOverlay, health, "RIGHT",
			-OVER_INDICATOR_WIDTH),
		overHealAbsorb = CreateOverIndicator(healthOverlay, health, "LEFT", 0),
	}

	ApplyPrediction(self)
	ApplyHealthColorFlags(self)
	ApplyPowerColorFlags(self)

	local costPrediction = CreateBar(power)
	costPrediction:SetReverseFill(true)
	costPrediction:SetPoint("TOP", power, "TOP", 0, 0)
	costPrediction:SetPoint("BOTTOM", power, "BOTTOM", 0, 0)
	costPrediction:SetPoint("RIGHT", power:GetStatusBarTexture(), "RIGHT", 0, 0)
	power.CostPrediction = costPrediction

	ns:CreateBorder(self)

	self.elements = {}

	local texts = {}

	for _, element in ipairs(ns.TEXT_ELEMENTS) do
		self.elements[element] = CreateText(healthOverlay,
			ns:GetElementAnchor(self.unitKey, element))
		texts[#texts + 1] = self.elements[element]
	end

	ns:CreateIndicators(self)

	if unit == "player" then
		local resting = ns:CreateRestingIndicator(self)
		self.RestingIndicator = resting
		self.elements.resting = resting

		if C_SwingTimer then
			self.SwingTimer = CreateSwingTimer(self)
			ApplySwingTimerColors(self)

			for _, key in ipairs(SWING_BAR_KEYS) do
				texts[#texts + 1] = self.SwingTimer[key].timeText
			end
		end
	end

	if ns:HasElement(self.unitKey, "castbar") then
		local castbar = CreateBar(self)

		local border = CreateFrame("Frame", nil, self)
		border:SetFrameLevel(self:GetFrameLevel())
		ns:CreateBorder(border)
		border:SetShown(castbar:IsShown())

		castbar:HookScript("OnShow", function()
			border:SetShown(self.castbarOutside)
		end)

		castbar:HookScript("OnHide", function()
			border:Hide()
		end)

		self.castbarBorder = border

		local castbarText = CreateText(castbar, "LEFT")
		castbarText:SetPoint("LEFT", castbar, "LEFT", ns.TEXT_PADDING, 0)
		castbar.Text = castbarText

		local castbarTime = CreateText(castbar, "RIGHT")
		castbarTime:SetPoint("RIGHT", castbar, "RIGHT", -ns.TEXT_PADDING, 0)
		castbar.Time = castbarTime

		local spark = castbar:CreateTexture(nil, "OVERLAY")
		spark:SetAtlas(SPARK_ATLAS)
		spark:SetBlendMode("ADD")
		spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
		castbar.Spark = spark

		local shield = castbar:CreateTexture(nil, "OVERLAY")
		shield:SetAllPoints(border)
		castbar.Shield = shield

		local iconBorder = CreateFrame("Frame", nil, castbar)
		iconBorder:SetFrameLevel(castbar:GetFrameLevel())
		ns:CreateBorder(iconBorder)
		self.castbarIconBorder = iconBorder

		local icon = iconBorder:CreateTexture(nil, "ARTWORK")
		ns:SetPoint(icon, "TOPLEFT", iconBorder, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(icon, "BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
		icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
		castbar.Icon = icon
		castbar.SafeZone = castbar:CreateTexture(nil, "BACKGROUND")

		self.Castbar = castbar

		texts[#texts + 1] = castbarText
		texts[#texts + 1] = castbarTime

		self.elements.castbar = castbar
	end

	styled[self] = texts

	ns:ApplyTags(self)
	ns:ApplyElementText(self)
	LayoutFrame(self)
end

function ns:UpdatePixelGeometry(key)
	for frame in next, styled do
		if not key or frame.unitKey == key then
			LayoutFrame(frame)
		end
	end

	ns:ApplyGroupLayout()
end

function ns:SetPreviewUnit(frame, previewed)
	local unit = frame:GetAttribute("unit")

	if previewed then
		if not (unit and UnitExists(unit)) then
			frame.realUnit = unit or false
			frame:SetAttribute("unit", PREVIEW_UNIT)
		end
	elseif frame.realUnit ~= nil then
		frame:SetAttribute("unit", frame.realUnit or nil)
		frame.realUnit = nil
	end
end

function ns:ApplyFramePreview(key)
	local previewed = ns:AnyPreviewActive(key)

	for frame in next, styled do
		if frame.standalone and frame.unitKey == key then
			ns:SetPreviewUnit(frame, previewed)

			if previewed then
				UnregisterUnitWatch(frame)
				frame:Show()
			else
				RegisterUnitWatch(frame)
			end
		end
	end
end

function ns:UpdateElements()
	for frame in next, styled do
		ns:ApplyElements(frame)
	end
end

function ns:OnFrameInitialized(frame)
	if styled[frame] then
		frame.elementsReady = true
		ns:ApplyElements(frame)
	end
end

function ns:UpdateTags()
	for frame in next, styled do
		ns:ApplyTags(frame)
	end
end

function ns:CreateLiveTextElement(key)
	local text

	for frame, texts in next, styled do
		text = CreateText(frame.healthOverlay, ns:GetElementAnchor(frame.unitKey, key))
		frame.elements[key] = text
		texts[#texts + 1] = text
	end

	ns:UpdateElements()
	ns:UpdateTags()
	ns:DeferMethod(ns, "UpdatePixelGeometry")
end

function ns:RemoveLiveTextElement(key)
	local text

	for frame, texts in next, styled do
		text = frame.elements[key]

		if text then
			frame:Untag(text)
			text:Hide()
			text:ClearAllPoints()
			frame.elements[key] = nil

			for index, existing in ipairs(texts) do
				if existing == text then
					table.remove(texts, index)
					break
				end
			end
		end
	end
end

function ns:UpdatePower()
	for frame in next, styled do
		if frame.Power and frame:IsElementEnabled("Power") then
			frame.Power:ForceUpdate()
		end
	end
end

function ns:ApplyMedia()
	local font = ns:GetFontFile()
	local size = ns:GetFontSize()
	local texture = ns:GetTexture()

	for frame, texts in next, styled do
		if texture then
			frame.Health:SetStatusBarTexture(texture)
			frame.healthBox:SetStatusBarTexture(texture)
			frame.predictionRegions.healingPlayer:SetStatusBarTexture(texture)
			frame.predictionRegions.healingOther:SetStatusBarTexture(texture)
			frame.predictionRegions.damageAbsorb:SetStatusBarTexture(texture)
			frame.predictionRegions.healAbsorb:SetStatusBarTexture(texture)
		end

		if frame.Power and texture then
			frame.Power:SetStatusBarTexture(texture)
			frame.Power.CostPrediction:SetStatusBarTexture(texture)
		end

		if frame.Castbar and texture then
			frame.Castbar:SetStatusBarTexture(texture)
		end

		if frame.SwingTimer and texture then
			for _, key in ipairs(SWING_BAR_KEYS) do
				frame.SwingTimer[key]:SetStatusBarTexture(texture)
			end

			ApplySwingTimerColors(frame)
		end

		ns:ApplyResourceMedia(frame, texture)

		for _, text in ipairs(texts) do
			SetTextFont(text, font, size)

			if text.binding then
				text.binding:UpdateFontString()
			end
		end

		if frame.__unit then
			frame:UpdateTags()
		end
	end
end

ns.Style = Style
