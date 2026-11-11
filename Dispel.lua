local _, ns = ...

local SLOT_KEY = "dispel"
local FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local TINT_KEY = "dispelTint"
local ICON_KEY = "dispelIcon"
local GLOW_KEY = "dispelGlow"
local BORDER_KEY = "dispelBorder"
local FILL_KEY = "healthbarDispel"
local WHITE = [[Interface\Buttons\WHITE8X8]]
local TINT_ALPHA = 0.35
local ICON_SIZE = 20
local GLOW_REACH = 8
local PREVIEW_TYPE = "Magic"
local PREVIEW_ICON = "RaidFrame-Icon-DebuffMagic"
local COLOR_STYLE = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset
local ICON_STYLE = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon

local function CreatePart(parent, level)
	local part = CreateFrame("Frame", nil, parent)
	part:SetFrameLevel(level)
	return part
end

local function BuildParts(frame, parent, Register)
	local parts = {}
	local healthTexture = frame.Health:GetStatusBarTexture()

	local fill = CreatePart(parent, frame.Health:GetFrameLevel() + 1)
	local texture = fill:CreateTexture(nil, "ARTWORK")
	texture:SetTexture(healthTexture:GetTexture())
	texture:SetAllPoints(healthTexture)
	Register(texture, COLOR_STYLE)
	parts.fill = fill
	parts.fillTexture = texture

	local tint = CreatePart(parent, frame.healthOverlay:GetFrameLevel() - 1)
	tint:SetAlpha(TINT_ALPHA)
	texture = tint:CreateTexture(nil, "ARTWORK")
	texture:SetTexture(WHITE)
	texture:SetAllPoints(frame.healthBox)
	Register(texture, COLOR_STYLE)
	parts.tint = tint

	local icon = CreatePart(parent, frame.healthOverlay:GetFrameLevel() + 1)
	texture = icon:CreateTexture(nil, "ARTWORK")
	ns:SetSize(texture, ICON_SIZE, ICON_SIZE)
	texture:SetPoint("CENTER", frame.healthBox, "CENTER", 0, 0)
	Register(texture, ICON_STYLE)
	parts.icon = icon

	local glow = ns:CreateGlow(parent)
	glow:SetFrameLevel(frame:GetFrameLevel())
	ns:PlaceGlow(frame, glow, GLOW_REACH)

	for _, piece in ipairs(glow.pieces) do
		Register(piece, COLOR_STYLE)
	end

	parts.glow = glow

	local border = CreatePart(parent, frame:GetFrameLevel() + 1)
	border:SetAllPoints(frame)
	ns:CreateBorder(border, true)
	border.shadeFixed = true
	border.borderPanels[1]:Hide()

	for _, shade in next, border.borderShades[1] do
		shade:Hide()
	end

	for _, edge in ipairs(border.borderTextures) do
		ns:SetBorderTextureBright(edge, true)
		Register(edge, COLOR_STYLE)
	end

	parts.border = border

	return parts
end

local function ShowParts(parts, fill, tint, icon, glow, border)
	parts.fill:SetShown(fill)
	parts.tint:SetShown(tint)
	parts.icon:SetShown(icon)
	parts.glow:SetShown(glow)
	parts.border:SetShown(border)
end

local function CreateDispel(frame)
	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	local colorOptions = {
		style = COLOR_STYLE,
		showWhenHarmful = true,
		customDispelColorMap = frame.colors.dispel,
	}
	local iconOptions = {
		style = ICON_STYLE,
		showWhenHarmful = true,
	}

	container:SetEditModePreviewEnabled(false)
	container:AddAuraSlot(SLOT_KEY, FILTER, {
		initializeFrame = function(button)
			button:EnableMouse(false)
			button:SetAllPoints(frame)
			button:Hide()

			frame.dispelParts = BuildParts(frame, button, function(texture, style)
				button:AddDispelTypeTexture(texture, style == ICON_STYLE and iconOptions or colorOptions)
			end)
		end,
	})

	frame.dispelContainer = container
	return container
end

local function CreatePreview(frame)
	local preview = CreateFrame("Frame", nil, frame)
	local color = frame.colors.dispel[PREVIEW_TYPE]

	preview:SetAllPoints()
	preview.parts = BuildParts(frame, preview, function(texture, style)
		if style == ICON_STYLE then
			texture:SetAtlas(PREVIEW_ICON)
		else
			texture:SetVertexColor(color:GetRGB())
		end
	end)

	frame.dispelPreview = preview
	return preview
end

function ns.RefreshDispel(frame)
	local container = frame.dispelContainer
	local unit = frame.__unit

	if not (container and container.active and unit) then
		return
	end

	local assist = UnitCanAssist("player", unit)

	container:SetEnabled(assist)
	container:SetShown(assist)

	if not assist then
		return
	end

	if container:GetUnit() ~= unit then
		container:SetUnit(unit)
	else
		container:UpdateAllAuras()
	end
end

function ns:ApplyDispel(frame)
	local unit = frame.unitKey
	local has = ns:HasElement(unit, ns.DISPEL_SECTION)
	local tint = has and ns:IsElementShown(unit, TINT_KEY)
	local icon = has and ns:IsElementShown(unit, ICON_KEY)
	local glow = has and ns:IsElementShown(unit, GLOW_KEY)
	local border = has and ns:IsElementShown(unit, BORDER_KEY)
	local fill = ns:IsElementShown(unit, FILL_KEY)
	local active = fill or tint or icon or glow or border
	local preview = active and ns:ShouldPreview(unit, ns.DISPEL_SECTION)
	local live = active and not preview
	local container = frame.dispelContainer

	if preview then
		preview = frame.dispelPreview or CreatePreview(frame)
		ShowParts(preview.parts, fill, tint, icon, glow, border)
		preview:Show()
	elseif frame.dispelPreview then
		frame.dispelPreview:Hide()
	end

	if not (live or container) then
		return
	end

	container = container or CreateDispel(frame)
	container.active = live

	if not live then
		container:SetEnabled(false)
		container:Hide()
		frame:UnregisterEvent("UNIT_FACTION", ns.RefreshDispel)
		return
	end

	ShowParts(frame.dispelParts, fill, tint, icon, glow, border)
	frame:RegisterEvent("UNIT_FACTION", ns.RefreshDispel)
	ns.RefreshDispel(frame)
end

function ns:ApplyDispelTexture(frame, texture)
	if frame.dispelParts then
		frame.dispelParts.fillTexture:SetTexture(texture)
	end

	if frame.dispelPreview then
		frame.dispelPreview.parts.fillTexture:SetTexture(texture)
	end
end
