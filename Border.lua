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

local function CreateSideEdge(parent, side, left, right, from, fromPoint, to, toPoint)
	local edge = CreateTexture(parent, EDGE_V, left, right, 0, 1)
	ns:SetPoint(edge, "TOP" .. side, from, fromPoint .. side, 0, 0)
	ns:SetPoint(edge, "BOTTOM" .. side, to, toPoint .. side, 0, 0)
	ns:SetWidth(edge, BORDER_THICKNESS)
	return edge
end

local function CreateBackground(frame)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetColorTexture(unpack(BACKGROUND_COLOR))
	return background
end

function ns:CreateBorder(frame, dividerAnchor)
	local overlay = CreateFrame("Frame", nil, frame)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(frame:GetFrameLevel() + BORDER_LEVEL)
	frame.borderOverlay = overlay

	local corners = {}
	local point, side, inner, left, right, top, bottom
	local corner, edge, junction

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

	local whole = {}

	for _, entry in ipairs(SIDES) do
		side, left, right = unpack(entry)
		whole[#whole + 1] = CreateSideEdge(overlay, side, left, right, corners["TOP" .. side], "BOTTOM",
			corners["BOTTOM" .. side], "TOP")
	end

	local background = CreateBackground(frame)
	ns:SetPoint(background, "TOPLEFT", frame, "TOPLEFT", BORDER_THICKNESS, -BORDER_THICKNESS)
	ns:SetPoint(background, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_THICKNESS, BORDER_THICKNESS)
	whole[#whole + 1] = background

	frame.wholeEdges = whole

	if not dividerAnchor then
		return
	end

	local split = {}

	local line = CreateTexture(overlay, DIVIDER_LINE_TEXTURE, 0, 1, DIVIDER_TRIM, 1 - DIVIDER_TRIM)
	ns:SetPoint(line, "TOP", dividerAnchor, "BOTTOM", 0, DIVIDER_LINE)
	ns:SetPoint(line, "LEFT", frame, "LEFT", BORDER_THICKNESS, 0)
	ns:SetPoint(line, "RIGHT", frame, "RIGHT", -BORDER_THICKNESS, 0)
	ns:SetHeight(line, DIVIDER_HEIGHT)
	split[#split + 1] = line

	local above = CreateBackground(frame)
	ns:SetPoint(above, "TOPLEFT", frame, "TOPLEFT", BORDER_THICKNESS, -BORDER_THICKNESS)
	ns:SetPoint(above, "BOTTOMRIGHT", line, "TOPRIGHT", 0, 0)
	split[#split + 1] = above

	local below = CreateBackground(frame)
	ns:SetPoint(below, "TOPLEFT", line, "BOTTOMLEFT", 0, 0)
	ns:SetPoint(below, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER_THICKNESS, BORDER_THICKNESS)
	split[#split + 1] = below

	for _, entry in ipairs(SIDES) do
		side, left, right = unpack(entry)
		inner = side == "LEFT" and "RIGHT" or "LEFT"

		junction = CreateTexture(overlay, DIVIDER_END, left, right, DIVIDER_TRIM, 1 - DIVIDER_TRIM)
		ns:SetPoint(junction, "TOP" .. inner, line, "TOP" .. side, 0, 0)
		ns:SetSize(junction, BORDER_THICKNESS, DIVIDER_HEIGHT)
		split[#split + 1] = junction

		split[#split + 1] = CreateSideEdge(overlay, side, left, right, corners["TOP" .. side], "BOTTOM",
			junction, "TOP")
		split[#split + 1] = CreateSideEdge(overlay, side, left, right, junction, "BOTTOM",
			corners["BOTTOM" .. side], "TOP")
	end

	frame.splitEdges = split
end

function ns:ApplyPowerShown(frame)
	local shown = frame.powerShown

	frame.Power:SetShown(shown)

	for _, region in ipairs(frame.splitEdges) do
		region:SetShown(shown)
	end

	for _, region in ipairs(frame.wholeEdges) do
		region:SetShown(not shown)
	end

	if shown then
		ns:SetPoint(frame.healthBox, "BOTTOMLEFT", frame.Power, "TOPLEFT", 0, 0)
		ns:SetPoint(frame.healthBox, "BOTTOMRIGHT", frame.Power, "TOPRIGHT", 0, 0)
	else
		ns:SetPoint(frame.healthBox, "BOTTOMLEFT", frame, "BOTTOMLEFT", ns.BAR_INSET, ns.BAR_INSET)
		ns:SetPoint(frame.healthBox, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -ns.BAR_INSET,
			ns.BAR_INSET)
	end
end

function ns:SetPowerShown(frame, shown)
	if frame.powerShown == shown then
		return
	end

	frame.powerShown = shown
	ns:ApplyPowerShown(frame)
end
