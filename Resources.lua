local _, ns = ...
local oUF = ns.oUF

local MAX_CLASS_POWER = 10
local MAX_RUNES = 6
local PIP_DIVIDER_COLOR = { 0, 0, 0, 0.6 }

local PREVIEW_FILL = 0.6

local CLASS_SLOT = "classresource"
local POWER_SLOT = "additionalpower"

ns.CLASS_SLOT = CLASS_SLOT
ns.POWER_SLOT = POWER_SLOT
ns.RESOURCE_SLOTS = { POWER_SLOT, CLASS_SLOT }

local slotFrames = {}

local SLOT_ELEMENTS = {
	[CLASS_SLOT] = { "ClassPower", "Runes", "Stagger" },
	[POWER_SLOT] = { "AdditionalPower" },
}

local function CreateBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(ns:GetTexture())
	return bar
end

local function CreatePip(parent)
	local pip = CreateBar(parent)

	local divider = pip:CreateTexture(nil, "OVERLAY")
	divider:SetColorTexture(unpack(PIP_DIVIDER_COLOR))
	pip.divider = divider

	return pip
end

local function SlotColor(frame, key)
	local mode = ns:GetElementColorMode(frame.unitKey, key)

	if mode == "class" then
		local color = oUF.colors.class[UnitClassBase("player")]

		if color then
			return color:GetRGB()
		end
	elseif mode == "custom" then
		return ns:GetElementColor(frame.unitKey, key)
	end
end

local function BarPostUpdateColor(element)
	local r, g, b = SlotColor(element.__owner, element.slotKey)

	if r then
		element:SetStatusBarColor(r, g, b)
	end
end

local function PipsPostUpdateColor(element)
	local r, g, b = SlotColor(element.__owner, element.slotKey)

	if not r then
		return
	end

	for index = 1, #element do
		element[index]:SetStatusBarColor(r, g, b)
	end
end

local function Relayout(frame)
	ns:DeferMethod(ns, "UpdatePixelGeometry", frame.unitKey)
end

local function ClassPowerPostVisibility(element, isVisible)
	local frame = element.__owner

	frame.classPowerShown = isVisible or nil
	Relayout(frame)
end

local function ClassPowerPostUpdate(element, _, max, _, hasMaxChanged)
	if not hasMaxChanged then
		return
	end

	local frame = element.__owner

	frame.classPowerMax = max
	ns:LayoutResourceBars(frame)
end

local function StaggerPostVisibility(element, isVisible)
	local frame = element.__owner

	frame.staggerShown = isVisible or nil
	Relayout(frame)
end

local function AdditionalPowerPostVisibility(element, isVisible)
	local frame = element.__owner

	frame.additionalPowerShown = isVisible or nil
	Relayout(frame)
end

local function BuildClassSlot(frame, holder)
	local pips = {}

	for index = 1, MAX_CLASS_POWER do
		pips[index] = CreatePip(holder)
	end

	pips.slotKey = CLASS_SLOT
	pips.PostUpdateColor = PipsPostUpdateColor
	pips.PostVisibility = ClassPowerPostVisibility
	pips.PostUpdate = ClassPowerPostUpdate
	frame.ClassPower = pips

	local runes = {}

	for index = 1, MAX_RUNES do
		runes[index] = CreatePip(holder)
	end

	runes.slotKey = CLASS_SLOT
	runes.PostUpdateColor = PipsPostUpdateColor
	frame.Runes = runes

	local stagger = CreateBar(holder)
	stagger:SetAllPoints(holder)
	stagger.slotKey = CLASS_SLOT
	stagger.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	stagger.PostUpdateColor = BarPostUpdateColor
	stagger.PostVisibility = StaggerPostVisibility
	frame.Stagger = stagger
end

local function BuildPowerSlot(frame, holder)
	local bar = CreateBar(holder)
	bar:SetAllPoints(holder)
	bar.slotKey = POWER_SLOT
	bar.frequentUpdates = true
	bar.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
	bar.colorPower = true
	bar.PostUpdateColor = BarPostUpdateColor
	bar.PostVisibility = AdditionalPowerPostVisibility
	frame.AdditionalPower = bar
