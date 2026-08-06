local _, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local POWER_HEIGHT = 10
local CASTBAR_HEIGHT = 16
local TEXT_PADDING = 4
local BORDER_THICKNESS = 3
local BAR_PADDING = 0
local BORDER_GAP = 6

local BORDER_DARK = { 0, 0, 0, 1 }
local BORDER_LIGHT = { 0.32, 0.32, 0.32, 1 }
local BACKGROUND_COLOR = { 0, 0, 0, 0.8 }

local EDGES = {
	{ "TOPLEFT", "TOPRIGHT", "height" },
	{ "BOTTOMLEFT", "BOTTOMRIGHT", "height" },
	{ "TOPLEFT", "BOTTOMLEFT", "width" },
	{ "TOPRIGHT", "BOTTOMRIGHT", "width" },
}

local SIZE_ORDER = { "targettarget", "player", "target", "focus", "pet", "party", "raid", "boss" }

local SIZES = {
	player = { 200, 46 },
	target = { 200, 46 },
	focus = { 160, 36 },
	targettarget = { 120, 28 },
	pet = { 120, 28 },
	party = { 150, 36 },
	raid = { 80, 28 },
	boss = { 160, 36 },
}

local DEFAULT_SIZE = { 160, 36 }

local CASTBAR_UNITS = {
	player = true,
	target = true,
	focus = true,
	boss1 = true, boss2 = true, boss3 = true, boss4 = true, boss5 = true,
}

local function GetSize(unit)
	for _, prefix in ipairs(SIZE_ORDER) do
		if unit:match("^" .. prefix) then
			return unpack(SIZES[prefix])
		end
	end

	return unpack(DEFAULT_SIZE)
end

function ns:GetUnitSize(unit)
	return GetSize(unit)
end

local styled = setmetatable({}, { __mode = "k" })

function ns:GetFontFile()
	return LSM:Fetch("font", ManiaUFDB.font or LSM:GetDefault("font"))
end

function ns:GetTexture()
	return LSM:Fetch("statusbar", ManiaUFDB.texture or LSM:GetDefault("statusbar"))
end

local function CreateText(parent, justify)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFont(ns:GetFontFile(), ns:GetOption("fontSize"), "OUTLINE")
	text:SetJustifyH(justify)
	return text
end

local function CreateBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(ns:GetTexture())
	return bar
end

local function Offset(point, inset)
	local x = point:find("LEFT") and inset or -inset
	local y = point:find("TOP") and -inset or inset
	return x, y
end

local function CreateOutline(frame, level, color)
	for _, edge in ipairs(EDGES) do
		local line = frame:CreateTexture(nil, "OVERLAY")
		line:SetColorTexture(unpack(color))
		line.edge = edge
		line.level = level

		frame.borderLines[#frame.borderLines + 1] = line
	end
end

local function CreateBorder(frame)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(unpack(BACKGROUND_COLOR))

	frame.borderLines = {}

	CreateOutline(frame, 0, BORDER_DARK)
	CreateOutline(frame, 1, BORDER_LIGHT)
	CreateOutline(frame, 2, BORDER_DARK)
end

local function PlaceOutlines(frame)
	local pixel = ns:PixelSize(frame, 1)

	for _, line in ipairs(frame.borderLines) do
		local first, second, axis = unpack(line.edge)
		local inset = pixel * line.level

		local firstX, firstY = Offset(first, inset)
		local secondX, secondY = Offset(second, inset)
		ns:SetPoint(line, first, frame, first, firstX, firstY)
		ns:SetPoint(line, second, frame, second, secondX, secondY)

		if axis == "height" then
			ns:SetHeight(line, pixel)
		else
			ns:SetWidth(line, pixel)
		end
	end
end

local function PlaceBars(frame)
	local pixel = ns:PixelSize(frame, 1)
	local inset = pixel * (BORDER_THICKNESS + BAR_PADDING)

	ns:SetSize(frame, unpack(frame.unitSize))

	ns:SetPoint(frame.Power, "BOTTOMLEFT", frame, "BOTTOMLEFT", inset, inset)
	ns:SetPoint(frame.Power, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
	ns:SetHeight(frame.Power, POWER_HEIGHT)

	ns:SetPoint(frame.Health, "TOPLEFT", frame, "TOPLEFT", inset, -inset)
	ns:SetPoint(frame.Health, "TOPRIGHT", frame, "TOPRIGHT", -inset, -inset)
	ns:SetPoint(frame.Health, "BOTTOMLEFT", frame.Power, "TOPLEFT", 0, pixel)
	ns:SetPoint(frame.Health, "BOTTOMRIGHT", frame.Power, "TOPRIGHT", 0, pixel)

	if frame.Castbar then
		ns:SetPoint(frame.Castbar, "TOPLEFT", frame, "BOTTOMLEFT", 0, -BORDER_GAP)
		ns:SetPoint(frame.Castbar, "TOPRIGHT", frame, "BOTTOMRIGHT", 0, -BORDER_GAP)
		ns:SetHeight(frame.Castbar, CASTBAR_HEIGHT)
		PlaceOutlines(frame.Castbar)
	end
end

local function Style(self, unit)
	unit = unit or ""

	local width, height = GetSize(unit)

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self.unitSize = { width, height }

	CreateBorder(self)

	local power = CreateBar(self)
	power.colorPower = true
	self.Power = power

	local health = CreateBar(self)
	health.colorClass = true
	health.colorReaction = true
	health.colorHealth = true
	self.Health = health

	local healthValue = CreateText(health, "RIGHT")
	healthValue:SetPoint("RIGHT", health, "RIGHT", -TEXT_PADDING, 0)
	self:Tag(healthValue, "[status][perhp]%")

	local name = CreateText(health, "LEFT")
	name:SetPoint("LEFT", health, "LEFT", TEXT_PADDING, 0)
	name:SetPoint("RIGHT", healthValue, "LEFT", -TEXT_PADDING, 0)
	name:SetWordWrap(false)
	self:Tag(name, "[difficulty][smartlevel] [name]")

	local texts = { name, healthValue }

	if CASTBAR_UNITS[unit] then
		local castbar = CreateBar(self)
		CreateBorder(castbar)

		local castbarText = CreateText(castbar, "LEFT")
		castbarText:SetPoint("LEFT", castbar, "LEFT", TEXT_PADDING, 0)
		castbar.Text = castbarText

		local castbarTime = CreateText(castbar, "RIGHT")
		castbarTime:SetPoint("RIGHT", castbar, "RIGHT", -TEXT_PADDING, 0)
		castbar.Time = castbarTime

		self.Castbar = castbar

		texts[#texts + 1] = castbarText
		texts[#texts + 1] = castbarTime
	end

	styled[self] = texts

	PlaceOutlines(self)
	PlaceBars(self)
end

function ns:UpdatePixelGeometry()
	for frame in next, styled do
		PlaceOutlines(frame)
		PlaceBars(frame)
	end
end

function ns:ApplyMedia()
	local font = ns:GetFontFile()
	local size = ns:GetOption("fontSize")
	local texture = ns:GetTexture()

	for frame, texts in next, styled do
		frame.Health:SetStatusBarTexture(texture)
		frame.Power:SetStatusBarTexture(texture)

		if frame.Castbar then
			frame.Castbar:SetStatusBarTexture(texture)
		end

		for _, text in ipairs(texts) do
			text:SetFont(font, size, "OUTLINE")
		end
	end
end

ns.Style = Style
