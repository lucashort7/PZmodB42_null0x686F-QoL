-- Re-equips a fresh copy of the weapon you just broke, on the vanilla reload key.
-- Inspired by TwisTonFire's "MeleeReloadHotbar" (Workshop 3480305875), which
-- originated the idea of sharing the reload keybind for this. Detection differs:
-- that mod infers leftovers from item naming, this one reads the break event.

local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

-- every log call passes its parts as separate varargs instead of concatenating.
-- the shared logger joins them itself, after its level guard, so a player running
-- at "info" never builds the string.
local _LOG = "auto_equip_broken_weapon.lua"

local _is_patched = false
local _get_core = getCore
local _get_specific_player = getSpecificPlayer
local _instanceof = instanceof

-- OnBreak holds two kinds of function: one handler per weapon, plus these three
-- shared helpers that nearly every handler calls internally. Wrapping the helpers
-- too makes a single break re-enter this feature once per helper call.
local _HELPERS = {
  GroundHandler = true,
  HeadHandler = true,
  HandleHandler = true,
}

-- true only while a vanilla OnBreak handler is running. HandleHandler puts the
-- leftover part straight into the hand, which would otherwise look like the player
-- arming themselves and cancel the re-equip we are in the middle of registering.
local _in_break = false

-- the flag is lowered a tick late rather than on the line after the vanilla handler
-- returns. if the engine dispatches OnEquipPrimary asynchronously, the leftover that
-- HandleHandler put in the hand arrives after the flag would already be down, and the
-- equip listener reads it as the player arming themselves -- which discards the pending
-- re-equip. costs one boolean per break and changes nothing if dispatch is synchronous.
local _clear_scheduled = false

local function _clear_in_break()
  Events.OnTick.Remove(_clear_in_break)
  _clear_scheduled = false
  _in_break = false
end

local function _schedule_in_break_clear()
  if _clear_scheduled then return end
  _clear_scheduled = true
  Events.OnTick.Add(_clear_in_break)
end

-- fullType of the weapon that broke and is still waiting for the re-equip key.
-- Only the primary hand is tracked: two-handed weapons occupy both slots but match
-- primary first, so the secondary slot only ever holds torches and the like.
local _pending = nil

-- mirrors vanilla ISInventoryPaneContextMenu.dropItem
local function _drop_weapon(playerObj, item)
  log.debug(_LOG, "drop leftover=", item:getFullType(), "inHand=", playerObj:isHandItem(item))
  playerObj:removeAttachedItem(item)
  if playerObj:isHandItem(item) then
    ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, 1, "drop"))
  end
  ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(
    playerObj, item, item:getContainer(), ISInventoryPage.GetFloorContainer(playerObj:getPlayerNum())))
end

local function _destroy_weapon(playerObj, item)
  log.debug(_LOG, "destroy leftover=", item:getFullType())
  playerObj:removeFromHands(item)
  playerObj:getInventory():Remove(item)
end

-- runs after vanilla finished transforming the weapon, so the hand now holds the
-- leftover part and the vanilla debris has already spawned.
local function _apply_break_behavior(playerObj)
  local item = playerObj:getPrimaryHandItem()
  if not item then
    log.debug(_LOG, "apply_break_behavior: primary hand already empty, nothing to apply")
    return
  end

  local behavior = setup.get_broken_weapon_behavior()
  log.debug(_LOG, "apply_break_behavior behavior=", behavior, "leftover=", item:getFullType())
  if behavior == "drop" then
    _drop_weapon(playerObj, item)
  elseif behavior == "destroy" then
    _destroy_weapon(playerObj, item)
  end
  -- "nothing" -> leave the leftover equipped, exactly as vanilla would
end

local function _on_weapon_broke(playerObj, original_full_type)
  _pending = original_full_type
  _apply_break_behavior(playerObj)
  log.debug(_LOG, "BROKE type=", original_full_type)
end

