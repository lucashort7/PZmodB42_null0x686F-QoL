local hort_wiz_qol = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")
local cfg = require("null0x686F_QoL/cfg")

local _mod_id = "null0x686F_QoL"
local _mod_name = "null0x686F QoL Options"

local _broken_weapon_behavior_order = { "drop", "destroy", "nothing" }
local _broken_weapon_behavior_labels = {
  drop = "Drop on Ground",
  destroy = "Destroy",
  nothing = "Do Nothing",
}

local _string_format = string.format
local _tostring = tostring
local _tonumber = tonumber
local _type = type
local _pcall = pcall

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

  local def_r, def_g, def_b, def_a = hort_wiz_qol.get_zombie_outline_custom_color()
  local def_enabled = hort_wiz_qol.is_zombie_outline_enabled()

  -- Combat & Visual Highlights
  options:addTitle("--- Combat & Visual Highlights ---")
  options:addTickBox("ZombieOutline_Enabled", "Enable Custom Zombie Outline", def_enabled, "Toggles custom color highlighting for zombies when aiming.")
  options:addColorPicker("ZombieOutline_Color", "Custom Zombie Outline Color", def_r, def_g, def_b, def_a, "Changes the color of the zombie outline when aiming in melee mode.")

  options:addTitle(" ")
  -- Inventory & Clothing
  options:addTitle("--- Inventory & Clothing ---")
  options:addTickBox("QoL_InvName", "Player Name in Inventory", hort_wiz_qol.is_feature_enabled("inv_name"), "Adds the character's name to the inventory window title.")
  options:addTickBox("QoL_HideWorn", "Hide Worn Items", hort_wiz_qol.is_feature_enabled("hide_worn"), "Hides worn clothing from the main inventory list to declutter.")
  options:addTickBox("QoL_QuickContext", "Quick Context Menu Actions", hort_wiz_qol.is_feature_enabled("quick_context"), "Adds 1-click context menu shortcuts for Rip All Clothing, Swap Gas Mask Filter, and Bandages.")
  options:addTickBox("QoL_WalkAndEquip", "Walk/Aim While Equipping Clothing", hort_wiz_qol.is_feature_enabled("walk_and_equip"), "Allows walking or aiming while putting on/adjusting clothing without interrupting the action.")

  options:addTitle(" ")
  -- Survival & World Interactions
  options:addTitle("--- Survival & World Interactions ---")
  options:addTickBox("QoL_RackDry", "Rack Firearm to Dry", hort_wiz_qol.is_feature_enabled("rack_dry"), "Press Rack Firearm key to dry yourself when wet and empty-handed.")
  options:addTickBox("QoL_AutoUnsetAlarms", "Auto-Unset Alarms", hort_wiz_qol.is_feature_enabled("auto_unset_alarms"), "Automatically turns off alarms on looted digital watches and clocks.")
  options:addTickBox("QoL_FencePriority", "Fence Jump Priority", hort_wiz_qol.is_feature_enabled("fence_priority"), "Prioritizes vaulting fences over ground item interactions when close to fences.")
  options:addTickBox("QoL_Vehicles", "Vehicle Gas QoL", hort_wiz_qol.is_feature_enabled("vehicle_gas"), "Allows aiming while pumping gas and restores original equipped items when done.")

  options:addTitle(" ")
  -- Weapons
  options:addTitle("--- Weapons ---")
  options:addTickBox("QoL_AutoEquipBroken", "Auto-Handle Broken Weapons", hort_wiz_qol.is_feature_enabled("auto_equip_broken_weapon"), "Automatically handles your weapon when it breaks, and lets you re-equip a fresh copy with a hotkey.")

  local behavior_combo = options:addComboBox("QoL_BrokenWeaponBehavior", "On Weapon Break", "Choose what happens to your weapon automatically when it breaks in combat.")
  local current_behavior = hort_wiz_qol.get_broken_weapon_behavior()
  for _, behavior_key in ipairs(_broken_weapon_behavior_order) do
    behavior_combo:addItem(_broken_weapon_behavior_labels[behavior_key], behavior_key == current_behavior)
  end

  options:addKeyBind("QoL_ReequipBrokenKey", "Re-Equip Fresh Weapon (when broken)", cfg.AUTO_EQUIP_BROKEN_WEAPON.hotkey)

  options.OnApplyMainMenu = hort_wiz_qol.sync_mod_options
  options.OnApplyInGame = hort_wiz_qol.sync_mod_options
end

hort_wiz_qol.sync_mod_options = function ()
  if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions) then return end

  local opts = PZAPI.ModOptions:getOptions(_mod_id)
  if not opts then return end

  local opt_enabled = opts:getOption("ZombieOutline_Enabled")
  if opt_enabled then
    local is_enabled = opt_enabled:getValue() and true or false
    hort_wiz_qol.set_zombie_outline_enabled(is_enabled)
  end

  local opt_color = opts:getOption("ZombieOutline_Color")
  if opt_color then
    local def_r, def_g, def_b, def_a = hort_wiz_qol.get_zombie_outline_custom_color()
    local r, g, b, a = _extract_color(opt_color, def_r, def_g, def_b, def_a)
    hort_wiz_qol.update_zombie_outline_custom_color(r, g, b, a)
  end

  local feature_map = {
    QoL_RackDry = "rack_dry",
    QoL_InvName = "inv_name",
    QoL_HideWorn = "hide_worn",
    QoL_Vehicles = "vehicle_gas",
    QoL_AutoUnsetAlarms = "auto_unset_alarms",
    QoL_FencePriority = "fence_priority",
    QoL_QuickContext = "quick_context",
    QoL_WalkAndEquip = "walk_and_equip",
    QoL_AutoEquipBroken = "auto_equip_broken_weapon",
  }

  for opt_key, feature_key in pairs(feature_map) do
    local opt_obj = opts:getOption(opt_key)
    if opt_obj then
      local val = opt_obj:getValue() and true or false
      hort_wiz_qol.set_feature_enabled(feature_key, val)
    end
  end

  local opt_behavior = opts:getOption("QoL_BrokenWeaponBehavior")
  if opt_behavior then
    local behavior_key = _broken_weapon_behavior_order[opt_behavior:getValue()] or "drop"
    hort_wiz_qol.set_broken_weapon_behavior(behavior_key)
  end
end

Events.OnGameBoot.Add(_init_mod_options)
Events.OnGameStart.Add(hort_wiz_qol.sync_mod_options)
