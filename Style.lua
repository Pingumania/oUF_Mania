local _, ns = ...
local oUF = ns.oUF

local LSM = LibStub("LibSharedMedia-3.0")

local issecretvalue = issecretvalue

local FONT_SIZE_MIN = 8
local FONT_SIZE_MAX = 20

local PREVIEW_UNIT = "player"
local ICON_ZOOM = 0.08

local SWING_TIMER_KEY = "swingtimer"
local SWING_COMBAT_KEY = "swingtimerCombat"
local SWING_TIME_KEY = "swingtimerTime"
local SWING_SEPARATE_KEY = "swingtimerSeparate"
local SWING_GAP_KEY = "swingtimerGap"
local SWING_BAR_KEYS = { "MainHand", "OffHand", "Ranged" }

local HEALTH_BAR_KEY = "healthbar"
local POWER_BAR_KEY = "powerbar"

local CAST_COLOR = CreateColor(1, 0.7, 0)
local CHANNEL_COLOR = CreateColor(0, 1, 0)

local DARK_BACKGROUND = 0.3

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

local FONT_OUTLINES = {
	{ value = "", label = "None" },
	{ value = "OUTLINE", label = "Outline" },
	{ value = "THICKOUTLINE", label = "Thick outline" },
}

function ns:GetTexture()
	return LSM:Fetch("statusbar", ns.db.texture or ns.Defaults.texture)
end

function ns:GetFontSizeRange()
	return FONT_SIZE_MIN, FONT_SIZE_MAX
end

function ns:GetFontOutlines()
	return FONT_OUTLINES
end

local BAR_COLOR_MODES = {
	{ value = "class", label = "Class color" },
	{ value = "blizzard", label = "Blizzard (default)" },
	{ value = "custom", label = "Custom color" },
}

function ns:GetBarColorModes()
	return BAR_COLOR_MODES
end

function ns:FollowBarColor(bar)
	if bar.darkBackground and bar.backgroundPanel then
		local r, g, b = (bar.colorSource or bar):GetStatusBarColor()
		bar.backgroundPanel:SetVertexColor(r, g, b)
	end
end

local function PaintBackground(frame, bar)
	local panel = bar.backgroundPanel
	local key = bar.backgroundKey
	local unit = frame.unitKey
	local mode = ns:GetElementBackgroundMode(unit, key)
	local alpha = ns:GetElementBackgroundAlpha(unit, key)
	local r, g, b = 0, 0, 0

	bar.darkBackground = mode == "dark"

	if bar.darkBackground then
		panel:SetColorTexture(DARK_BACKGROUND, DARK_BACKGROUND, DARK_BACKGROUND, alpha)
		ns:FollowBarColor(bar)
		return
	elseif mode == "custom" then
		r, g, b = ns:GetElementBackgroundColor(unit, key)
	end

	panel:SetColorTexture(r, g, b, alpha)
	panel:SetVertexColor(1, 1, 1)
end

local function ApplyBackgrounds(frame)
	local panels = frame.borderPanels

	for index = 1, frame.borderPanelCount do
		ns:PaintDefaultBackground(panels[index])
	end

	for _, bar in ipairs(frame.backgroundBars) do
		if bar.backgroundPanel then
			PaintBackground(frame, bar)
		end
	end
end

local function BarPostUpdateColor(element, _, color)
	local unit = element.__owner.unitKey

	if not color and ns:GetElementColorMode(unit, element.colorKey) == "custom" then
		element:SetStatusBarColor(ns:GetElementColor(unit, element.colorKey))
	end

	ns:FollowBarColor(element)
end

local function UnitColor(unit)
	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		return issecretvalue(class) and C_ClassColor.GetClassColor(class) or oUF.colors.class[class]
	end

	return oUF.colors.reaction[UnitReaction(unit, "player")]
end

local function CastbarColor(element, unit)
	local key = element.__owner.unitKey
	local mode = ns:GetElementColorMode(key, "castbar")

	if mode == "custom" then
		element.customColor:SetRGB(ns:GetElementColor(key, "castbar"))
		return element.customColor
	elseif mode == "class" then
		return UnitColor(unit) or CAST_COLOR
	end

	local name, _, _, _, _, _, _, _, isEmpowered = UnitChannelInfo(unit)

	return (name and not isEmpowered) and CHANNEL_COLOR or CAST_COLOR