end

local BUILDERS = {
	[CLASS_SLOT] = BuildClassSlot,
	[POWER_SLOT] = BuildPowerSlot,
}

local function EnsureSlot(frame, key)
	local slots = frame.resourceSlots

	if slots and slots[key] then
		return slots[key]
	end

	slots = slots or {}
	frame.resourceSlots = slots

	local holder = CreateFrame("Frame", nil, frame)
	holder:Hide()

	local box = CreateFrame("Frame", nil, frame)
	box:SetFrameLevel(frame:GetFrameLevel())
	ns:CreateBorder(box)
	box:Hide()

	local slot = { holder = holder, box = box }
	slots[key] = slot
	slotFrames[frame.unitKey] = frame

	BUILDERS[key](frame, holder)

	return slot
end

local function ForEachSlotBar(frame, key, Apply, ...)
	local element

	for _, name in ipairs(SLOT_ELEMENTS[key]) do
		element = frame[name]

		if element and element.SetStatusBarColor then
			Apply(element, ...)
		elseif element then
			for index = 1, #element do
				Apply(element[index], ...)
			end
		end
	end
end

local function ClearOccupancy(frame, key)
	if key == CLASS_SLOT then
		frame.classPowerShown = nil
		frame.staggerShown = nil
	else
		frame.additionalPowerShown = nil
	end
end

local function LiveClassBars(frame)
	if frame.staggerShown then
		return frame.Stagger, 1
	elseif frame.classPowerShown then
		return frame.ClassPower, frame.classPowerMax or 0
	elseif frame:IsElementEnabled("Runes") then
		return frame.Runes, MAX_RUNES
	end
end

local function ClassSlotBars(frame)
	local slot = frame.resourceSlots and frame.resourceSlots[CLASS_SLOT]

	if slot and slot.previewed then
		return slot.previewBars, slot.previewCount
	end

	return LiveClassBars(frame)
end

function ns:IsResourceSlotFilled(frame, key)
	local slot = frame.resourceSlots and frame.resourceSlots[key]

	if not slot then
		return false
	elseif slot.previewed then
		return slot.previewBars ~= nil
	elseif not ns:IsElementShown(frame.unitKey, key) then
		return false
	elseif key == POWER_SLOT then
		return not not frame.additionalPowerShown
	end

	return ClassSlotBars(frame) ~= nil
end

function ns:GetResourceSlotRegion(frame, key)
	local slot = frame.resourceSlots and frame.resourceSlots[key]
	return slot and slot.holder
end

function ns:SnapWidthToPips(key, width)
	local frame = slotFrames[key]

	if not frame or not ns:IsResourceSlotFilled(frame, CLASS_SLOT) then
		return width
	elseif not ns:IsElementPixelSnapped(key, CLASS_SLOT) then
		return width
	end

	local placement = ns:GetElementPlacement(key, CLASS_SLOT)

	if placement ~= ns.PLACEMENT_INSIDE and placement ~= ns.PLACEMENT_OUTSIDE then
		return width
	end

	local bars, count = ClassSlotBars(frame)

	if not bars or bars == frame.Stagger or not count or count < 2 then
		return width
	end

	local unit = ns:PixelSize(frame, 1)
	local inset = math.floor(ns.BAR_INSET / unit + 0.5)
	local pixels = math.floor(width / unit + 0.5)
	local remainder = (pixels - 2 * inset) % count

	if remainder == 0 then
		return width
	elseif remainder * 2 <= count then
		return (pixels - remainder) * unit
	end

	return (pixels + count - remainder) * unit
end

