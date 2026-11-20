-- The addon has no window of its own: its pane lives in Blizzard's Cooldown
-- Manager alert editor. Key, minimap icon and Settings page all open that
-- panel (CooldownViewerSettings).
local addonName, ns = ...

local TITLE = "CDM Custom TTS"
local ACTION = "CDMCUSTOMTTS_TOGGLE"
local ICON = "Interface\\AddOns\\CDMCustomTTS\\Assets\\CDMCustomTTSIcon"
local COLORS, ApplyBackdrop, StyleAddonButton, Say = ns.COLORS, ns.ApplyBackdrop, ns.StyleAddonButton, ns.Say

BINDING_CATEGORY_CDMCUSTOMTTS = TITLE
BINDING_HEADER_CDMCUSTOMTTS = TITLE
BINDING_NAME_CDMCUSTOMTTS_TOGGLE = "Cooldown Manager"

local function OptionsDB()
	CDMCustomTTSDB = CDMCustomTTSDB or {}
	local db = CDMCustomTTSDB
	if type(db.minimap) ~= "table" then
		db.minimap = { show = true, angle = 200 }
	end
	if db.minimap.show == nil then db.minimap.show = true end
	db.minimap.angle = tonumber(db.minimap.angle) or 200
	return db
end

local function ManagerPanel()
	if not CooldownViewerSettings and C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
	end
	return CooldownViewerSettings
end

-- Opening Blizzard's panel from addon code stays out of combat, so its
-- combat path is never touched by an addon-started show.
function CDMCustomTTS_Toggle(show)
	if InCombatLockdown() then
		Say("not in combat.")
		return
	end
	local panel = ManagerPanel()
	if not panel then
		Say("Cooldown Manager unavailable.")
		return
	end
	if show == nil then show = not panel:IsVisible() end
	if show then
		if panel.ShowUIPanel then panel:ShowUIPanel() else ShowUIPanel(panel) end
	else
		HideUIPanel(panel)
	end
end

--------------------------------------------------------------------------
-- Key setter: keycap, click to listen, Esc cancels, modifiers combine
--------------------------------------------------------------------------

local MODIFIERS = {
	LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
	LALT = true, RALT = true, LMETA = true, RMETA = true,
}
local NEVER = { ENTER = true, BACKSPACE = true }

local function BoundText(action)
	local key = GetBindingKey and GetBindingKey(action)
	if not key then return nil end
	return GetBindingText and GetBindingText(key) or key
end

local function Combo(key)
	local mods = ""
	if IsAltKeyDown() then mods = mods .. "ALT-" end
	if IsControlKeyDown() then mods = mods .. "CTRL-" end
	if IsShiftKeyDown() then mods = mods .. "SHIFT-" end
	if IsMetaKeyDown and IsMetaKeyDown() then mods = mods .. "META-" end
	return mods .. key
end

-- Binds `key` (nil clears) in place of the action's old keys. Returns the
-- name of what the key did before, or false when refused.
local function BindKey(action, key)
	if InCombatLockdown() then return false end
	for _, old in ipairs({ GetBindingKey(action) }) do SetBinding(old) end
	local before
	if key then
		local previous = GetBindingAction(key)
		if previous and previous ~= "" and previous ~= action then
			before = _G["BINDING_NAME_" .. previous] or previous
		end
		SetBinding(key, action)
	end
	SaveBindings(GetCurrentBindingSet and GetCurrentBindingSet() or 1)
	return before or ""
end

local function KeySetter(parent, action)
	local s = CreateFrame("Frame", nil, parent)
	s:SetSize(260, 44)

	local cap = CreateFrame("Button", nil, s, "BackdropTemplate")
	cap:SetSize(120, 24)
	cap:SetPoint("TOPLEFT")
	ApplyBackdrop(cap, COLORS.cardAlt, COLORS.border)
	cap.text = cap:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	cap.text:SetPoint("CENTER", 0, 1)
	cap:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local clear = CreateFrame("Button", nil, s, "BackdropTemplate")
	clear:SetSize(24, 24)
	clear:SetPoint("LEFT", cap, "RIGHT", 6, 0)
	StyleAddonButton(clear)
	clear:SetText("x")

	local status = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	status:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -5)
	status:SetTextColor(unpack(COLORS.muted))

	function s:Refresh()
		local key = BoundText(action)
		if self.listening then
			cap.text:SetText("Press a key")
			cap.text:SetTextColor(unpack(COLORS.accent))
		else
			cap.text:SetText(key or "Not set")
			if key then cap.text:SetTextColor(1, 1, 1) else cap.text:SetTextColor(unpack(COLORS.muted)) end
		end
		clear:SetShown(key ~= nil and not self.listening)
		local width = math.max(120, (cap.text:GetUnboundedStringWidth() or 0) + 24)
		cap:SetWidth(width)
	end

	function s:Stop()
		if not self.listening then return end
		self.listening = false
		cap:EnableKeyboard(false)
		cap:SetScript("OnKeyDown", nil)
		self:Refresh()
	end

	function s:Listen()
		if InCombatLockdown() then
			status:SetText("Not in combat.")
			return
		end
		self.listening = true
		status:SetText("Esc to cancel")
		cap:EnableKeyboard(true)
		if cap.SetPropagateKeyboardInput then cap:SetPropagateKeyboardInput(false) end
		cap:SetScript("OnKeyDown", function(_, key)
			if MODIFIERS[key] then return end
			if key == "ESCAPE" then
				status:SetText("")
			elseif NEVER[key] then
				status:SetText("Key reserved.")
			else
				local before = BindKey(action, Combo(key))
				if before == false then
					status:SetText("Not in combat.")
				else
					status:SetText(before ~= "" and ("Was " .. before) or "")
				end
			end
			s:Stop()
		end)
		self:Refresh()
	end

	cap:SetScript("OnClick", function(_, button)
		if s.listening then
			status:SetText("")
			s:Stop()
		elseif button == "LeftButton" then
			s:Listen()
		end
	end)
	clear:SetScript("OnClick", function()
		if BindKey(action, nil) == false then
			status:SetText("Not in combat.")
		else
			status:SetText("")
		end
		s:Refresh()
	end)
	s:SetScript("OnHide", function() s:Stop() status:SetText("") end)
	s:SetScript("OnShow", function() s:Refresh() end)
	s:RegisterEvent("PLAYER_REGEN_DISABLED")
	s:SetScript("OnEvent", function() s:Stop() end)
	s:Refresh()
	return s
