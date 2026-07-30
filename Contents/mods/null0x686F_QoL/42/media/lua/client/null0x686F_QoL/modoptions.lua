require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISTickBox")
require("ISUI/ISButton")

local qol_setup = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")
local cfg = require("null0x686F_QoL/cfg")
local tab_registry = require("null0x686F_CoreLib/debug_panel/tab_registry")

local _mod_id = "null0x686F_QoL"
local _mod_name = "null0x686F QoL Options"

local _string_format = string.format
local _tostring = tostring
local _tonumber = tonumber
local _type = type
local _pcall = pcall
local _ipairs = ipairs

local _broken_weapon_behavior_order = { "drop", "destroy", "nothing" }
local _broken_weapon_behavior_labels = {
  drop = "Drop on Ground",
  destroy = "Destroy",
  nothing = "Do Nothing",
}

-- Single source of truth for every boolean feature toggle: drives the ModOptions
-- tickboxes, sync_mod_options' read-back, and the debug tab's toggle list, so
-- the 3 no longer drift independently. Non-boolean settings (zombie outline
-- color, broken weapon behavior enum) stay hand-built below -- they don't fit
-- this shape.
local FEATURE_DEFS = {
  { key = "zombie_outline", pzapi_key = "ZombieOutline_Enabled", label = "Enable Custom Zombie Outline", tooltip = "Toggles custom color highlighting for zombies when aiming.", section = "combat" },
  { key = "inv_name", pzapi_key = "QoL_InvName", label = "Player Name in Inventory", tooltip = "Adds the character's name to the inventory window title.", section = "inventory" },
  { key = "hide_worn", pzapi_key = "QoL_HideWorn", label = "Hide Worn Items", tooltip = "Hides worn clothing from the main inventory list to declutter.", section = "inventory" },
  { key = "quick_context", pzapi_key = "QoL_QuickContext", label = "Quick Context Menu Actions", tooltip = "Adds 1-click context menu shortcuts for Rip All Clothing, Swap Gas Mask Filter, and Bandages.", section = "inventory" },
  { key = "walk_and_equip", pzapi_key = "QoL_WalkAndEquip", label = "Walk/Aim While Equipping Clothing", tooltip = "Allows walking or aiming while putting on/adjusting clothing without interrupting the action.", section = "inventory" },
  { key = "rack_dry", pzapi_key = "QoL_RackDry", label = "Rack Firearm to Dry", tooltip = "Press Rack Firearm key to dry yourself when wet and empty-handed.", section = "survival" },
  { key = "auto_unset_alarms", pzapi_key = "QoL_AutoUnsetAlarms", label = "Auto-Unset Alarms", tooltip = "Automatically turns off alarms on looted digital watches and clocks.", section = "survival" },
  { key = "fence_priority", pzapi_key = "QoL_FencePriority", label = "Fence Jump Priority", tooltip = "Prioritizes vaulting fences over ground item interactions when close to fences.", section = "survival" },
  { key = "vehicle_gas", pzapi_key = "QoL_Vehicles", label = "Vehicle Gas QoL", tooltip = "Allows aiming while pumping gas and restores original equipped items when done.", section = "survival" },
  { key = "auto_equip_broken_weapon", pzapi_key = "QoL_AutoEquipBroken", label = "Auto-Handle Broken Weapons", tooltip = "Automatically handles your weapon when it breaks, and lets you re-equip a fresh copy with a hotkey.", section = "weapons" },
}

local FEATURE_DEFS_BY_KEY = {}
for _, def in _ipairs(FEATURE_DEFS) do
  FEATURE_DEFS_BY_KEY[def.key] = def
end

local SECTION_ORDER = { "combat", "inventory", "survival", "weapons" }
local SECTION_TITLES = {
  combat = "--- Combat & Visual Highlights ---",
  inventory = "--- Inventory & Clothing ---",
  survival = "--- Survival & World Interactions ---",
  weapons = "--- Weapons ---",
}

local function _extract_color(opt, def_r, def_g, def_b, def_a)
  if not opt then return def_r, def_g, def_b, def_a end

  local ok, v1, v2, v3, v4 = _pcall(function ()
    if opt.getRGBA then return opt:getRGBA() end
    if opt.getColor then return opt:getColor() end
    return opt:getValue()
  end)

  if not ok then return def_r, def_g, def_b, def_a end

  if _type(v1) == "table" then
    return _tonumber(v1.r or v1[1]) or def_r,
      _tonumber(v1.g or v1[2]) or def_g,
      _tonumber(v1.b or v1[3]) or def_b,
      _tonumber(v1.a or v1[4]) or def_a
  end

  return _tonumber(v1) or def_r, _tonumber(v2) or def_g, _tonumber(v3) or def_b, _tonumber(v4) or def_a
end