end

function ns:ApplyCastbarColor(element, unit, notInterruptible)
	element.uninterruptibleColor:SetRGB(ns:GetElementColor(element.__owner.unitKey, "castbarUninterruptible"))
	element:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, element.uninterruptibleColor,
		CastbarColor(element, unit))
	ns:FollowBarColor(element)
end

local function CastbarPostCastStart(element, unit, _, notInterruptible)
	ns:ApplyCastbarColor(element, unit, notInterruptible)
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

local function ApplyBarColorFlags(bar, mode)
	bar.colorClass = mode == "class"
	bar.colorReaction = mode == "class"
	bar.colorHealth = mode == "blizzard"
	bar.colorPower = mode == "blizzard"
end

local function ApplyBarColors(frame)
	local unit = frame.unitKey

	ApplyBarColorFlags(frame.Health, ns:GetElementColorMode(unit, HEALTH_BAR_KEY))
	ApplyBarColorFlags(frame.Power, ns:GetElementColorMode(unit, POWER_BAR_KEY))
	frame.Health:ForceUpdate()
	frame.Power:ForceUpdate()
end

local function RedrawText(text)
	if text:IsShown() then
		local value = text:GetText()
		text:Hide()
		text:SetText("")
		text:SetText(value)
		text:Show()
	end
end

local function SetTextFont(text, unit)
	local key = text.fontKey
	local font = LSM:Fetch("font", ns:GetTextFont(unit, key))
	local size = ns:GetTextFontSize(unit, key)
	local outline = ns:GetTextOutline(unit, key)
	local smooth = ns:IsTextSmooth(unit, key)
	if smooth then
		outline = outline == "" and "SLUG" or outline..", SLUG"
	end
	local shadow = ns:HasTextShadow(unit, key) and 1 or 0

	if not (font and text:SetFont(font, size, outline)) then
		text:SetFont(GameFontNormal:GetFont(), size, outline)
	end

	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(shadow, -shadow)

	return smooth
end

local function ApplyTextFont(text, unit)
	local smooth = SetTextFont(text, unit)

	RedrawText(text)

	if smooth then
		RunNextFrame(function()
			RedrawText(text)
		end)
	end
end

local function CreateText(parent, justify, unit, key)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text.fontKey = key
	ApplyTextFont(text, unit)
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
		bar.backgroundKey = SWING_TIMER_KEY

		time = CreateText(bar, "RIGHT", frame.unitKey, SWING_TIME_KEY)
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
		ApplyBarColors(frame)
		ns:ApplyResourceColors(frame)
		ns:ApplyThreatColor(frame)
		ns:ApplyCastPreviewColor(frame)

		if frame.SwingTimer then
			ApplySwingTimerColors(frame)
		end

		ApplyBackgrounds(frame)
	end
end

local function OnEnter(frame)
	if GameTooltip:IsForbidden() or not frame.__unit then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, frame)

	GameTooltip:SetUnit(frame.__unit)
end

local function OnLeave(frame)
	if GameTooltip:IsForbidden() then
		return
	end

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

local SPARK_STYLES = {
	{ value = "plunderstorm", label = "Plunderstorm", atlas = "plunderstorm-stormbar-spark",
		ratio = 1.45 },
	{ value = "modern", label = "Modern", atlas = "ui-castingbar-pip-2x", ratio = 0.4 },
	{ value = "classic", label = "Classic",
		texture = [[Interface\CastingBar\UI-CastingBar-Spark]], ratio = 1, scale = 2.2 },
}

function ns:GetSparkStyles()
	return SPARK_STYLES
end

function ns:GetSparkStyle()
	return ns.db.castbarSpark or SPARK_STYLES[1].value
end

function ns:SetSparkStyle(value)
	ns.db.castbarSpark = value
	ns:UpdatePixelGeometry()
end

function ns:IsSparkShown()
	return not ns.db.castbarSparkHidden
end

function ns:SetSparkShown(shown)
	ns.db.castbarSparkHidden = not shown or nil
	ns:UpdatePixelGeometry()
end