local function LayoutPips(pips, holder, count, width)
	local unit = ns:PixelSize(holder, 1)
	local inset = math.floor(ns.BAR_INSET / unit + 0.5)
	local total = math.floor(width / unit + 0.5) - 2 * inset
	local size = math.max(1, math.floor(total / count))
	local extra = total - size * count
	local pip, divider, previous

	for index = 1, count do
		pip = pips[index]
		divider = pip.divider

		pip:ClearAllPoints()

		if previous then
			ns:SetPoint(pip, "TOPLEFT", previous, "TOPRIGHT", 0, 0)
			ns:SetPoint(pip, "BOTTOMLEFT", previous, "BOTTOMRIGHT", 0, 0)
		else
			ns:SetPoint(pip, "TOPLEFT", holder, "TOPLEFT", 0, 0)
			ns:SetPoint(pip, "BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
		end

		ns:SetWidth(pip, (index <= extra and size + 1 or size) * unit)

		divider:ClearAllPoints()
		ns:SetPoint(divider, "TOPRIGHT", pip, "TOPRIGHT", 0, 0)
		ns:SetPoint(divider, "BOTTOMRIGHT", pip, "BOTTOMRIGHT", 0, 0)
		ns:SetWidth(divider, unit)
		divider:SetShown(index < count)

		previous = pip
	end
end

function ns:LayoutResourceBars(frame)
	local slot = frame.resourceSlots and frame.resourceSlots[CLASS_SLOT]
	local width = slot and slot.outerWidth

	if not width or width <= 0 then
		return
	end

	local bars, count = ClassSlotBars(frame)

	if bars and count > 0 and bars ~= frame.Stagger then
		LayoutPips(bars, slot.holder, count, width)
	end
end

function ns:PlaceResourceSlot(frame, key, placement, stackY)
	local slot = frame.resourceSlots and frame.resourceSlots[key]

	if not slot then
		return
	end

	local boxed = placement == ns.PLACEMENT_OUTSIDE or placement == ns.PLACEMENT_FREE

	if not boxed then
		slot.box:Hide()
	end

	if not placement then
		slot.holder:Hide()
		return
	end

	local unit = frame.unitKey
	local height = ns:GetElementSize(unit, key)

	if placement == ns.PLACEMENT_FREE then
		slot.outerWidth = ns:GetElementSize(unit, key .. "Width")
	else
		slot.outerWidth = ns:GetUnitSizes(unit)
	end

	slot.holder:ClearAllPoints()
	slot.holder:Show()

	if placement == ns.PLACEMENT_FREE then
		local x, y = ns:GetElementPosition(unit, key)

		slot.box:ClearAllPoints()
		ns:SetPoint(slot.box, "BOTTOM", UIParent, "BOTTOM", x, y)
		ns:SetSize(slot.box, slot.outerWidth, height + 2 * ns.BAR_INSET)
		ns:SnapToPixelGrid(slot.box)
		slot.box:Show()

		ns:SetPoint(slot.holder, "TOPLEFT", slot.box, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(slot.holder, "BOTTOMRIGHT", slot.box, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
	elseif placement == ns.PLACEMENT_OUTSIDE then
		local x, y = ns:GetElementOffset(unit, key)

		slot.box:ClearAllPoints()
		ns:SetPoint(slot.box, "TOPLEFT", frame, "BOTTOMLEFT", x, stackY + y)
		ns:SetPoint(slot.box, "TOPRIGHT", frame, "BOTTOMRIGHT", x, stackY + y)
		ns:SetHeight(slot.box, height + 2 * ns.BAR_INSET)
		slot.box:Show()

		ns:SetPoint(slot.holder, "TOPLEFT", slot.box, "TOPLEFT", ns.BAR_INSET, -ns.BAR_INSET)
		ns:SetPoint(slot.holder, "BOTTOMRIGHT", slot.box, "BOTTOMRIGHT", -ns.BAR_INSET, ns.BAR_INSET)
	end
end

local function ApplySlot(frame, key)
	local shown = ns:IsElementShown(frame.unitKey, key)

	if not shown and not (frame.resourceSlots and frame.resourceSlots[key]) then
		return
	end

	EnsureSlot(frame, key)

	for _, element in ipairs(SLOT_ELEMENTS[key]) do
		if not shown then
			frame:DisableElement(element)
		elseif not frame:IsElementEnabled(element) then
			frame:EnableElement(element)

			if frame:IsElementEnabled(element) and frame.__unit then
				frame[element]:ForceUpdate()
			end
		end
	end

	if not shown then
		ClearOccupancy(frame, key)
	end
end

local function PreviewColor(frame, key)
	local r, g, b = SlotColor(frame, key)

	if r then
		return r, g, b
	end

	local color = oUF.colors.class[UnitClassBase("player")]

	if color then
		return color:GetRGB()
	end

	return 1, 1, 1
end

local function HideBar(bar)
	bar:Hide()
end

local function PreviewBars(frame, key)
	if key == POWER_SLOT then
		return frame.AdditionalPower, 1
	end

	return LiveClassBars(frame)
end

local function ShowSlotPreview(frame, key)
	local slot = EnsureSlot(frame, key)

	if not slot.previewed then
		local bars, count = PreviewBars(frame, key)

		if bars and count > 0 then
			slot.previewBars = bars
			slot.previewCount = count
		end

		slot.previewed = true
		Relayout(frame)
	end

	for _, element in ipairs(SLOT_ELEMENTS[key]) do
		frame:DisableElement(element)
	end

	ClearOccupancy(frame, key)
	ForEachSlotBar(frame, key, HideBar)

	local bars = slot.previewBars

	if not bars then
		return
	end

	local r, g, b = PreviewColor(frame, key)

	if bars.SetStatusBarColor then
		bars:SetMinMaxValues(0, 1)
		bars:SetValue(PREVIEW_FILL)
		bars:SetStatusBarColor(r, g, b)
		bars:Show()

		return
	end

	for index = 1, slot.previewCount do
		bars[index]:SetMinMaxValues(0, 1)
		bars[index]:SetValue(1)
		bars[index]:SetStatusBarColor(r, g, b)
		bars[index]:Show()
	end

	ns:LayoutResourceBars(frame)
end

local function StopSlotPreview(frame, key)
	local slot = frame.resourceSlots and frame.resourceSlots[key]

	if not slot or not slot.previewed then
		return
	end

	slot.previewed = nil
	slot.previewBars = nil
	slot.previewCount = nil
	ForEachSlotBar(frame, key, HideBar)
	Relayout(frame)
end

function ns:ApplyResourceSlots(frame)
	local unit = frame.unitKey

	for _, key in ipairs(ns.RESOURCE_SLOTS) do
		if ns:HasElement(unit, key) then
			if ns:ShouldPreview(unit, key) then
				ShowSlotPreview(frame, key)
			else
				StopSlotPreview(frame, key)
				ApplySlot(frame, key)
			end
		end
	end
end

local function SetBarTexture(bar, texture)
	bar:SetStatusBarTexture(texture)
end

function ns:ApplyResourceMedia(frame, texture)
	if not frame.resourceSlots or not texture then
		return
	end

	for key in next, frame.resourceSlots do
		ForEachSlotBar(frame, key, SetBarTexture, texture)
	end
end

local function SetBarColor(bar, r, g, b)
	bar:SetStatusBarColor(r, g, b)
end

function ns:ApplyResourceColors(frame)
	if not frame.resourceSlots then
		return
	end

	local slot, mode, r, g, b

	for _, key in ipairs(ns.RESOURCE_SLOTS) do
		slot = frame.resourceSlots[key]

		if slot then
			mode = ns:GetElementColorMode(frame.unitKey, key)
			r, g, b = SlotColor(frame, key)

			if r then
				ForEachSlotBar(frame, key, SetBarColor, r, g, b)
			elseif slot.colorMode ~= mode then
				for _, name in ipairs(SLOT_ELEMENTS[key]) do
					if frame:IsElementEnabled(name) then
						frame[name]:ForceUpdate()
					end
				end
			end

			slot.colorMode = mode
		end
	end
end
