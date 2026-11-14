-- lua5.1 tests/Options.lua (from the addon folder): key, minimap icon and
-- Settings page, with a stubbed client.
local failures = 0
local function check(cond, name)
	if cond then print("ok   " .. name) else failures = failures + 1; print("FAIL " .. name) end
end

-- Minimal frame stub: remembers scripts, shown state and points.
local function Frame(name)
	local f = { scripts = {}, shown = true, events = {} }
	local mt = { __index = function(_, k)
		if type(k) == "string" and k:match("^%u") then return function() end end
	end }
	setmetatable(f, mt)
	function f:SetScript(k, fn) self.scripts[k] = fn end
	function f:HookScript(k, fn) self.scripts[k] = fn end
	function f:GetScript(k) return self.scripts[k] end
	function f:Show() self.shown = true end
	function f:Hide() self.shown = false end
	function f:SetShown(v) self.shown = v and true or false end
	function f:IsShown() return self.shown end
	function f:IsVisible() return self.shown end
	function f:SetPoint(...) self.point = { ... } end
	function f:SetText(t) self.text_ = t end
	function f:GetText() return self.text_ end
	function f:SetChecked(v) self.checked = v end
	function f:GetChecked() return self.checked end
	function f:GetWidth() return 140 end
	function f:GetHeight() return 140 end
	function f:GetCenter() return 500, 500 end
	function f:GetEffectiveScale() return 1 end
	function f:GetUnboundedStringWidth() return 40 end
	function f:RegisterEvent(e) self.events[e] = true end
	function f:CreateFontString() return Frame() end
	function f:CreateTexture() return Frame() end
	function f:GetFontString() return self.fs end
	function f:SetFontString(fs) self.fs = fs end
	if name then _G[name] = f end
	return f
end

CreateFrame = function(_, name) return Frame(name) end
UIParent, Minimap, GameTooltip = Frame(), Frame(), Frame()
GameFontNormalSmall, GameFontDisableSmall = {}, {}
Enum = { CooldownViewerAlertType = {}, CooldownViewerSound = {}, CooldownViewerAlertEventType = {} }
C_AddOns = { IsAddOnLoaded = function() return false end }
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
SlashCmdList = {}
print = print

local inCombat = false
InCombatLockdown = function() return inCombat end
local bindings, saved = { F5 = "TOGGLEMUSIC" }, 0
BINDING_NAME_TOGGLEMUSIC = "Toggle Music"
GetBindingKey = function(action)
	local keys = {}
	for k, a in pairs(bindings) do if a == action then keys[#keys + 1] = k end end
	return unpack(keys)
end
GetBindingAction = function(key) return bindings[key] or "" end
GetBindingText = function(key) return key end
SetBinding = function(key, action) bindings[key] = action end
SaveBindings = function() saved = saved + 1 end
GetCurrentBindingSet = function() return 1 end
IsAltKeyDown = function() return false end
IsControlKeyDown = function() return true end
IsShiftKeyDown = function() return false end
local cursor = { 500, 600 }
GetCursorPosition = function() return cursor[1], cursor[2] end

local registered
Settings = {
	RegisterCanvasLayoutCategory = function(panel, title) registered = { panel = panel, title = title }; return registered end,
	RegisterAddOnCategory = function() end,
}
local shownPanel
CooldownViewerSettings = Frame("CooldownViewerSettings")
CooldownViewerSettings.shown = false
function CooldownViewerSettings:ShowUIPanel() self.shown = true; shownPanel = true end
HideUIPanel = function(f) f.shown = false end

local ns = {}
local function load(file)
	local chunk = assert(loadfile(file))
	chunk("CDMCustomTTS", ns)
end
load("CDMCustomTTS.lua")

-- Login: icon built and shown by default, Settings page registered.
-- Options.lua keeps its frames local; capture them as they are made.
local loader
local created = {}
CreateFrame = function(t, n) local f = Frame(n); created[#created + 1] = f; return f end
load("Options.lua")
for _, f in ipairs(created) do
	if f.events.PLAYER_LOGIN then loader = f end
end
check(loader ~= nil, "loader listens for login")
loader.scripts.OnEvent(loader, "PLAYER_LOGIN")

check(BINDING_CATEGORY_CDMCUSTOMTTS == "CDM Custom TTS", "bindings section named")
check(BINDING_NAME_CDMCUSTOMTTS_TOGGLE ~= nil, "binding named")
check(CDMCustomTTSDB.minimap.show == true, "icon shown by default")
check(CDMCustomTTSMinimapButton and CDMCustomTTSMinimapButton.shown, "icon built")
check(registered and registered.title == "CDM Custom TTS", "Settings page titled")

-- Toggle: opens and closes Blizzard's panel; refused in combat.
CDMCustomTTS_Toggle()
check(CooldownViewerSettings.shown, "toggle opens Cooldown Manager")
CDMCustomTTS_Toggle()
check(not CooldownViewerSettings.shown, "toggle closes it")
inCombat = true
CDMCustomTTS_Toggle()
check(not CooldownViewerSettings.shown, "toggle refused in combat")
inCombat = false

-- Minimap icon click toggles; drag saves the angle.
local b = CDMCustomTTSMinimapButton
b.scripts.OnClick(b)
check(CooldownViewerSettings.shown, "icon click opens")
b.scripts.OnDragStart(b)
b.scripts.OnUpdate(b)
check(math.abs(CDMCustomTTSDB.minimap.angle - 90) < 0.01, "drag saves angle")
b.scripts.OnDragStop(b)

-- Hide and show from the page's toggle.
ns.SetMinimapShown(false)
check(CDMCustomTTSDB.minimap.show == false and not b.shown, "icon hidden and saved")
ns.SetMinimapShown(true)
check(CDMCustomTTSDB.minimap.show == true and b.shown, "icon shown again")

-- Key setter: find the keycap (the button with an OnKeyDown after a click).
local cap
for _, f in ipairs(created) do
	if f.scripts.OnClick and f.scripts.OnClick ~= b.scripts.OnClick then
		f.scripts.OnClick(f, "LeftButton")
		if f.scripts.OnKeyDown then cap = f; break end
	end
end
check(cap ~= nil, "keycap listens after click")
cap.scripts.OnKeyDown(cap, "LCTRL")
check(cap.scripts.OnKeyDown ~= nil, "modifier alone keeps listening")
cap.scripts.OnKeyDown(cap, "F5")
check(bindings["CTRL-F5"] == "CDMCUSTOMTTS_TOGGLE", "Ctrl+key bound")
check(saved >= 1, "bindings saved")
check(cap.scripts.OnKeyDown == nil, "listening stops")

cap.scripts.OnClick(cap, "LeftButton")
cap.scripts.OnKeyDown(cap, "ESCAPE")
check(bindings["CTRL-F5"] == "CDMCUSTOMTTS_TOGGLE", "Esc cancels")

IsControlKeyDown = function() return false end
cap.scripts.OnClick(cap, "LeftButton")
cap.scripts.OnKeyDown(cap, "F5")
check(bindings.F5 == "CDMCUSTOMTTS_TOGGLE" and bindings["CTRL-F5"] == nil, "taken key replaced, old key cleared")

inCombat = true
cap.scripts.OnClick(cap, "LeftButton")
check(cap.scripts.OnKeyDown == nil, "no listening in combat")
inCombat = false

print(failures == 0 and "all passed" or (failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
