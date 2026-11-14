-- Forever Drinking: drinking indicator on Blizzard CompactUnitFrames (raid/party frames).
local addonName, ns = ...
local L = ns.L

-- Look settings, kept separately for each frame kind (db.raid / db.party).
ns.STYLE_KEYS = { "mode", "anchor", "offsetX", "offsetY", "iconSize", "textSize", "outline", "textR", "textG", "textB", "blink", "blinkSpeed",
	"textAnchor", "textOffsetX", "textOffsetY" }
ns.STYLE_DEFAULTS = {
	raid = {
		mode = "icon",          -- "icon" | "text" | "both"
		anchor = "TOPRIGHT",
		offsetX = 0, offsetY = 0,
		textAnchor = "TOPRIGHT", textOffsetX = 0, textOffsetY = 0,
		iconSize = 16, textSize = 11, outline = true,
		textR = 0.3, textG = 0.7, textB = 1.0,
		blink = false, blinkSpeed = 0.6,   -- seconds per fade
	},
	party = {
		mode = "icon",
		anchor = "BOTTOM",
		offsetX = 0, offsetY = 0,
		textAnchor = "BOTTOM", textOffsetX = 0, textOffsetY = 0,
		iconSize = 10, textSize = 9, outline = true,
		textR = 0.3, textG = 0.7, textB = 1.0,
		blink = false, blinkSpeed = 0.6,   -- seconds per fade
	},
}
ns.DEFAULTS = {
	preview = false,
	showOnRaid = true,      -- raid-style frames (CompactRaid*/CompactParty*)
	showOnParty = true,     -- classic party frames (PartyFrame members)
}

-- Aura names that mean "drinking for mana". Spell 430 = "Drink" (localized by client).
local DRINK = { ["Drink"] = true, ["Trinken"] = true, ["Food & Drink"] = true, ["Essen & Trinken"] = true }
local function AddSpellName(id)
	local name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id))
		or (GetSpellInfo and GetSpellInfo(id))
	if name then DRINK[name] = true end
end
for _, id in ipairs({ 430, 431, 432, 1133, 1135, 1137, 22734, 24355, 25696, 26475 }) do AddSpellName(id) end

-- This client uses "secret values": some aura fields can be hidden from addons
-- (e.g. in combat). Those must not be compared or used as table keys.
local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local PREVIEW_ICON = "Interface\\Icons\\INV_Drink_07"

-- Asks the client first whether a buff slot is locked ("secret") for addons.
-- Reading a locked slot from addon code is refused (and spams warnings),
-- so locked slots are skipped and only readable buffs are checked.
local ShouldIndexBeSecret = C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret

local function GetDrinkIcon(unit)
	if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
		for i = 1, 40 do
			if not (ShouldIndexBeSecret and ShouldIndexBeSecret(unit, i, "HELPFUL")) then
				local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
				if not aura then return end
				local name = aura.name
				if name and not IsSecret(name) and DRINK[name] and not IsSecret(aura.icon) then return aura.icon end
			end
		end
	elseif UnitBuff then
		for i = 1, 40 do
			local name, icon = UnitBuff(unit, i)
			if not name then return end
			if not IsSecret(name) and DRINK[name] then return icon end
		end
	end
end

local frames = setmetatable({}, { __mode = "k" }) -- every raid/party frame we have seen

local function Build(frame)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetFrameLevel(frame:GetFrameLevel() + 10)
	holder.icon = holder:CreateTexture(nil, "OVERLAY")
	holder.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	holder.text = holder:CreateFontString(nil, "OVERLAY")
	-- blinking: fade out and back in, endlessly
	local anim = holder:CreateAnimationGroup()
	anim:SetLooping("BOUNCE")
	holder.fade = anim:CreateAnimation("Alpha")
	holder.fade:SetFromAlpha(1)
	holder.fade:SetToAlpha(0.15)
	holder.fade:SetSmoothing("IN_OUT")
	holder.blink = anim
	frame.ForeverDrinking = holder
	return holder
end

-- Puts one region at its chosen spot. "BOTTOM" = dead center in the
-- resource (mana) bar when the frame shows one.
-- A small automatic gap keeps the indicator off the frame border, always
-- pointing inwards; the offset sliders then start at 0 for every position.
local INSET = 3
local function Place(region, frame, bar, anchor, x, y)
	region:ClearAllPoints()
	if anchor == "BOTTOM" and bar and bar:IsShown() then
		region:SetPoint("CENTER", bar, "CENTER", 0, 0)
	else
		local ix = anchor:find("LEFT") and INSET or anchor:find("RIGHT") and -INSET or 0
		local iy = anchor:find("TOP") and -INSET or anchor:find("BOTTOM") and INSET or 0
		region:SetPoint(anchor, frame, anchor, ix + x, iy + y)
	end
end

