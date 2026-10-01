local _, ns = ...

local MEDIA = [[Interface\AddOns\oUF_Mania\Media\]]

local BORDER_SIZE = 8
local BORDER_TRIM = 4 / 16
local BORDER_THICKNESS = BORDER_SIZE * (1 - BORDER_TRIM)
local CORNER_TRIM = 2 / 16
local CORNER_SIZE = BORDER_SIZE * (1 - CORNER_TRIM)
local DIVIDER_TOP = 7 / 16
local DIVIDER_BOTTOM = 9 / 16
ns.BAR_INSET = BORDER_THICKNESS - 1
local BORDER_LEVEL = 5

local TEXTURE_TEXELS = 16
local EDGE_TEXELS = TEXTURE_TEXELS * (1 - BORDER_TRIM)
local DIVIDER_TEXELS = TEXTURE_TEXELS * (DIVIDER_BOTTOM - DIVIDER_TOP)
ns.BORDER_GAP = 6

local BACKGROUND_COLOR = { 0, 0, 0 }

local MAX_DIVIDERS = 4
local MAX_PANELS = MAX_DIVIDERS + 1

local CORNER = "border-corner-bottom-right"

local SHADE = "inner-shade"
local SHADE_SHEET_WIDTH = 64
local SHADE_SHEET_HEIGHT = 256
local SHADE_TEXELS = 2
local SHADE_PAD = 2
local SHADE_PITCH = 20
local SHADE_ROUNDED = 0
local SHADE_SQUARE = 1
local SHADE_EDGE = 2
ns.SHADE_SIZE_MIN = 1
ns.SHADE_SIZE_MAX = 8

local SHADE_CORNERS = {
	{ "TOPLEFT", false, false },
	{ "TOPRIGHT", true, false },
	{ "BOTTOMLEFT", false, true },
	{ "BOTTOMRIGHT", true, true },
}