local function ApplySparkStyle(spark, height)
	local value = ns:GetSparkStyle()
	local style = SPARK_STYLES[1]
	local sparkHeight

	for _, entry in ipairs(SPARK_STYLES) do
		if entry.value == value then
			style = entry
			break
		end
	end

	if style.atlas then
		spark:SetAtlas(style.atlas)
	else
		spark:SetTexture(style.texture)
		spark:SetTexCoord(0, 1, 0, 1)
	end

	spark:SetAlpha(ns:IsSparkShown() and 1 or 0)
	sparkHeight = height * (style.scale or 1)
	ns:SetSize(spark, sparkHeight * style.ratio, sparkHeight)
end

local SHIELD_MEDIA = [[Interface\AddOns\oUF_Mania\Media\shield-]]

local SHIELD_STYLES = {
	{ value = "castbar", label = "Cast bar", width = 75, height = 89, canvas = 128 },
	{ value = "tank", label = "Tank role", width = 16, height = 16, canvas = 16 },
	{ value = "warning", label = "Timeline warning", width = 64, height = 64, canvas = 64 },
	{ value = "groupmanager", label = "Group manager", width = 40, height = 40, canvas = 64 },
	{ value = "grouporganizer", label = "Group organizer", width = 50, height = 50, canvas = 64 },
	{ value = "nameplate", label = "Nameplate", width = 14, height = 16, canvas = 16 },
}

function ns:GetShieldStyles()
	return SHIELD_STYLES
end

function ns:GetShieldStyle()
	return ns.db.castbarShieldStyle or SHIELD_STYLES[1].value
end

function ns:SetShieldStyle(value)
	ns.db.castbarShieldStyle = value
	ns:UpdatePixelGeometry()
end

local function ApplyShieldStyle(holder, shield, size)
	local value = ns:GetShieldStyle()
	local style = SHIELD_STYLES[1]

	for _, entry in ipairs(SHIELD_STYLES) do
		if entry.value == value then
			style = entry
			break
		end
	end

	shield:SetTexture(SHIELD_MEDIA .. style.value, nil, nil, "TRILINEAR")
	shield:SetTexCoord(0, style.width / style.canvas, 0, style.height / style.canvas)
	ns:SetSize(holder, size * style.width / style.height, size)
end

local function PlaceCastbarIcon(frame, region, key, anchor, inset)
	local unit = frame.unitKey
	local x, y = ns:GetElementOffset(unit, key)
	local gap = inset + ns:GetElementSize(unit, key .. "Gap") - 2 * ns.BORDER_SHADOW
	local size = ns:GetElementSize(unit, ns:IsElementShown(unit, key .. "Match") and "castbar" or key)
	local side = ns:GetElementAnchor(unit, key)

	region:ClearAllPoints()

	if side == "CENTER" then
		ns:SetPoint(region, "CENTER", frame.Castbar, "CENTER", x, y)
	elseif side == "RIGHT" then
		ns:SetPoint(region, "LEFT", anchor, "RIGHT", gap + x, y)
	else
		ns:SetPoint(region, "RIGHT", anchor, "LEFT", -gap + x, y)
	end

	return size
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
	castbar.backgroundPanel = boxed and border.borderPanels[1] or nil

	if not boxed then
		border:Hide()
	end

	if not placement then
		return
	end

	local unit = frame.unitKey
	local height = ns:GetElementSize(unit, "castbar")
	local anchor, inset, iconSize, shieldSize, shieldLevel

	castbar:ClearAllPoints()

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

		anchor, inset = border, 0
	else
		anchor, inset = castbar, ns.BAR_INSET
	end

	iconSize = PlaceCastbarIcon(frame, frame.castbarIconBorder, "castbarIcon", anchor, inset)
	ns:SetSize(frame.castbarIconBorder, iconSize + 2 * ns.BAR_INSET, iconSize + 2 * ns.BAR_INSET)

	shieldSize = PlaceCastbarIcon(frame, frame.castbarShieldHolder, "castbarShield", anchor, inset)

	if ns:GetElementAnchor(unit, "castbarShield") == "CENTER" then
		shieldLevel = (boxed and border or frame).borderOverlay:GetFrameLevel() + 1
	else
		shieldLevel = castbar:GetFrameLevel()
	end

	frame.castbarShieldHolder:SetFrameLevel(shieldLevel)
	ApplyShieldStyle(frame.castbarShieldHolder, castbar.Shield, shieldSize)

	ApplySparkStyle(castbar.Spark, height)
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
		bar.backgroundPanel = nil

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
			bar.backgroundPanel = box.borderPanels[1]
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
			bar.backgroundPanel = swingTimer.box.borderPanels[count]
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
	frame.Health.backgroundPanel = frame.borderPanels[1]

	for index = 1, count do
		region = stackRegions[index]

		if region.backgroundKey then
			region.backgroundPanel = frame.borderPanels[index + 1]
		end
	end

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
	frame.Power.backgroundPanel = nil

	if frame.powerShown then
		count = count + 1
		stackRegions[count] = frame.Power
		stackHeights[count] = ns:GetElementSize(unit, POWER_BAR_KEY)
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
	ApplyBackgrounds(frame)
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