local function _init_mod_options()
  if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create) then
    return
  end

  local options = PZAPI.ModOptions:create(_mod_id, _mod_name)
  if not options then return end

  local def_r, def_g, def_b, def_a = qol_setup.get_zombie_outline_custom_color()

  for i, section in _ipairs(SECTION_ORDER) do
    options:addTitle(SECTION_TITLES[section])

    for _, def in _ipairs(FEATURE_DEFS) do
      if def.section == section then
        options:addTickBox(def.pzapi_key, def.label, qol_setup.is_feature_enabled(def.key), def.tooltip)
      end
    end

    if section == "combat" then
      options:addColorPicker("ZombieOutline_Color", "Custom Zombie Outline Color", def_r, def_g, def_b, def_a, "Changes the color of the zombie outline when aiming in melee mode.")
    elseif section == "weapons" then
      local behavior_combo = options:addComboBox("QoL_BrokenWeaponBehavior", "On Weapon Break", "Choose what happens to your weapon automatically when it breaks in combat.")
      local current_behavior = qol_setup.get_broken_weapon_behavior()
      for _, behavior_key in _ipairs(_broken_weapon_behavior_order) do
        behavior_combo:addItem(_broken_weapon_behavior_labels[behavior_key], behavior_key == current_behavior)
      end
      options:addKeyBind("QoL_ReequipBrokenKey", "Re-Equip Fresh Weapon (when broken)", cfg.AUTO_EQUIP_BROKEN_WEAPON.hotkey)
    end

    if i < #SECTION_ORDER then
      options:addTitle(" ")
    end
  end

  -- OnApplyMainMenu/OnApplyInGame (PZAPI's own ModOptions apply callbacks)
  -- confirmed via in-game log to never fire on this build -- client.lua's
  -- own monkeypatch on vanilla MainOptions:apply is the only Apply path that
  -- actually works, don't re-add these without re-confirming first.
end

qol_setup.sync_mod_options = function (source)
  log.debug("sync_mod_options() triggered by: " .. _tostring(source or "unknown"))
  if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions) then return end

  local opts = PZAPI.ModOptions:getOptions(_mod_id)
  if not opts then return end

  for _, def in _ipairs(FEATURE_DEFS) do
    local opt = opts:getOption(def.pzapi_key)
    if opt then
      qol_setup.set_feature_enabled(def.key, opt:getValue() and true or false)
    end
  end

  local opt_color = opts:getOption("ZombieOutline_Color")
  if opt_color then
    local def_r, def_g, def_b, def_a = qol_setup.get_zombie_outline_custom_color()
    local r, g, b, a = _extract_color(opt_color, def_r, def_g, def_b, def_a)
    qol_setup.update_zombie_outline_custom_color(r, g, b, a)
  end

  local opt_behavior = opts:getOption("QoL_BrokenWeaponBehavior")
  if opt_behavior then
    local behavior_key = _broken_weapon_behavior_order[opt_behavior:getValue()] or "drop"
    qol_setup.set_broken_weapon_behavior(behavior_key)
  end
end

-- ==============================================================================
-- Debug panel tab (CoreLib debug panel, Debug Mode only): live toggles for the
-- same FEATURE_DEFS, without going through the vanilla ModOptions Apply flow.
-- ==============================================================================

---@class QoLOptionsTabUI: ISPanel
local QoLOptionsTabUI = ISPanel:derive("QoLOptionsTabUI")

function QoLOptionsTabUI:initialise()
  ISPanel.initialise(self)

  local font = (UIFont and UIFont.Small) and UIFont.Small or 0

  self.title_lbl = ISLabel:new(12, 10, 20, "null0x686F QoL V2 - Live Feature Control", 1, 1, 1, 1, font, true)
  self:addChild(self.title_lbl)

  self.tickbox = ISTickBox:new(12, 35, self.width - 24, #FEATURE_DEFS * 26, "", self, self.on_tick_toggled)
  self.tickbox:initialise()
  self:addChild(self.tickbox)

  self:populate_toggles()
end

function QoLOptionsTabUI:populate_toggles()
  self.tickbox.options = {}
  self.tickbox.optionData = {}
  self.tickbox.selected = {}
  self.tickbox.disabledOptions = {}
  self.tickbox.optionsIndex = {}
  self.tickbox.textures = {}
  self.tickbox.optionCount = 1

  for i, def in _ipairs(FEATURE_DEFS) do
    local is_enabled = qol_setup.is_feature_enabled(def.key)
    local idx = self.tickbox:addOption(def.label, def.key)
    self.tickbox:setSelected(idx, is_enabled)
  end
end

function QoLOptionsTabUI:on_tick_toggled(index, selected)
  local feat_key = self.tickbox:getOptionData(index)
  if not feat_key then return end

  -- 1. Update setup.lua memory cache in O(1)
  qol_setup.set_feature_enabled(feat_key, selected)

  -- 2. Bidirectional Sync with PZAPI.ModOptions (.ini persistence). Must use
  -- the real PZAPI option key (def.pzapi_key), not the internal feature key --
  -- they differ (e.g. "inv_name" vs "QoL_InvName").
  if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
    local opts = PZAPI.ModOptions:getOptions(_mod_id)
    if opts then
      local def = FEATURE_DEFS_BY_KEY[feat_key]
      local opt = def and opts:getOption(def.pzapi_key)
      if opt and opt.setValue then
        opt:setValue(selected)
      end
    end
  end

  log.debug(_string_format("QoL Tab Sync -> %s set to %s", feat_key, _tostring(selected)))
end

function QoLOptionsTabUI:new(x, y, width, height)
  local o = ISPanel:new(x, y, width, height)
  setmetatable(o, self)
  self.__index = self
  o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.85 }
  o.borderColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }
  return o
end

local function _register_qol_tab()
  tab_registry.registerTab("QoL Options", QoLOptionsTabUI, "NULL0X686F")
end

-- ==============================================================================

local _is_patched = false
local function init()
  _G.__Null0x686FQoL = _G.__Null0x686FQoL or {}
  local state = _G.__Null0x686FQoL
  if _is_patched or state.__modoptions_hooks then return end

  Events.OnGameBoot.Add(_init_mod_options)
  Events.OnGameStart.Add(function() qol_setup.sync_mod_options("OnGameStart") end)
  Events.OnGameStart.Add(_register_qol_tab)

  _is_patched = true
  state.__modoptions_hooks = true
end

return {
  init = init
}