end

--------------------------------------------------------------------------
-- Minimap icon: drag around the edge; position and toggle saved
--------------------------------------------------------------------------

local minimapButton

local function PlaceMinimapButton()
	local db = OptionsDB()
	local angle = math.rad(db.minimap.angle)
	local x, y = math.cos(angle), math.sin(angle)
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	if shape ~= "ROUND" then
		-- Square minimap: push to its edge rather than a circle inside it.
		x = math.max(-1, math.min(1, x * 1.414))
		y = math.max(-1, math.min(1, y * 1.414))
	end
	local w, h = Minimap:GetWidth() / 2 + 5, Minimap:GetHeight() / 2 + 5
	minimapButton:ClearAllPoints()
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * w, y * h)
end

local function DragUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	OptionsDB().minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
	PlaceMinimapButton()
end

local function BuildMinimapButton()
	if minimapButton or not Minimap then return end
	local b = CreateFrame("Button", "CDMCustomTTSMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = b:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetPoint("TOPLEFT", 7, -5)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("TOPLEFT", 7, -6)
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	b:SetScript("OnClick", function() CDMCustomTTS_Toggle() end)
	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", DragUpdate)
		GameTooltip:Hide()
	end)
	b:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(TITLE)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	minimapButton = b
	PlaceMinimapButton()
end

local minimapCheck

function ns.SetMinimapShown(show)
	OptionsDB().minimap.show = show and true or false
	if show then BuildMinimapButton() end
	if minimapButton then minimapButton:SetShown(show) end
	if minimapCheck then minimapCheck:SetChecked(show) end
end

--------------------------------------------------------------------------
-- Settings > AddOns page
--------------------------------------------------------------------------

local function RegisterInSettings()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")

	local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", 16, -16)
	heading:SetText(TITLE)
	heading:SetTextColor(unpack(COLORS.accent))

	local open = CreateFrame("Button", nil, panel, "BackdropTemplate")
	open:SetSize(180, 26)
	open:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -14)
	StyleAddonButton(open)
	open:SetText("Open Cooldown Manager")
	open:SetScript("OnClick", function()
		if InCombatLockdown() then
			Say("not in combat.")
			return
		end
		if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
		CDMCustomTTS_Toggle(true)
	end)

	local slash = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	slash:SetPoint("LEFT", open, "RIGHT", 12, 0)
	slash:SetText("/cdmtts")
	slash:SetTextColor(unpack(COLORS.muted))

	local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", open, "BOTTOMLEFT", -4, -14)
	local checkLabel = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	checkLabel:SetPoint("LEFT", check, "RIGHT", 2, 1)
	checkLabel:SetText("Minimap icon")
	check:SetScript("OnClick", function(self) ns.SetMinimapShown(self:GetChecked()) end)
	minimapCheck = check

	local keyLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keyLabel:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 4, -16)
	keyLabel:SetText("Cooldown Manager key")
	keyLabel:SetTextColor(unpack(COLORS.accent))

	local setter = KeySetter(panel, ACTION)
	setter:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -6)

	panel:SetScript("OnShow", function()
		check:SetChecked(OptionsDB().minimap.show)
		setter:Refresh()
	end)

	local category = Settings.RegisterCanvasLayoutCategory(panel, TITLE)
	Settings.RegisterAddOnCategory(category)
	ns.settingsCategory = category
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	local db = OptionsDB()
	if db.minimap.show then BuildMinimapButton() end
	pcall(RegisterInSettings)
end)