local function PlacePortrait(frame, frameHeight)
	local unit = frame.unitKey
	local holder = frame.portraitHolder
	local x, y = ns:GetElementOffset(unit, "portrait")
	local gap = ns:GetElementSize(unit, "portraitGap") - 2 * ns.BORDER_SHADOW
	local size = frameHeight

	if not ns:IsElementShown(unit, "portraitMatch") then
		size = ns:GetElementSize(unit, "portrait") + 2 * ns.BAR_INSET
	end

	holder:ClearAllPoints()

	if ns:GetElementAnchor(unit, "portrait") == "RIGHT" then
		ns:SetPoint(holder, "TOPLEFT", frame, "TOPRIGHT", gap + x, y)
	else
		ns:SetPoint(holder, "TOPRIGHT", frame, "TOPLEFT", -gap + x, y)
	end

	ns:SetSize(holder, size, size)
end

local function LayoutFrame(frame)
	local width, height = ns:GetUnitSizes(frame.unitKey)

	height = height + InsideHeight(frame)
	PlacePortrait(frame, height)

	if not InCombatLockdown() then
		ns:SetSize(frame, width, height)

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

	ns.RefreshAuraState(frame)
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
	power.PostUpdateColor = BarPostUpdateColor
	power.colorKey = POWER_BAR_KEY
	power.backgroundKey = POWER_BAR_KEY
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
	health.PostUpdateColor = BarPostUpdateColor
	health.colorKey = HEALTH_BAR_KEY
	health.backgroundKey = HEALTH_BAR_KEY
	health:SetClipsChildren(true)
	health:SetPoint("TOPLEFT", healthBox, "TOPLEFT", 0, 0)
	health:SetPoint("BOTTOMLEFT", healthBox, "BOTTOMLEFT", 0, 0)
	self.Health = health
	self.backgroundBars = { health, power }

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
	ApplyBarColorFlags(health, ns:GetElementColorMode(self.unitKey, HEALTH_BAR_KEY))
	ApplyBarColorFlags(power, ns:GetElementColorMode(self.unitKey, POWER_BAR_KEY))

	local costPrediction = CreateBar(power)
	costPrediction:SetReverseFill(true)
	costPrediction:SetPoint("TOP", power, "TOP", 0, 0)
	costPrediction:SetPoint("BOTTOM", power, "BOTTOM", 0, 0)
	costPrediction:SetPoint("RIGHT", power:GetStatusBarTexture(), "RIGHT", 0, 0)
	power.CostPrediction = costPrediction

	ns:CreateBorder(self)

	local portraitHolder = CreateFrame("Frame", nil, self)
	portraitHolder:SetFrameLevel(self:GetFrameLevel())
	portraitHolder:Hide()
	ns:CreateBorder(portraitHolder)
	self.portraitHolder = portraitHolder

	self.elements = {}

	local texts = {}

	for _, element in ipairs(ns.TEXT_ELEMENTS) do
		self.elements[element] = CreateText(healthOverlay, ns:GetElementAnchor(self.unitKey, element), self.unitKey, element)
		texts[#texts + 1] = self.elements[element]
	end

	ns:CreateIndicators(self)

	if unit == "player" then
		local resting = ns:CreateRestingIndicator(self)
		self.RestingIndicator = resting
		self.elements.resting = resting

		if C_SwingTimer then
			self.SwingTimer = CreateSwingTimer(self)

			for _, key in ipairs(SWING_BAR_KEYS) do
				self.backgroundBars[#self.backgroundBars + 1] = self.SwingTimer[key]
			end
			ApplySwingTimerColors(self)

			for _, key in ipairs(SWING_BAR_KEYS) do
				texts[#texts + 1] = self.SwingTimer[key].timeText
			end
		end
	end

	if ns:HasElement(self.unitKey, "castbar") then
		local castbar = CreateBar(self)
		castbar.customColor = CreateColor(1, 1, 1)
		castbar.uninterruptibleColor = CreateColor(1, 1, 1)
		castbar.backgroundKey = "castbar"
		castbar.PostCastStart = CastbarPostCastStart
		castbar.PostCastInterruptible = CastbarPostCastStart

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

		local castbarText = CreateText(castbar, "LEFT", self.unitKey, "castbarText")
		castbarText:SetPoint("LEFT", castbar, "LEFT", ns.TEXT_PADDING, 0)
		castbar.Text = castbarText

		local castbarTime = CreateText(castbar, "RIGHT", self.unitKey, "castbarTime")
		castbarTime:SetPoint("RIGHT", castbar, "RIGHT", -ns.TEXT_PADDING, 0)
		castbar.Time = castbarTime

		local spark = castbar:CreateTexture(nil, "OVERLAY")
		spark:SetBlendMode("ADD")
		spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
		castbar.Spark = spark

		local shieldHolder = CreateFrame("Frame", nil, castbar)
		shieldHolder:SetFrameLevel(castbar:GetFrameLevel())
		self.castbarShieldHolder = shieldHolder

		local shield = shieldHolder:CreateTexture(nil, "ARTWORK")
		shield:SetAllPoints()
		castbar.Shield = shield

		local iconBorder = CreateFrame("Frame", nil, castbar)
		iconBorder:SetFrameLevel(castbar:GetFrameLevel() + 1)
		ns:CreateBorder(iconBorder)
		self.castbarIconBorder = iconBorder

		local icon = iconBorder:CreateTexture(nil, "ARTWORK")
		ns:SetPoint(icon, "TOPLEFT", iconBorder, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(icon, "BOTTOMRIGHT", iconBorder, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
		icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
		castbar.Icon = icon
		castbar.SafeZone = castbar:CreateTexture(nil, "BACKGROUND")

		self.Castbar = castbar
		self.backgroundBars[#self.backgroundBars + 1] = castbar

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

-- Forever client bug: a frame shown for the first time from inside an OnUpdate
-- draws its StatusBar fills at full size for one frame. RegisterUnitWatch shows
-- unit frames from SecureStateDriverManager's OnUpdate, so every unit frame
-- flashes full bars on its first show. Hand OnShow back to oUF, then hide that
-- one frame with alpha 0 and restore it on the next frame.
local function MaskFirstShow(frame, ...)
	local onShow = frame.firstShowOnShow

	frame.firstShowOnShow = nil
	frame:SetScript("OnShow", onShow)
	onShow(frame, ...)

	frame:SetAlpha(0)
	C_Timer.After(0, function()
		frame:SetAlpha(1)
	end)
end

function ns:OnFrameInitialized(frame)
	if styled[frame] then
		frame.elementsReady = true
		ns:ApplyElements(frame)

		if ns:IsForever() then
			frame.firstShowOnShow = frame:GetScript("OnShow")
			frame:SetScript("OnShow", MaskFirstShow)
		end
	end
end

function ns:UpdateAuras()
	for frame in next, styled do
		ns:ApplyAuras(frame)
	end
end

function ns:SetAuraTextFont(text, unit)
	SetTextFont(text, unit)
end

function ns:UpdateTags()
	for frame in next, styled do
		ns:ApplyTags(frame)
	end
end

function ns:CreateLiveTextElement(key)
	local text

	for frame, texts in next, styled do
		text = CreateText(frame.healthOverlay, ns:GetElementAnchor(frame.unitKey, key), frame.unitKey, key)
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
			ApplyTextFont(text, frame.unitKey)

			if text.binding then
				text.binding:UpdateFontString()
			end
		end

		if frame.__unit then
			frame:UpdateTags()
		end
	end

	ns:DeferMethod(ns, "UpdateAuras")
end

ns.Style = Style
