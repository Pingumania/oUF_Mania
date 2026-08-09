local _, ns = ...
local oUF = ns.oUF

local BOSS_ANCHOR = { "RIGHT", UIParent, "RIGHT", -60, 160 }
local PARTY_ANCHOR = { "TOPLEFT", UIParent, "TOPLEFT", 30, -220 }

local FRAMES = {
	{ key = "player", name = "ManiaUFPlayer",
		anchor = { "BOTTOM", UIParent, "BOTTOM", -260, 280 } },
	{ key = "target", name = "ManiaUFTarget",
		anchor = { "BOTTOM", UIParent, "BOTTOM", 260, 280 } },
	{ key = "focus", name = "ManiaUFFocus",
		anchor = { "BOTTOM", UIParent, "BOTTOM", -260, 380 } },
	{ key = "pet", name = "ManiaUFPet",
		anchor = { "BOTTOMRIGHT", "ManiaUFPlayer", "TOPRIGHT", 0, 6 } },
	{ key = "targettarget", name = "ManiaUFTargetTarget",
		anchor = { "BOTTOMLEFT", "ManiaUFTarget", "TOPLEFT", 0, 6 } },
}

local PREVIEW_MEMBERS = {
	party = 5,
}

local placed = {}
local groupPreviews = {}
local bossFrames = {}
local partyHeader

function ns:HasGroupPreview(key)
	return PREVIEW_MEMBERS[key] ~= nil
end

function ns:IsGroupPreviewed(key)
	return not not groupPreviews[key]
end

local function SetChildrenPreviewed(header, previewed)
	local children = { header:GetChildren() }

	for _, child in ipairs(children) do
		ns:SetPreviewUnit(child, previewed)

		if previewed then
			UnregisterUnitWatch(child)
			child:Show()
		else
			RegisterUnitWatch(child)
		end
	end
end

function ns:ApplyGroupPreview()
	local entry, header

	for key, count in next, PREVIEW_MEMBERS do
		entry = placed[key]

		if entry then
			header = entry.frame

			if groupPreviews[key] then
				RegisterAttributeDriver(header, "state-visibility", "show")
				header:SetAttribute("startingIndex", -(count - 1))
			else
				RegisterAttributeDriver(header, "state-visibility", header.visibility)
				header:SetAttribute("startingIndex", 1)
			end

			SetChildrenPreviewed(header, groupPreviews[key])
		end
	end
end

function ns:SetGroupPreviewed(key, enabled)
	groupPreviews[key] = enabled or nil
	ns:DeferMethod(ns, "ApplyGroupPreview")
end

function ns:StopAllGroupPreviews()
	local any

	for key in next, groupPreviews do
		groupPreviews[key] = nil
		any = true
	end

	if any then
		ns:DeferMethod(ns, "ApplyGroupPreview")
	end
end

local function PlaceFrame(key, frame, anchor)
	local x, y = ns:GetUnitOffset(key)

	placed[key] = { frame = frame, anchor = anchor }

	ns:SetPoint(frame, anchor[1], anchor[2], anchor[3], anchor[4] + x, anchor[5] + y)
end

function ns:UpdatePositions()
	for key, entry in next, placed do
		PlaceFrame(key, entry.frame, entry.anchor)
	end
end

local function ConfigSnippet(key)
	local width, height = ns:GetUnitSize(key)

	return ([[
		self:SetWidth(%d)
		self:SetHeight(%d)
	]]):format(width, height)
end

local function SpawnFrames()
	local anchor, relative, frame

	for _, info in ipairs(FRAMES) do
		anchor = info.anchor
		relative = anchor[2]

		if ns:IsUnitEnabled(info.key) and (type(relative) ~= "string" or _G[relative]) then
			frame = oUF:Spawn(info.key, info.name)
			frame.standalone = true
			PlaceFrame(info.key, frame, anchor)
		end
	end
end

local function SpawnBoss()
	if not ns:IsUnitEnabled("boss") then
		return
	end

	local boss

	for index = 1, MAX_BOSS_FRAMES do
		boss = oUF:Spawn("boss" .. index, "ManiaUFBoss" .. index)
		boss.standalone = true
		bossFrames[index] = boss

		if index == 1 then
			PlaceFrame("boss", boss, BOSS_ANCHOR)
		end
	end
end

local function SpawnParty()
	if not ns:IsUnitEnabled("party") then
		return
	end

	partyHeader = oUF:SpawnHeader("ManiaUFParty", nil,
		"showParty", true,
		"showSolo", false,
		"oUF-initialConfigFunction", ConfigSnippet("party")
	)

	PlaceFrame("party", partyHeader, PARTY_ANCHOR)
	partyHeader:SetVisibility("party")
end

function ns:ApplyGroupLayout()
	local spacing = ns:GetUnitSpacing("boss")

	for index = 2, #bossFrames do
		ns:SetPoint(bossFrames[index], "TOP", bossFrames[index - 1], "BOTTOM", 0, -spacing)
	end

	if not partyHeader then
		return
	end

	local vertical = ns:IsPartyVertical()
	local shown = ns:IsPartyPlayerShown()

	spacing = ns:GetUnitSpacing("party")

	local point = vertical and "TOP" or "LEFT"
	local xOffset = vertical and 0 or spacing
	local yOffset = vertical and -spacing or 0

	if partyHeader:GetAttribute("point") == point
		and partyHeader:GetAttribute("xOffset") == xOffset
		and partyHeader:GetAttribute("yOffset") == yOffset
		and partyHeader:GetAttribute("showPlayer") == shown then
		return
	end

	partyHeader:SetAttribute("startingIndex", 1)
	partyHeader:SetAttribute("showPlayer", shown)
	partyHeader:SetAttribute("point", point)
	partyHeader:SetAttribute("xOffset", xOffset)
	partyHeader:SetAttribute("yOffset", yOffset)

	ns:ApplyGroupPreview()
end

function ns:OnLogin()
	SpawnFrames()
	SpawnBoss()
	SpawnParty()
	ns:ApplyGroupLayout()
end