-- Icon and text are positioned independently (anchor/offset* = icon,
-- textAnchor/textOffset* = text). The holder covers the whole unit frame.
local function Layout(frame, holder, bar, db)
	local showIcon = db.mode ~= "text"
	local showText = db.mode ~= "icon"

	holder:ClearAllPoints()
	holder:SetAllPoints(frame)
	holder.icon:SetShown(showIcon)
	holder.text:SetShown(showText)

	if showIcon then
		holder.icon:SetSize(db.iconSize, db.iconSize)
		Place(holder.icon, frame, bar, db.anchor, db.offsetX, db.offsetY)
	end
	if showText then
		holder.text:SetFont(STANDARD_TEXT_FONT, db.textSize, db.outline and "OUTLINE" or "")
		holder.text:SetTextColor(db.textR, db.textG, db.textB)
		holder.text:SetText(L.drinking)
		Place(holder.text, frame, bar, db.textAnchor, db.textOffsetX, db.textOffsetY)
	end

	if db.blink then
		if holder.fade:GetDuration() ~= db.blinkSpeed then
			holder.blink:Stop()
			holder.fade:SetDuration(db.blinkSpeed)
		end
		if not holder.blink:IsPlaying() then holder.blink:Play() end
	else
		holder.blink:Stop()
		holder:SetAlpha(1)
	end
end

local function Show(frame, unit, bar, enabled, style)
	local icon = enabled and unit and UnitExists(unit) and GetDrinkIcon(unit)
	if not icon and enabled and ns.db.preview and frame:IsShown() then icon = PREVIEW_ICON end

	local holder = frame.ForeverDrinking
	if not icon then
		if holder then holder:Hide() end
		return
	end
	holder = holder or Build(frame)
	holder.icon:SetTexture(icon)
	Layout(frame, holder, bar, style)
	holder:Show()
end

-- raid-style frames (also used for raid-style party frames)
local function Update(frame)
	if not frame or not ns.db or (frame.IsForbidden and frame:IsForbidden()) then return end
	local name = frame:GetName()
	if not name or not (name:find("^CompactRaid") or name:find("^CompactParty")) then return end
	frames[frame] = true
	Show(frame, frame.displayedUnit or frame.unit, frame.powerBar, ns.db.showOnRaid, ns.db.raid)
end

-- classic party frames (portrait + bars). Blizzard builds them from a frame
-- pool when PartyFrame is shown, so we hook each member frame's own update
-- methods. Only hooks: we never call Blizzard code ourselves (that would taint it).
local partyFrames = {}

local function UpdatePartyMember(frame)
	if not ns.db or not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
	local unit = frame.unit or frame.unitToken
	if IsSecret(unit) then unit = nil end
	Show(frame, unit, frame.ManaBar or frame.manabar, ns.db.showOnParty, ns.db.party)
end

local function HookPartyMember(frame)
	if not frame or partyFrames[frame] then return end
	partyFrames[frame] = true
	if frame.UpdateMember then hooksecurefunc(frame, "UpdateMember", UpdatePartyMember) end
	if frame.UpdateAuras then hooksecurefunc(frame, "UpdateAuras", UpdatePartyMember) end
	UpdatePartyMember(frame)
end

local function ScanParty()
	local pool = PartyFrame and PartyFrame.PartyMemberFramePool
	if pool and pool.EnumerateActive then
		for frame in pool:EnumerateActive() do HookPartyMember(frame) end
	end
end

local partyHooked
local function HookPartyFrame()
	if partyHooked or not PartyFrame then return end
	partyHooked = true
	for _, method in ipairs({ "InitializePartyMemberFrames", "UpdateMemberFrames", "UpdatePartyFrames" }) do
		if PartyFrame[method] then hooksecurefunc(PartyFrame, method, ScanParty) end
	end
	PartyFrame:HookScript("OnShow", ScanParty)
end
HookPartyFrame()

-- very old clients: global PartyMemberFrame1..4 without mixin methods
local function UpdateLegacyParty()
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame" .. i]
		if frame and not partyFrames[frame] then
			local name = frame:GetName()
			Show(frame, frame.unit or ("party" .. i), frame.manabar or _G[name .. "ManaBar"],
				ns.db and ns.db.showOnParty, ns.db and ns.db.party)
		end
	end
end

local function UpdateAllParty()
	if not ns.db then return end
	HookPartyFrame()
	ScanParty()
	for frame in pairs(partyFrames) do UpdatePartyMember(frame) end
	UpdateLegacyParty()
end

function ns.RefreshAll()
	for frame in pairs(frames) do Update(frame) end
	UpdateAllParty()
end

if CompactUnitFrame_UpdateAuras then hooksecurefunc("CompactUnitFrame_UpdateAuras", Update) end
if CompactUnitFrame_UpdateAll then hooksecurefunc("CompactUnitFrame_UpdateAll", Update) end

-- Our own safety net: do not rely only on Blizzard's frame updates. Re-check
-- the matching frames on every buff change, and everything on combat start/end,
-- so an indicator can never get stuck after someone stopped drinking.
local function UpdateUnit(unit)
	for frame in pairs(frames) do
		local u = frame.displayedUnit or frame.unit
		if not IsSecret(u) and u == unit then Update(frame) end
	end
	for frame in pairs(partyFrames) do
		local u = frame.unit or frame.unitToken
		if not IsSecret(u) and u == unit then UpdatePartyMember(frame) end
	end