-- wrap every per-weapon OnBreak handler. at the moment the engine calls it, `item`
-- is still the original, unbroken reference -- capture its fullType before letting
-- the vanilla handler transform it into a leftover part.
local function _patch_onbreak_table()
  if not OnBreak then
    log.debug(_LOG, "patch skipped: OnBreak table does not exist yet")
    return
  end
  if OnBreak.__NULL0X686F_PATCHED then
    log.debug(_LOG, "patch skipped: OnBreak already patched")
    return
  end

  OnBreak.__NULL0X686F_PATCHED = true
  local wrapped_count = 0
  local probed_count = 0

  for name, original_fn in pairs(OnBreak) do
    if type(original_fn) == "function" and not _HELPERS[name] then
      wrapped_count = wrapped_count + 1
      OnBreak[name] = function(item, player, ...)
        local captured_type = item and item.getFullType and item:getFullType() or nil
        local was_primary = captured_type and player and player:getPrimaryHandItem() == item

        log.debug(_LOG, "onbreak enter handler=", name, "type=", captured_type, "wasPrimary=", was_primary)

        _in_break = true
        local result = original_fn(item, player, ...)
        _schedule_in_break_clear()

        local leftover = player and player:getPrimaryHandItem()
        log.debug(_LOG, "onbreak vanilla done handler=", name,
          "leftover=", leftover and leftover:getFullType() or "<empty hand>")

        if was_primary and setup.is_feature_enabled("auto_equip_broken_weapon") then
          _on_weapon_broke(player, captured_type)
        else
          log.debug(_LOG, "onbreak ignored handler=", name,
            "reason=", not was_primary and "not primary hand" or "feature disabled")
        end

        return result
      end
    elseif _HELPERS[name] then
      -- temporary scaffolding: observe only. the helpers must never run feature logic,
      -- because at this point the weapon's own handler has not finished and the vanilla
      -- leftover parts have not all spawned yet -- mutating the item here is what made
      -- an earlier version destroy the base game's own drops.
      probed_count = probed_count + 1
      OnBreak[name] = function(item, player, ...)
        log.debug(_LOG, "helper probe name=", name,
          "type=", item and item.getFullType and item:getFullType() or nil)
        return original_fn(item, player, ...)
      end
    end
  end

  log.debug(_LOG, "patched handlers=", wrapped_count, "probed shared helpers=", probed_count)
end

-- arming yourself by hand cancels the pending re-equip, so the key does nothing
-- instead of handing over a redundant duplicate.
local function _on_equip_primary(_player, item)
  if _in_break then
    log.debug(_LOG, "equip_primary ignored: vanilla break still running")
    return
  end
  if not item then
    log.debug(_LOG, "equip_primary ignored: item is nil (unequip)")
    return
  end
  if not _instanceof(item, "HandWeapon") then
    log.debug(_LOG, "equip_primary ignored: not a HandWeapon type=", item:getFullType())
    return
  end
  if item:isBroken() or item:getCondition() <= 0 then
    log.debug(_LOG, "equip_primary ignored: item is broken type=", item:getFullType())
    return
  end

  log.debug(_LOG, "equip_primary accepted type=", item:getFullType(), "pending=", _pending or "<none>")
  _pending = nil
end

local function _find_replacement(inv, full_type)
  return inv:getFirstTypeEvalRecurse(full_type, function(it)
    return it:getCondition() > 0
  end)
end

local function _try_reequip(playerObj)
  if not _pending then
    log.debug(_LOG, "reequip skipped: nothing pending")
    return
  end

  local replacement = _find_replacement(playerObj:getInventory(), _pending)
  if not replacement then
    log.debug(_LOG, "reequip skipped: no intact replacement in inventory for", _pending)
    return
  end

  local two_hands = false
  if replacement.isTwoHandWeapon and replacement:isTwoHandWeapon() then
    two_hands = true
    log.debug(_LOG, "reequip twoHands decided by isTwoHandWeapon")
  elseif replacement.isRequiresEquippedBothHands and replacement:isRequiresEquippedBothHands() then
    two_hands = true
    log.debug(_LOG, "reequip twoHands decided by isRequiresEquippedBothHands")
  end

  log.debug(_LOG, "reequip queued type=", _pending, "twoHands=", two_hands)
  ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, replacement, 50, true, two_hands))
  _pending = nil
end

-- shares the vanilla reload keybind: "make my weapon usable again" means reload for
-- a firearm and a fresh weapon for melee, and the two never apply at once. firearms
-- define no OnBreak handler, so they never set _pending and fall through to vanilla.
local function _on_key_pressed(key)
  -- both guards stay ahead of any logging: this fires on every keystroke, and the
  -- cheap enabled lookup must short-circuit before the isKey call into Java.
  if not setup.is_feature_enabled("auto_equip_broken_weapon") then return end
  if not _get_core():isKey("ReloadWeapon", key) then return end

  log.debug(_LOG, "reload key pressed, pending=", _pending or "<none>")

  local player = _get_specific_player(0)
  if not player or player:isDead() then
    log.debug(_LOG, "reload ignored: no living player")
    return
  end

  _try_reequip(player)
end

local function _init_auto_equip_broken_weapon()
  if _is_patched then
    log.debug(_LOG, "init skipped: already initialized")
    return
  end
  _patch_onbreak_table()
  Events.OnEquipPrimary.Add(_on_equip_primary)
  Events.OnKeyPressed.Add(_on_key_pressed)
  _is_patched = true
  log.debug(_LOG, "initialized")
end

return {
  init = _init_auto_equip_broken_weapon
}
