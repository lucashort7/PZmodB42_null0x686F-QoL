local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _rack_firearm_binding = "Rack Firearm"
local _towel_types = { BathTowel = true, DishCloth = true }

local _get_core = getCore
local _get_specific_player = getSpecificPlayer
local _get_cell = getCell

local function _is_firearm(item)
  if not item then return false end
  if item.isRanged and item:isRanged() then return true end
  if item.getAmmoType and item:getAmmoType() then return true end
  if item.getMagazineType and item:getMagazineType() then return true end
  return false
end

local function _has_held_firearm(player)
  if not player then return false end
  if _is_firearm(player:getPrimaryHandItem()) then return true end
  if _is_firearm(player:getSecondaryHandItem()) then return true end
  return false
end

local function _is_player_wet(player)
  if not player then return false end
  if player.getBodyDamage and player:getBodyDamage() then
    local wet = player:getBodyDamage():getWetness()
    if wet and wet > 0 then return true end
  end
  if player.getStats and player:getStats() then
    local wet = player:getStats():getWetness()
    if wet and wet > 0 then return true end
  end
  -- If player is in rain or has wet clothes, allow drying:
  if player.getPrimaryHandItem and player:getPrimaryHandItem() then
    local item = player:getPrimaryHandItem()
    if item and _towel_types[item:getType()] then return true end
  end
  return false
end

local function _find_best_towel(player)
  if not player then return nil end
  local inv = player:getInventory()
  if not inv then return nil end

  local items = inv:getItems()
  if items then
    for i = 0, items:size() - 1 do
      local item = items:get(i)
      if item and item.getType and _towel_types[item:getType()] then
        if item.getCurrentUsesFloat and item:getCurrentUsesFloat() > 0 then
          return item
        end
      end
    end
  end
  return nil
end

local function _on_key_start_pressed(key)
  if not setup.is_feature_enabled("rack_dry") then return end

  local core = _get_core()
  if not core or not core:isKey(_rack_firearm_binding, key) then return end

  local speed = UIManager.getSpeedControls()
  if speed and speed:getCurrentGameSpeed() == 0 then return end

  local player = _get_specific_player(0)
  if not player or player:isDead() then return end
  if _get_cell() and _get_cell():getDrag(0) then return end
  if player.isAttacking and player:isAttacking() then return end

  if _has_held_firearm(player) then return end
  if not _is_player_wet(player) then return end

  local queue = ISTimedActionQueue.getTimedActionQueue(player)
  if queue and queue.indexOfType and queue:indexOfType("ISDryMyself") > -1 then return end

  local towel = _find_best_towel(player)
  if not towel then return end

  local dry_action = ISDryMyself:new(player, towel)
  if dry_action then
    dry_action.stopOnWalk = false
    dry_action.stopOnRun = true
    dry_action.stopOnAim = false
    ISTimedActionQueue.add(dry_action)
  end
end

local function _init_dry_towel()
  if _is_patched then return end
  Events.OnKeyStartPressed.Add(_on_key_start_pressed)
  _is_patched = true
  log.debug("dry_towel_hotkey.lua initialized")
end

Events.OnGameStart.Add(_init_dry_towel)
if _get_core() then _init_dry_towel() end

return {
  init = _init_dry_towel
}
