local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _get_core = getCore

local function _on_fill_inventory_menu(player_num, context, items)
  if not setup.is_feature_enabled("auto_unset_alarms") then return end
  if not items then return end
  local player = getSpecificPlayer(player_num)
  if not player then return end

  for _, v in ipairs(items) do
    local item = type(v) == "table" and v.items and v.items[1] or v
    if item and instanceof(item, "AlarmClockClothing") then
      if item:isAlarmSet() then
        item:setAlarmSet(false)
        log.debug("auto_unset_alarms.lua: Auto-unset alarm on looted item: " .. tostring(item:getName()))
      end
    elseif item and instanceof(item, "AlarmClock") then
      if item:isAlarmSet() then
        item:setAlarmSet(false)
        log.debug("auto_unset_alarms.lua: Auto-unset alarm on looted clock: " .. tostring(item:getName()))
      end
    end
  end
end

local function _init_auto_unset_alarms()
  if _is_patched then return end
  Events.OnFillInventoryObjectContextMenu.Add(_on_fill_inventory_menu)
  _is_patched = true
  log.debug("auto_unset_alarms.lua initialized")
end

return {
  init = _init_auto_unset_alarms
}