end

local partyEv = CreateFrame("Frame")
partyEv:RegisterEvent("UNIT_AURA")
partyEv:RegisterEvent("GROUP_ROSTER_UPDATE")
partyEv:RegisterEvent("PLAYER_ENTERING_WORLD")
partyEv:RegisterEvent("PLAYER_REGEN_DISABLED")
partyEv:RegisterEvent("PLAYER_REGEN_ENABLED")
partyEv:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_AURA" then
		if type(unit) == "string" and not IsSecret(unit) then UpdateUnit(unit) end
		if next(partyFrames) == nil then UpdateLegacyParty() end
	elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		ns.RefreshAll()
	else
		-- let Blizzard update the party frames first
		C_Timer.After(0, UpdateAllParty)
	end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, _, addon)
	if addon ~= addonName then return end
	self:UnregisterEvent("ADDON_LOADED")
	local db = ForeverDrinkingDB or {}
	ForeverDrinkingDB = db
	for k, v in pairs(ns.DEFAULTS) do
		if db[k] == nil then db[k] = v end
	end
	for kind, defaults in pairs(ns.STYLE_DEFAULTS) do
		db[kind] = type(db[kind]) == "table" and db[kind] or {}
		for _, k in ipairs(ns.STYLE_KEYS) do
			-- older versions had one shared set of settings: take it over for both kinds
			if db[kind][k] == nil and db[k] ~= nil then db[kind][k] = db[k] end
			if db[kind][k] == nil then db[kind][k] = defaults[k] end
		end
		-- the old fixed -3/-3 default is now an automatic inward gap
		-- text position is new: start it where the shared position was
		local st = db[kind]
		if st.textPosMigrated == nil then
			st.textAnchor, st.textOffsetX, st.textOffsetY = st.anchor, st.offsetX, st.offsetY
			st.textPosMigrated = true
		end
		-- the old fixed -3/-3 default is now an automatic inward gap: reset it to 0
		if not st.insetMigrated then
			if st.offsetX == -3 and st.offsetY == -3 then st.offsetX, st.offsetY = 0, 0 end
			if st.textOffsetX == -3 and st.textOffsetY == -3 then st.textOffsetX, st.textOffsetY = 0, 0 end
			st.insetMigrated = true
		end
	end
	for _, k in ipairs(ns.STYLE_KEYS) do db[k] = nil end
	ForeverDrinkingDB.preview = false
	ns.db = ForeverDrinkingDB
end)

-- ---------------------------------------------------------------- diagnostics
-- /trinken debug : lists what the addon can see of every group member's buffs.
function ns.Debug()
	-- also kept in the saved variables (written on /reload) for troubleshooting
	local log = {}
	if ns.db then ns.db.lastDebug = log end
	local function out(msg)
		DEFAULT_CHAT_FRAME:AddMessage("|cff4db3ffForeverDrinking:|r " .. msg)
		log[#log + 1] = msg
	end
	local function show(v)
		if v == nil then return "nil" end
		if IsSecret(v) then return "<geheim>" end
		return tostring(v)
	end
	local units = { "player" }
	if IsInRaid() then
		for i = 1, 40 do units[#units + 1] = "raid" .. i end
	else
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	local inInstance, instanceType = IsInInstance()
	out(("Instanz: %s (%s), Kampf: %s"):format(show(inInstance), show(instanceType), show(InCombatLockdown())))
	if C_Secrets then
		if C_Secrets.ShouldAurasBeSecret then out("Buffs allgemein gesperrt: " .. show(C_Secrets.ShouldAurasBeSecret())) end
		if C_Secrets.ShouldSpellAuraBeSecret then
			local ids = {}
			for _, id in ipairs({ 430, 431, 432, 1133, 1135, 1137, 22734, 24355, 25696, 26475 }) do
				ids[#ids + 1] = id .. "=" .. show(C_Secrets.ShouldSpellAuraBeSecret(id))
			end
			out("Trink-Zauber gesperrt: " .. table.concat(ids, " "))
		end
	else
		out("C_Secrets nicht vorhanden")
	end
	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			local parts, readable, locked = {}, 0, 0
			for i = 1, 40 do
				if ShouldIndexBeSecret and ShouldIndexBeSecret(unit, i, "HELPFUL") then
					locked = locked + 1
				else
					local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
					if not aura then break end
					readable = readable + 1
					parts[#parts + 1] = ("%s [%s]"):format(show(aura.name), show(aura.spellId))
				end
			end
			local hit = GetDrinkIcon(unit) and "|cff00ff00TRINKT erkannt|r" or "nicht erkannt"
			out(("%s (%s): %d lesbar, %d gesperrt, %s"):format(unit, show(UnitName(unit)), readable, locked, hit))
			if #parts > 0 then out("   " .. table.concat(parts, ", ")) end
		end
	end
end
