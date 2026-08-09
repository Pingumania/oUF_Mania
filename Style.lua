local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local issecretvalue = issecretvalue

local DEFAULT_FONT_SIZE = 12
local FONT_SIZE_MIN = 8
local FONT_SIZE_MAX = 20

local CASTBAR_HEIGHT = 16
local PREVIEW_UNIT = "player"
local SPARK_ATLAS = "ui-castingbar-pip"
local SPARK_OVERHANG = 4
local SPARK_RATIO = 0.4

local styled = setmetatable({}, { __mode = "k" })

ns.TEXT_PADDING = 4

function ns:GetFontFile()
	return LSM:Fetch("font", ManiaUFDB.font or LSM:GetDefault("font"))
end

function ns:GetTexture()
	return LSM:Fetch("statusbar", ManiaUFDB.texture or LSM:GetDefault("statusbar"))
end

function ns:GetFontSize()
	return ManiaUFDB.fontSize or DEFAULT_FONT_SIZE
end

function ns:GetFontSizeRange()
	return FONT_SIZE_MIN, FONT_SIZE_MAX
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

local function PowerPostUpdate(element, unit, _, _, max)
	local key = element.__owner.unitKey
	local shown

	if not ns:IsUnitPowerShown(key) then
		shown = false
	elseif ns:IsHealerPowerOnly(key) and IsHealer(unit) == false then
		shown = false
	elseif issecretvalue(max) then
		shown = true
	else
		shown = (max or 0) > 0
	end

	ns:SetPowerShown(element.__owner, shown)
end

local function LayoutFrame(frame)
	local width, height, powerHeight = ns:GetUnitSizes(frame.unitKey)

	ns:SetSize(frame, width, height)

	ns:SetPoint(frame.Health, "TOPLEFT", frame, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
	ns:SetPoint(frame.Health, "TOPRIGHT", frame, "TOPRIGHT", -ns.BAR_INSET, -ns.BAR_INSET)

	ns:SetPoint(frame.Power, "BOTTOMLEFT", frame, "BOTTOMLEFT", ns.BAR_INSET, ns.BAR_INSET)
	ns:SetPoint(frame.Power, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
	ns:SetHeight(frame.Power, powerHeight)

	ns:ApplyPowerShown(frame)

	if frame.Castbar then
		local x, y = ns:GetElementOffset(frame.unitKey, "castbar")
		local border = frame.castbarBorder

		ns:SetPoint(border, "TOPLEFT", frame, "BOTTOMLEFT", x, -ns.BORDER_GAP + y)
		ns:SetPoint(border, "TOPRIGHT", frame, "BOTTOMRIGHT", x, -ns.BORDER_GAP + y)
		ns:SetHeight(border, CASTBAR_HEIGHT + 2 * ns.BAR_INSET)

		ns:SetPoint(frame.Castbar, "TOPLEFT", border, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(frame.Castbar, "BOTTOMRIGHT", border, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)

		local boxHeight = CASTBAR_HEIGHT + 2 * ns.BAR_INSET
		local icon = frame.Castbar.Icon
		local iconX, iconY = ns:GetElementOffset(frame.unitKey, "castbarIcon")

		icon:ClearAllPoints()

		if ns:GetElementAnchor(frame.unitKey, "castbarIcon") == "RIGHT" then
			ns:SetPoint(icon, "TOPLEFT", border, "TOPRIGHT", ns.BORDER_GAP + iconX, iconY)
		else
			ns:SetPoint(icon, "TOPRIGHT", border, "TOPLEFT", -ns.BORDER_GAP + iconX, iconY)
		end

		ns:SetSize(icon, boxHeight, boxHeight)
		local sparkHeight = CASTBAR_HEIGHT + SPARK_OVERHANG
		ns:SetSize(frame.Castbar.Spark, sparkHeight * SPARK_RATIO, sparkHeight)
	end

	ns:PlaceElements(frame)
end

local function Style(self, unit)
	unit = unit or ""

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self.unitKey = ns:GetUnitKey(unit)

	local power = CreateBar(self)
	power.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	power.frequentUpdates = unit == "player"
	power.colorTapping = true
	power.colorDisconnected = true
	power.colorPower = true
	power.PostUpdate = PowerPostUpdate
	self.Power = power

	local health = CreateBar(self)
	health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorClass = true
	health.colorReaction = true
	health.colorHealth = true
	self.Health = health

	local costPrediction = CreateBar(power)
	costPrediction:SetReverseFill(true)
	costPrediction:SetPoint("TOP", power, "TOP", 0, 0)
	costPrediction:SetPoint("BOTTOM", power, "BOTTOM", 0, 0)
	costPrediction:SetPoint("RIGHT", power:GetStatusBarTexture(), "RIGHT", 0, 0)
	power.CostPrediction = costPrediction

	ns:CreateBorder(self, health)

	self.elements = {}

	local texts = {}

	for _, element in ipairs(ns.TEXT_ELEMENTS) do
		self.elements[element] = CreateText(health, ns:GetElementAnchor(self.unitKey, element))
		texts[#texts + 1] = self.elements[element]
	end

	ns:CreateIndicators(self)

	if unit == "player" then
		local resting = ns:CreateRestingIndicator(self)
		self.RestingIndicator = resting
		self.elements.resting = resting
	end

	if ns:HasElement(self.unitKey, "castbar") then
		local castbar = CreateBar(self)

		local border = CreateFrame("Frame", nil, self)
		border:SetFrameLevel(self:GetFrameLevel())
		ns:CreateBorder(border)
		border:SetShown(castbar:IsShown())

		castbar:HookScript("OnShow", function()
			border:Show()
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
		spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
		castbar.Spark = spark

		local shield = castbar:CreateTexture(nil, "OVERLAY")
		shield:SetAllPoints(border)
		castbar.Shield = shield

		castbar.Icon = border:CreateTexture(nil, "ARTWORK")
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
		end

		if frame.Power and texture then
			frame.Power:SetStatusBarTexture(texture)
			frame.Power.CostPrediction:SetStatusBarTexture(texture)
		end

		if frame.Castbar and texture then
			frame.Castbar:SetStatusBarTexture(texture)
		end

		for _, text in ipairs(texts) do
			SetTextFont(text, font, size)
		end

		if frame.__unit then
			frame:UpdateTags()
		end
	end
end

ns.Style = Style
