-- Settings page (Game Menu → Options → AddOns → Forever Drinking), also /fdrink.
local _, ns = ...
local L = ns.L

local function Refresh() ns.RefreshAll() end

local ANCHORS = {}
for _, a in ipairs({ "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }) do
	ANCHORS[#ANCHORS + 1] = { a, L[a] }
end

-- Main page: what is shown where.
local GENERAL_ROWS = {
	{ "header", L.optDisplay },
	{ "check", "showOnRaid", L.optShowRaid, L.optShowRaidTip },
	{ "check", "showOnParty", L.optShowParty, L.optShowPartyTip },
	{ "check", "preview", L.optPreview, L.optPreviewTip },
}

-- Look settings: one page each for raid frames and normal party frames.
local STYLE_ROWS = {
	{ "header", L.optDisplay },
	{ "cycle", "mode", L.optMode, L.optModeTip, choices = {
		{ "icon", L.modeIcon }, { "text", L.modeText }, { "both", L.modeBoth } } },
	{ "check", "blink", L.optBlink, L.optBlinkTip },
	{ "step", "blinkSpeed", L.optBlinkSpeed, L.optBlinkSpeedTip, 0.2, 2, 0.1,
		parent = "blink", active = function(db) return db.blink end,
		fmt = function(v) return string.format("%.1f s", v) end },

	{ "header", L.optIcon },
	{ "cycle", "anchor", L.optIconAnchor, L.optAnchorTip, choices = ANCHORS,
		active = function(db) return db.mode ~= "text" end },
	{ "step", "offsetX", L.optOffsetX, L.optOffsetXTip, -40, 40, 1,
		parent = "anchor", active = function(db) return db.mode ~= "text" and db.anchor ~= "BOTTOM" end },
	{ "step", "offsetY", L.optOffsetY, L.optOffsetYTip, -40, 40, 1,
		parent = "anchor", active = function(db) return db.mode ~= "text" and db.anchor ~= "BOTTOM" end },
	{ "step", "iconSize", L.optIconSize, L.optIconSizeTip, 6, 48, 1,
		active = function(db) return db.mode ~= "text" end },

	{ "header", L.optText },
	{ "cycle", "textAnchor", L.optTextAnchor, L.optAnchorTip, choices = ANCHORS,
		active = function(db) return db.mode ~= "icon" end },
	{ "step", "textOffsetX", L.optOffsetX, L.optOffsetXTip, -40, 40, 1,
		parent = "textAnchor", active = function(db) return db.mode ~= "icon" and db.textAnchor ~= "BOTTOM" end },
	{ "step", "textOffsetY", L.optOffsetY, L.optOffsetYTip, -40, 40, 1,
		parent = "textAnchor", active = function(db) return db.mode ~= "icon" and db.textAnchor ~= "BOTTOM" end },
	{ "step", "textSize", L.optTextSize, L.optTextSizeTip, 6, 32, 1,
		active = function(db) return db.mode ~= "icon" end },
	{ "check", "outline", L.optOutline, L.optOutlineTip,
		active = function(db) return db.mode ~= "icon" end },
	{ "color", active = function(db) return db.mode ~= "icon" end },
}

-- ---------------------------------------------------------------- color picker

local function OpenColorPicker(db)
	local old = { db.textR, db.textG, db.textB }
	local function apply()
		db.textR, db.textG, db.textB = ColorPickerFrame:GetColorRGB()
		Refresh()
	end
	local function cancel()
		db.textR, db.textG, db.textB = old[1], old[2], old[3]
		Refresh()
	end
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow({
			r = db.textR, g = db.textG, b = db.textB, hasOpacity = false,
			swatchFunc = apply, cancelFunc = cancel,
		})
	else
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func, ColorPickerFrame.cancelFunc = apply, cancel
		ColorPickerFrame:SetColorRGB(db.textR, db.textG, db.textB)
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end
end

-- ---------------------------------------------------------------- Blizzard page

local category

-- Adds rows to a settings category. db = table the values live in,
-- defaults = their default values, prefix = unique variable name prefix.
local function AddRows(cat, rows, db, defaults, prefix)
	local inits = {}
	for _, row in ipairs(rows) do
		local kind, key, label, tooltip = row[1], row[2], row[3], row[4]
		local init
		if kind == "header" then
			if Settings.RegisterInitializer and CreateSettingsListSectionHeaderInitializer then
				Settings.RegisterInitializer(cat, CreateSettingsListSectionHeaderInitializer(key))
			end
		elseif kind == "button" then
			if CreateSettingsButtonInitializer and Settings.RegisterInitializer then
				Settings.RegisterInitializer(cat,
					CreateSettingsButtonInitializer(row[2], row[3], row[5], row[4], true))
			end
		elseif kind == "color" then
			if CreateSettingsButtonInitializer and Settings.RegisterInitializer then
				init = CreateSettingsButtonInitializer(L.optColor, L.optColorBtn,
					function() OpenColorPicker(db) end, L.optColorTip, true)
				Settings.RegisterInitializer(cat, init)
			end
		else
			local vtype = (kind == "check" and Settings.VarType.Boolean)
				or (kind == "cycle" and Settings.VarType.String) or Settings.VarType.Number
			local default = defaults[key]
			if kind == "check" then default = default and Settings.Default.True or Settings.Default.False end
			local setting = Settings.RegisterAddOnSetting(cat, prefix .. key:upper(), key,
				db, vtype, label, default)
			setting:SetValueChangedCallback(Refresh)

			if kind == "check" then
				init = Settings.CreateCheckbox(cat, setting, tooltip)
			elseif kind == "step" and Settings.CreateSlider and Settings.CreateSliderOptions then
				local options = Settings.CreateSliderOptions(row[5], row[6], row[7])
				if MinimalSliderWithSteppersMixin and options.SetLabelFormatter then
					options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, row.fmt)
				end
				init = Settings.CreateSlider(cat, setting, options, tooltip)
			elseif kind == "cycle" then
				local create = Settings.CreateDropdown or Settings.CreateDropDown
				if create and Settings.CreateControlTextContainer then
					local function GetOptions()
						local container = Settings.CreateControlTextContainer()
						for _, c in ipairs(row.choices) do container:Add(c[1], c[2]) end
						return container:GetData()
					end
					init = create(cat, setting, GetOptions, tooltip)
				end
			end
			inits[key] = init
		end
		-- grey out settings that do not apply (to the chosen mode / position)
		local parent = inits[row.parent or "mode"]
		if init and row.active and parent and init.SetParentInitializer then
			pcall(init.SetParentInitializer, init, parent, function() return row.active(db) end)
		end
	end
end

local function Register()
	if category or not (Settings and Settings.RegisterVerticalLayoutCategory and ns.db) then return end
	category = Settings.RegisterVerticalLayoutCategory(L.title)
	AddRows(category, GENERAL_ROWS, ns.db, ns.DEFAULTS, "FOREVER_DRINKING_")

	for _, page in ipairs({ { "raid", L.pageRaid }, { "party", L.pageParty } }) do
		local kind, title = page[1], page[2]
		local cat = category
		if Settings.RegisterVerticalLayoutSubcategory then
			cat = Settings.RegisterVerticalLayoutSubcategory(category, title)
		elseif Settings.RegisterInitializer and CreateSettingsListSectionHeaderInitializer then
			Settings.RegisterInitializer(category, CreateSettingsListSectionHeaderInitializer("— " .. title .. " —"))
		end
		AddRows(cat, STYLE_ROWS, ns.db[kind], ns.STYLE_DEFAULTS[kind], "FOREVER_DRINKING_" .. kind:upper() .. "_")
	end

	Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
	if InCombatLockdown and InCombatLockdown() then
		if UIErrorsFrame then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT or "Not in combat", 1, 0.1, 0.1) end
		return
	end
	Register()
	if category and Settings.OpenToCategory then
		if not pcall(Settings.OpenToCategory, category:GetID()) then pcall(Settings.OpenToCategory, category) end
	end
end

SLASH_FOREVERDRINKING1 = "/fdrink"
SLASH_FOREVERDRINKING2 = "/trinken"
SlashCmdList.FOREVERDRINKING = function(msg)
	if msg and msg:lower():match("^%s*debug") then ns.Debug() else ns.OpenOptions() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", Register)