local SHADE_EDGES = {
	{ "TOP", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", "BOTTOMLEFT" },
	{ "BOTTOM", "BOTTOMLEFT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMLEFT" },
	{ "LEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", "TOPRIGHT" },
	{ "RIGHT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT" },
}

local CORNERS = {
	{ "TOPLEFT", 1, CORNER_TRIM, 1, CORNER_TRIM },
	{ "TOPRIGHT", CORNER_TRIM, 1, 1, CORNER_TRIM },
	{ "BOTTOMLEFT", 1, CORNER_TRIM, CORNER_TRIM, 1 },
	{ "BOTTOMRIGHT", CORNER_TRIM, 1, CORNER_TRIM, 1 },
}

local HORIZONTAL_EDGES = {
	{ "TOP", 0, 1, 1, BORDER_TRIM },
	{ "BOTTOM", 0, 1, BORDER_TRIM, 1 },
}

local SIDES = {
	{ "LEFT", 1, BORDER_TRIM },
	{ "RIGHT", BORDER_TRIM, 1 },
}

local EDGE_H = "border-bottom"
local EDGE_V = "border-right"
local DIVIDER_END = "border-divider-right"
local DIVIDER_LINE_TEXTURE = "divider-line"

local function CreateTexture(parent, file, left, right, top, bottom)
	local texture = parent:CreateTexture(nil, "OVERLAY")
	texture:SetTexture(MEDIA .. file)
	texture:SetTexCoord(left, right, top, bottom)
	return texture
end

local function PointSideEdge(edge, side, from, fromPoint, to, toPoint)
	edge:ClearAllPoints()
	ns:SetPoint(edge, "TOP" .. side, from, fromPoint .. side, 0, 0)
	ns:SetPoint(edge, "BOTTOM" .. side, to, toPoint .. side, 0, 0)
	ns:SetWidth(edge, BORDER_THICKNESS)
end

local function CreateSideEdge(parent, side, left, right)
	return CreateTexture(parent, EDGE_V, left, right, 0, 1)
end

local function CreateShade(overlay)
	local shade = {}
	local texture

	for _, entry in ipairs(SHADE_CORNERS) do
		texture = overlay:CreateTexture(nil, "ARTWORK")
		texture:SetTexture(MEDIA .. SHADE)
		shade[entry[1]] = texture
	end

	for _, entry in ipairs(SHADE_EDGES) do
		texture = overlay:CreateTexture(nil, "ARTWORK")
		texture:SetTexture(MEDIA .. SHADE)
		texture:SetPoint("TOPLEFT", shade[entry[2]], entry[3], 0, 0)
		texture:SetPoint("BOTTOMRIGHT", shade[entry[4]], entry[5], 0, 0)
		shade[entry[1]] = texture
	end

	return shade
end

local function ShadeCell(column, size, pixels, total)
	local left = (column * SHADE_PITCH + SHADE_PAD) / SHADE_SHEET_WIDTH
	local top = ((size - 1) * SHADE_PITCH + SHADE_PAD) / SHADE_SHEET_HEIGHT
	local extent = size * SHADE_TEXELS * pixels / total
	return left, left + extent / SHADE_SHEET_WIDTH, top, top + extent / SHADE_SHEET_HEIGHT
end

local function SetEdgeTexCoord(texture, side, left, right, top, bottom)
	if side == "TOP" then
		texture:SetTexCoord(left, top, right, top, left, bottom, right, bottom)
	elseif side == "BOTTOM" then
		texture:SetTexCoord(right, top, left, top, right, bottom, left, bottom)
	elseif side == "LEFT" then
		texture:SetTexCoord(left, right, top, bottom)
	else
		texture:SetTexCoord(right, left, top, bottom)
	end
end

local function SetShadeShown(shade, shown)
	for _, texture in next, shade do
		texture:SetShown(shown)
	end
end

local function LayoutPanelShade(shade, panel, size, unit, roundedTop, roundedBottom)
	local width, height = panel:GetSize()
	local total = math.max(Round(size / unit), 1)
	local panelPixels = Round(math.min(width, height) / unit)
	local pixels = math.min(total, math.floor(panelPixels / 2))

	if pixels < 1 then
		SetShadeShown(shade, false)
		return
	end

	local extent = pixels * unit
	local point, flipX, flipY, rounded, texture
	local left, right, top, bottom

	for _, entry in ipairs(SHADE_CORNERS) do
		point, flipX, flipY = unpack(entry)
		rounded = flipY and roundedBottom or not flipY and roundedTop
		left, right, top, bottom = ShadeCell(rounded and SHADE_ROUNDED or SHADE_SQUARE, size, pixels, total)

		if flipX then
			left, right = right, left
		end

		if flipY then
			top, bottom = bottom, top
		end

		texture = shade[point]
		texture:SetTexCoord(left, right, top, bottom)
		texture:ClearAllPoints()
		texture:SetPoint(point, panel, point, 0, 0)
		texture:SetSize(extent, extent)
	end

	left, right, top, bottom = ShadeCell(SHADE_EDGE, size, pixels, total)

	for _, entry in ipairs(SHADE_EDGES) do
		SetEdgeTexCoord(shade[entry[1]], entry[1], left, right, top, bottom)
	end

	SetShadeShown(shade, true)
end

local bordered = setmetatable({}, { __mode = "k" })

function ns:GetShadeSize()
	return ns.db.shadeSize or ns.Defaults.shadeSize
end

local function LayoutShade(frame)
	local count = frame.borderPanelCount
	local panels = frame.borderPanels
	local size = ns:GetShadeSize()
	local unit = ns:PixelSize(frame.borderOverlay)

	for index, shade in ipairs(frame.borderShades) do
		if index <= count then
			LayoutPanelShade(shade, panels[index], size, unit, index == 1, index == count)
		else
			SetShadeShown(shade, false)
		end
	end
end

function ns:ApplyShadeSize()
	for frame in next, bordered do
		LayoutShade(frame)
	end
end

function ns:SetShadeSize(size)
	ns.db.shadeSize = size
	ns:ApplyShadeSize()
end

function ns:GetBackgroundAlpha()
	return ns.db.backgroundAlpha or ns.Defaults.backgroundAlpha
end

local function ApplyFrameBackground(frame, alpha)
	local r, g, b = unpack(BACKGROUND_COLOR)

	for _, panel in ipairs(frame.borderPanels) do
		panel:SetColorTexture(r, g, b, alpha)
	end
end

function ns:ApplyBackgroundAlpha()
	local alpha = ns:GetBackgroundAlpha()

	for frame in next, bordered do
		ApplyFrameBackground(frame, alpha)
	end
end

function ns:SetBackgroundAlpha(alpha)
	ns.db.backgroundAlpha = alpha
	ns:ApplyBackgroundAlpha()
end

local function CreateDivider(frame, overlay)
	local divider = {}

	local line = CreateTexture(overlay, DIVIDER_LINE_TEXTURE, 0, 1, DIVIDER_TOP, DIVIDER_BOTTOM)
	ns:SetPoint(line, "LEFT", frame, "LEFT", BORDER_THICKNESS, 0)
	ns:SetPoint(line, "RIGHT", frame, "RIGHT", -BORDER_THICKNESS, 0)
	divider.line = line

	local side, inner, left, right, junction

	for _, entry in ipairs(SIDES) do
		side, left, right = unpack(entry)
		inner = side == "LEFT" and "RIGHT" or "LEFT"

		junction = CreateTexture(overlay, DIVIDER_END, left, right, DIVIDER_TOP, DIVIDER_BOTTOM)
		ns:SetPoint(junction, "TOP" .. inner, line, "TOP" .. side, 0, 0)
		ns:SetWidth(junction, BORDER_THICKNESS)
		divider[side] = junction
	end

	return divider
end

function ns:CreateBorder(frame)
	local overlay = CreateFrame("Frame", nil, frame)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(frame:GetFrameLevel() + BORDER_LEVEL)
	frame.borderOverlay = overlay

	local corners = {}
	local point, side, left, right, top, bottom
	local corner, edge, edges

	for _, entry in ipairs(CORNERS) do
		point, left, right, top, bottom = unpack(entry)
		corner = CreateTexture(overlay, CORNER, left, right, top, bottom)
		ns:SetPoint(corner, point, overlay, point, 0, 0)
		ns:SetSize(corner, CORNER_SIZE, CORNER_SIZE)
		corners[point] = corner
	end

	for _, entry in ipairs(HORIZONTAL_EDGES) do
		side, left, right, top, bottom = unpack(entry)
		edge = CreateTexture(overlay, EDGE_H, left, right, top, bottom)
		ns:SetPoint(edge, side .. "LEFT", corners[side .. "LEFT"], side .. "RIGHT", 0, 0)
		ns:SetPoint(edge, side .. "RIGHT", corners[side .. "RIGHT"], side .. "LEFT", 0, 0)
		ns:SetHeight(edge, BORDER_THICKNESS)
	end

	local dividers = {}
	local panels = {}
	local sides = {}

	for index = 1, MAX_DIVIDERS do
		dividers[index] = CreateDivider(frame, overlay)
	end

	for index = 1, MAX_PANELS do
		panels[index] = frame:CreateTexture(nil, "BACKGROUND")
	end

	for _, entry in ipairs(SIDES) do
		side, left, right = unpack(entry)
		edges = {}

		for index = 1, MAX_PANELS do
			edges[index] = CreateSideEdge(overlay, side, left, right)
		end

		sides[side] = edges
	end

	frame.borderCorners = corners
	frame.borderDividers = dividers
	frame.borderPanels = panels
	frame.borderSides = sides
	frame.borderTextures = { overlay:GetRegions() }

	local shades = {}

	for index = 1, MAX_PANELS do
		shades[index] = CreateShade(overlay)
	end

	frame.borderShades = shades
	bordered[frame] = true

	frame:HookScript("OnSizeChanged", LayoutShade)

	ApplyFrameBackground(frame, ns:GetBackgroundAlpha())

	ns:SetBorderDividers(frame)
end

function ns:SetBorderColor(frame, r, g, b)
	for _, texture in ipairs(frame.borderTextures) do
		texture:SetVertexColor(r, g, b)
	end
end

function ns:SetBorderDividers(frame, anchors, count)
	count = count or 0

	local corners = frame.borderCorners
	local dividers = frame.borderDividers
	local panels = frame.borderPanels
	local divider, panel, side, edges, edge, above, below

	local unit = ns:PixelSize(frame.borderOverlay)
	local texelsPerPixel = EDGE_TEXELS / math.max(Round(BORDER_THICKNESS / unit), 1)
	local height = math.max(Round(DIVIDER_TEXELS / texelsPerPixel), 1) * unit
	local rimSize = (Round(BORDER_THICKNESS / unit) - Round(ns.BAR_INSET / unit)) * unit

	for index = 1, MAX_DIVIDERS do
		divider = dividers[index]

		if index <= count then
			divider.line:SetPoint("TOP", anchors[index], "BOTTOM", 0, 0)
			divider.line:SetHeight(height)
			divider.LEFT:SetHeight(height)
			divider.RIGHT:SetHeight(height)
		end

		divider.line:SetShown(index <= count)
		divider.LEFT:SetShown(index <= count)
		divider.RIGHT:SetShown(index <= count)
	end

	for index = 1, MAX_PANELS do
		panel = panels[index]

		if index <= count + 1 then
			panel:ClearAllPoints()

			if index == 1 then
				ns:SetPoint(panel, "TOPLEFT", frame, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
			else
				panel:SetPoint("TOPLEFT", dividers[index - 1].line, "BOTTOMLEFT", -rimSize, 0)
			end

			if index == count + 1 then
				ns:SetPoint(panel, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
			else
				panel:SetPoint("BOTTOMRIGHT", dividers[index].line, "TOPRIGHT", rimSize, 0)
			end
		end

		panel:SetShown(index <= count + 1)
	end

	for _, entry in ipairs(SIDES) do
		side = entry[1]
		edges = frame.borderSides[side]

		for index = 1, MAX_PANELS do
			edge = edges[index]

			if index <= count + 1 then
				above = index == 1 and corners["TOP" .. side] or dividers[index - 1][side]
				below = index == count + 1 and corners["BOTTOM" .. side] or dividers[index][side]
				PointSideEdge(edge, side, above, "BOTTOM", below, "TOP")
			end

			edge:SetShown(index <= count + 1)
		end
	end

	frame.borderPanelCount = count + 1
	LayoutShade(frame)
end
