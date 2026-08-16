local _, ns = ...

local MEDIA = [[Interface\AddOns\oUF_Mania\Media\]]

local BORDER_SIZE = 8
local BORDER_TRIM = 4 / 16
local BORDER_THICKNESS = BORDER_SIZE * (1 - BORDER_TRIM)
local CORNER_TRIM = 2 / 16
local CORNER_SIZE = BORDER_SIZE * (1 - CORNER_TRIM)
local DIVIDER_TRIM = 5 / 16
local DIVIDER_HEIGHT = BORDER_SIZE * (1 - 2 * DIVIDER_TRIM)
ns.BAR_INSET = BORDER_THICKNESS - 1
local BORDER_LEVEL = 5
local DIVIDER_LINE = BORDER_SIZE * (7 / 16 - DIVIDER_TRIM)
ns.BORDER_GAP = 6

local BACKGROUND_COLOR = { 0, 0, 0, 0.4 }

local MAX_DIVIDERS = 4
local MAX_PANELS = MAX_DIVIDERS + 1

local CORNER = "border-corner-bottom-right"

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

local function CreateBackground(frame)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetColorTexture(unpack(BACKGROUND_COLOR))
	return background
end

local function CreateDivider(frame, overlay)
	local divider = {}

	local line = CreateTexture(overlay, DIVIDER_LINE_TEXTURE, 0, 1, DIVIDER_TRIM, 1 - DIVIDER_TRIM)
	ns:SetPoint(line, "LEFT", frame, "LEFT", BORDER_THICKNESS, 0)
	ns:SetPoint(line, "RIGHT", frame, "RIGHT", -BORDER_THICKNESS, 0)
	ns:SetHeight(line, DIVIDER_HEIGHT)
	divider.line = line

	local side, inner, left, right, junction

	for _, entry in ipairs(SIDES) do
		side, left, right = unpack(entry)
		inner = side == "LEFT" and "RIGHT" or "LEFT"

		junction = CreateTexture(overlay, DIVIDER_END, left, right, DIVIDER_TRIM, 1 - DIVIDER_TRIM)
		ns:SetPoint(junction, "TOP" .. inner, line, "TOP" .. side, 0, 0)
		ns:SetSize(junction, BORDER_THICKNESS, DIVIDER_HEIGHT)
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
		panels[index] = CreateBackground(frame)
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

	ns:SetBorderDividers(frame)
end

function ns:SetBorderDividers(frame, anchors, count)
	count = count or 0

	local corners = frame.borderCorners
	local dividers = frame.borderDividers
	local panels = frame.borderPanels
	local divider, panel, side, edges, edge, above, below

	for index = 1, MAX_DIVIDERS do
		divider = dividers[index]

		if index <= count then
			ns:SetPoint(divider.line, "TOP", anchors[index], "BOTTOM", 0, DIVIDER_LINE)
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
				ns:SetPoint(panel, "TOPLEFT", frame, "TOPLEFT", BORDER_THICKNESS, -BORDER_THICKNESS)
			else
				ns:SetPoint(panel, "TOPLEFT", dividers[index - 1].line, "BOTTOMLEFT", 0, 0)
			end

			if index == count + 1 then
				ns:SetPoint(panel, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_THICKNESS,
					BORDER_THICKNESS)
			else
				ns:SetPoint(panel, "BOTTOMRIGHT", dividers[index].line, "TOPRIGHT", 0, 0)
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
end
