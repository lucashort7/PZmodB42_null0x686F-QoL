local null0x686F_QoL = {}
local cfg = require("null0x686F_QoL/cfg")
local log = require("null0x686F_QoL/log")

local _string_format = string.format

local r, g, b, a = 0.0, 1.0, 0.8, 1.0
local _is_zombie_outline_enabled = true

local _feature_toggles = {
  rack_dry = false,
  inv_name = true,
  hide_worn = true,
  vehicle_gas = true,
  auto_unset_alarms = true,
  fence_priority = true,
  quick_context = true,
  walk_and_equip = true,
  auto_equip_broken_weapon = true,
}

local _broken_weapon_behavior = "drop" -- "drop" | "destroy" | "nothing"

if cfg.ZOMBIE_OUTLINE then
  _is_zombie_outline_enabled = cfg.ZOMBIE_OUTLINE.enabled ~= false
  if type(cfg.ZOMBIE_OUTLINE.colorRGBA) == "table" then
    local color = cfg.ZOMBIE_OUTLINE.colorRGBA
    r = color[1] or r
    g = color[2] or g
    b = color[3] or b
    a = color[4] or a
  end
end

function null0x686F_QoL.is_zombie_outline_enabled()
  return _is_zombie_outline_enabled
end

function null0x686F_QoL.set_zombie_outline_enabled(enabled)
  _is_zombie_outline_enabled = enabled and true or false
  log.debug(_string_format("setup.lua CACHE UPDATED -> ZombieOutline=%s", tostring(_is_zombie_outline_enabled)))
end

local _is_hiding_worn_items = true

function null0x686F_QoL.is_hiding_worn_items()
  return _is_hiding_worn_items
end

function null0x686F_QoL.set_hiding_worn_items(enabled)
  _is_hiding_worn_items = enabled and true or false
  log.debug(_string_format("setup.lua CACHE UPDATED -> HidingWornItems=%s", tostring(_is_hiding_worn_items)))
end

function null0x686F_QoL.get_zombie_outline_custom_color()
  return r, g, b, a
end

function null0x686F_QoL.update_zombie_outline_custom_color(new_r, new_g, new_b, new_a)
  r = new_r or r
  g = new_g or g
  b = new_b or b
  a = new_a or a
  log.debug(_string_format("setup.lua CACHE UPDATED -> R=%.2f, G=%.2f, B=%.2f, A=%.2f", r, g, b, a))
end

function null0x686F_QoL.is_feature_enabled(feature_key)
  return _feature_toggles[feature_key] ~= false
end

function null0x686F_QoL.set_feature_enabled(feature_key, enabled)
  _feature_toggles[feature_key] = enabled and true or false
  log.debug(_string_format("setup.lua CACHE UPDATED -> %s=%s", feature_key, tostring(_feature_toggles[feature_key])))
end

function null0x686F_QoL.get_broken_weapon_behavior()
  return _broken_weapon_behavior
end

function null0x686F_QoL.set_broken_weapon_behavior(behavior)
  if behavior == "drop" or behavior == "destroy" or behavior == "nothing" then
    _broken_weapon_behavior = behavior
    log.debug(_string_format("setup.lua CACHE UPDATED -> BrokenWeaponBehavior=%s", behavior))
  end
end

return null0x686F_QoL
