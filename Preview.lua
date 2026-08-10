local _, ns = ...

local THREAT_PREVIEW_COLOR = { 1, 0, 0 }
local CASTBAR_PREVIEW_SPELL = 133
local CASTBAR_PREVIEW_DURATION = 3

local wholeUnitPreviews = {}
local elementPreviews = {}

function ns:ShouldPreview(unit, element)
	local own = elementPreviews[unit]
	local shared = elementPreviews[ns.ALL_KEY]

	return wholeUnitPreviews[unit] or (own and own[element]) or (shared and shared[element])
end

function ns:IsWholeUnitPreviewed(unit)
	return not not wholeUnitPreviews[unit]
end

function ns:AnyPreviewActive(unit)
	local own = elementPreviews[unit]
	local shared = elementPreviews[ns.ALL_KEY]

	return not not (wholeUnitPreviews[unit] or (own and next(own)) or (shared and next(shared)))
end

function ns:SetWholeUnitPreviewed(unit, enabled)
	wholeUnitPreviews[unit] = enabled or nil
	ns:UpdateElements()
	ns:DeferMethod(ns, "ApplyFramePreview", unit)
end

function ns:IsPreviewSet(unit, element)
	local own = elementPreviews[unit]
	return not not (own and own[element])
end

function ns:SetPreviewSet(unit, element, value)
	elementPreviews[unit] = elementPreviews[unit] or {}
	elementPreviews[unit][element] = value or nil
	ns:UpdateElements()

	if unit == ns.ALL_KEY then
		for _, unit in ipairs(ns.UNIT_KEYS) do
			ns:DeferMethod(ns, "ApplyFramePreview", unit)
		end
	else
		ns:DeferMethod(ns, "ApplyFramePreview", unit)
	end
end

function ns:StopAllElementPreviews()
	local any

	for unit in next, wholeUnitPreviews do
		wholeUnitPreviews[unit] = nil
		any = true
	end

	for unit in next, elementPreviews do
		elementPreviews[unit] = nil
		any = true
	end

	if not any then
		return
	end

	ns:UpdateElements()

	for _, unit in ipairs(ns.UNIT_KEYS) do
		ns:DeferMethod(ns, "ApplyFramePreview", unit)
	end
end

function ns:ShowIndicatorPreview(frame, info)
	local indicator = frame.elements[info.key]

	ns:SetOUFElement(frame, info.element, false)

	if info.marker then
		SetRaidTargetIconTexture(indicator, info.marker)
	elseif info.key == "quest" then
		ns:ApplyQuestIcon(indicator)
	elseif info.key == "grouprole" then
		indicator:SetAtlas(ns:GetRoleIcon("TANK"), false, nil, true)
	elseif info.atlas then
		indicator:SetAtlas(info.atlas, false, nil, true)
	elseif info.texture then
		indicator:SetTexture(info.texture)
		indicator:SetTexCoord(0, 1, 0, 1)
	end

	indicator:Show()
end

local castPreviews = {}

local function RunPreviewCast(castbar)
	castbar.previewDuration:SetTimeFromStart(GetTime(), CASTBAR_PREVIEW_DURATION)
	castbar:SetTimerDuration(castbar.previewDuration, Enum.StatusBarInterpolation.Immediate,
		Enum.StatusBarTimerDirection.ElapsedTime)

	if castbar.Time.binding then
		castbar.Time.binding:SetDuration(castbar.previewDuration)
	end
end

local function PlacePreviewSafeZone(castbar)
	local safeZone = castbar.SafeZone
	local ratio = select(4, GetNetStats()) / (CASTBAR_PREVIEW_DURATION * 1000)

	safeZone:ClearAllPoints()
	safeZone:SetPoint("TOP")
	safeZone:SetPoint("BOTTOM")
	safeZone:SetPoint("RIGHT")
	safeZone:SetWidth(castbar:GetWidth() * math.min(ratio, 1))
end

function ns:StartCastPreview(frame)
	if castPreviews[frame] then
		return
	end

	local castbar = frame.elements.castbar
	local info = C_Spell.GetSpellInfo(CASTBAR_PREVIEW_SPELL)

	ns:SetOUFElement(frame, "Castbar", false)

	castbar.previewDuration = castbar.previewDuration or C_DurationUtil.CreateDuration()
	castbar:SetMinMaxValues(0, 1)
	castbar.Text:SetText(info and info.name or "")
	castbar.Icon:SetTexture(info and info.iconID)
	castbar.Shield:SetAlpha(0)
	castbar.Spark:Show()
	castbar:Show()

	if frame.unitKey == "player" then
		PlacePreviewSafeZone(castbar)
	end

	if castbar.Time.binding then
		castbar.Time.binding:SetEnabled(true)
	end

	RunPreviewCast(castbar)

	castPreviews[frame] = C_Timer.NewTicker(CASTBAR_PREVIEW_DURATION, function()
		RunPreviewCast(castbar)
	end)
end

function ns:StopCastPreview(frame)
	local ticker = castPreviews[frame]

	if not ticker then
		return
	end

	ticker:Cancel()
	castPreviews[frame] = nil

	local castbar = frame.elements.castbar

	if castbar.Time.binding then
		castbar.Time.binding:SetEnabled(false)
	end

	castbar:Hide()
end

function ns:ShowThreatPreview(frame)
	local threat = frame.elements.threat

	ns:SetOUFElement(frame, "ThreatIndicator", false)
	threat:SetVertexColor(unpack(THREAT_PREVIEW_COLOR))
	threat:SetAlpha(1)
	threat:Show()
end

function ns:ShowRestingPreview(frame)
	local resting = frame.elements.resting

	ns:SetOUFElement(frame, "RestingIndicator", false)
	resting:Show()
	resting.Anim:Play()
end
