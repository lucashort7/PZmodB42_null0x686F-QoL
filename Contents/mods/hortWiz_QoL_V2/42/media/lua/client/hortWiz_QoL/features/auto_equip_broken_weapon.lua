local log = require("hortWiz_QoL/log")
local setup = require("hortWiz_QoL/setup")
local cfg = require("hortWiz_QoL/cfg")

local _is_patched = false
local _get_core = getCore
local _get_specific_player = getSpecificPlayer
local _instanceof = instanceof
local _mod_id = "hortWiz_QoL_V2"

-- keyed by 1=primary, 2=secondary. { full_type, pending } where pending means
-- "this slot broke and is still waiting to be handled by the re-equip hotkey".
local _last_real_weapon = { [1] = nil, [2] = nil }

local function _get_hand_item(playerObj, slot)
  if slot == 1 then return playerObj:getPrimaryHandItem() end
  return playerObj:getSecondaryHandItem()
end

-- opportunistically remember the last known-good weapon per slot, so that once it
-- transforms into an unrelated leftover item (Base.SmallHandle, etc.) we still know
-- what to search for. cheap: only runs on the low-frequency attack-finished event.
local function _refresh_slot_if_healthy(playerObj, slot)
  local item = _get_hand_item(playerObj, slot)
  if item and _instanceof(item, "HandWeapon") and not item:isBroken() and item:getCondition() > 0 then
    _last_real_weapon[slot] = { full_type = item:getFullType(), pending = false }
  end
end

-- mirrors vanilla ISInventoryPaneContextMenu.dropItem
local function _drop_weapon(playerObj, item)
  playerObj:removeAttachedItem(item)
  if playerObj:isHandItem(item) then
    ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, 1, "drop"))
  end
  ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(
    playerObj, item, item:getContainer(), ISInventoryPage.GetFloorContainer(playerObj:getPlayerNum())))
end

local function _destroy_weapon(playerObj, item)
  playerObj:removeFromHands(item)
  playerObj:getInventory():Remove(item)
end

local function _apply_break_behavior(playerObj, slot)
  local item = _get_hand_item(playerObj, slot)
  if not item then return end

  local behavior = setup.get_broken_weapon_behavior()
  if behavior == "drop" then
    _drop_weapon(playerObj, item)
  elseif behavior == "destroy" then
    _destroy_weapon(playerObj, item)
  end
  -- "nothing" -> leave the leftover equipped, exactly as vanilla would
end

local function _on_weapon_broke(playerObj, slot, original_full_type)
  _last_real_weapon[slot] = { full_type = original_full_type, pending = true }
  _apply_break_behavior(playerObj, slot)
  log.debug("auto_equip_broken_weapon.lua BROKE slot=" .. slot .. " type=" .. original_full_type)
end

-- primary interception: wrap every OnBreak.<Weapon> handler. at the moment the engine
-- calls it, `item` is still the original, unbroken reference -- capture its fullType
-- before letting the vanilla handler transform/remove it into a leftover part.
local function _patch_onbreak_table()
  if OnBreak and not OnBreak.__HORT_PATCHED then
    OnBreak.__HORT_PATCHED = true
    for name, original_fn in pairs(OnBreak) do
      if type(original_fn) == "function" then
        OnBreak[name] = function(item, player, ...)
          local captured_type = item and item.getFullType and item:getFullType() or nil
          local was_primary = captured_type and player and player:getPrimaryHandItem() == item
          local was_secondary = captured_type and player and player:getSecondaryHandItem() == item

          local result = original_fn(item, player, ...)

          if setup.is_feature_enabled("auto_equip_broken_weapon") then
            if was_primary then
              _on_weapon_broke(player, 1, captured_type)
            elseif was_secondary then
              _on_weapon_broke(player, 2, captured_type)
            end
          end

          return result
        end
      end
    end
  end
end

-- fallback for weapon types with no OnBreak handler (e.g. firearms): they just sit at
-- condition 0 on the SAME fullType with no transformation, so no leftover-tracking is
-- needed. if OnBreak already handled this item, `weapon` no longer matches the current
-- hand item (it was replaced/removed), so this naturally no-ops in that case.
local function _on_player_attack_finished(playerObj, weapon)
  if not playerObj then return end

  _refresh_slot_if_healthy(playerObj, 1)
  _refresh_slot_if_healthy(playerObj, 2)

  if not setup.is_feature_enabled("auto_equip_broken_weapon") then return end
  if not weapon or not weapon.isBroken then return end
  if not (weapon:isBroken() or (weapon.getCondition and weapon:getCondition() <= 0)) then return end

  if playerObj:getPrimaryHandItem() == weapon then
    _on_weapon_broke(playerObj, 1, weapon:getFullType())
  elseif playerObj:getSecondaryHandItem() == weapon then
    _on_weapon_broke(playerObj, 2, weapon:getFullType())
  end
end

local function _find_replacement(inv, full_type)
  return inv:getFirstTypeEvalRecurse(full_type, function(it)
    return it:getCondition() > 0
  end)
end

local function _try_reequip_slot(playerObj, slot)
  local cached = _last_real_weapon[slot]
  if not cached or not cached.pending then return false end

  local inv = playerObj:getInventory()
  local replacement = _find_replacement(inv, cached.full_type)
  if not replacement then return false end

  local two_hands = false
  if replacement.isTwoHandWeapon and replacement:isTwoHandWeapon() then
    two_hands = true
  elseif replacement.isRequiresEquippedBothHands and replacement:isRequiresEquippedBothHands() then
    two_hands = true
  end

  ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, replacement, 50, slot == 1, two_hands))
  cached.pending = false
  return true
end

local function _on_key_pressed(key)
  if not setup.is_feature_enabled("auto_equip_broken_weapon") then return end

  local current_hotkey = cfg.AUTO_EQUIP_BROKEN_WEAPON.hotkey
  if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
    local opts = PZAPI.ModOptions:getOptions(_mod_id)
    if opts then
      local kb = opts:getOption("QoL_ReequipBrokenKey")
      if kb and kb:getValue() then current_hotkey = kb:getValue() end
    end
  end
  if key ~= current_hotkey then return end

  local player = _get_specific_player(0)
  if not player or player:isDead() then return end

  if _try_reequip_slot(player, 1) then return end
  _try_reequip_slot(player, 2)
end

local function _init_auto_equip_broken_weapon()
  if _is_patched then return end
  _patch_onbreak_table()
  Events.OnPlayerAttackFinished.Add(_on_player_attack_finished)
  Events.OnKeyPressed.Add(_on_key_pressed)
  _is_patched = true
  log.debug("auto_equip_broken_weapon.lua initialized")
end

Events.OnGameStart.Add(_init_auto_equip_broken_weapon)
if _get_core() then _init_auto_equip_broken_weapon() end

return {
  init = _init_auto_equip_broken_weapon
}
