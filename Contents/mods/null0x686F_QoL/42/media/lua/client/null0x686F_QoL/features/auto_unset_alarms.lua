-- disarms alarm clocks the player can see.
--
-- the trigger is VISIBILITY, not acquisition, and that distinction is the whole
-- point: an armed alarm makes noise from inside any container -- including a
-- corpse left on the ground -- and noise draws zombies. so a watch the player
-- opened, looked at and chose NOT to take is still worth disarming. any
-- pickup-based trigger leaves exactly that case uncovered.
--
-- this replaces OnFillInventoryObjectContextMenu, which the docs describe as
-- "triggered after the context menu for an inventory item is filled" -- it fires
-- on RIGHT-CLICK, not on looting. the feature therefore never ran in its own
-- main scenario: nobody right-clicks a wristwatch inside a dead zombie, they
-- open the loot window and drag or Grab All. it also had a menu-fill handler
-- mutating world state, which is not what that handler is for.
--
-- there is no vanilla event for "item entered the inventory" -- checked by name
-- and by description across all 183 documented events. the loot window refresh
-- is the closest thing to the fact this feature actually cares about.

local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false

-- AlarmClockClothing is the wristwatch a zombie was wearing, which is the case
-- that matters. AlarmClock is the bedside kind, found in houses.
local ALARM_CLASSES = { "AlarmClockClothing", "AlarmClock" }

local function _is_alarm(item)
  for _, class_name in ipairs(ALARM_CLASSES) do
    if instanceof(item, class_name) then return true end
  end
  return false
end

local function _disarm_container(container)
  if not container then return 0 end

  local items = container:getItems()
  if not items then return 0 end

  local disarmed = 0

  -- a java list: zero-indexed, and neither # nor ipairs work on it.
  for i = 0, items:size() - 1 do
    local item = items:get(i)
    if item and _is_alarm(item) and item:isAlarmSet() then
      item:setAlarmSet(false)
      disarmed = disarmed + 1
      log.debug("auto_unset_alarms: disarmed", tostring(item:getName()))
    end
  end

  return disarmed
end

-- the event fires four times per refresh -- begin / beforeFloor / buttonsAdded /
-- end, see ISInventoryPage.lua:1560-1902. "end" is the only one where every
-- container button is guaranteed to be present.
local function _on_containers_refreshed(inventory_page, reason)
  if reason ~= "end" then return end
  if not setup.is_feature_enabled("auto_unset_alarms") then return end
  if not inventory_page or not inventory_page.backpacks then return end

  local disarmed = 0
  for _, button in ipairs(inventory_page.backpacks) do
    disarmed = disarmed + _disarm_container(button.inventory)
  end

  if disarmed > 0 then
    log.debug("auto_unset_alarms: disarmed", disarmed, "alarm(s) across visible containers")
  end
end

local function init()
  if _is_patched then return end

  Events.OnRefreshInventoryWindowContainers.Add(_on_containers_refreshed)

  _is_patched = true
  log.debug("auto_unset_alarms.lua initialized")
end

return {
  init = init,
}
