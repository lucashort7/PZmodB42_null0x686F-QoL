local log = require("hortWiz_QoL/log")
local setup = require("hortWiz_QoL/setup")

local _is_patched = false
local _string_lower = string.lower
local _tostring = tostring
local _ipairs = ipairs
local _table_insert = table.insert
local _table_wipe = table.wipe
local _get_specific_player = getSpecificPlayer
local _get_core = getCore

local _hide_cache = {}

local function _patch_worn_items()
  if _is_patched then return end
  if not ISInventoryPane then return end

  local original_refresh = ISInventoryPane.refreshContainer

  function ISInventoryPane:refreshContainer()
    original_refresh(self)

    if not setup.is_feature_enabled("hide_worn") then return end

    local page = self.inventoryPage or self.parent
    if not page then return end

    local player = _get_specific_player(page.player or 0)
    if not player or self.inventory ~= player:getInventory() then return end

    if _table_wipe then
      _table_wipe(_hide_cache)
    else
      for k in pairs(_hide_cache) do _hide_cache[k] = nil end
    end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    local worn = player:getWornItems()
    for i = 0, worn:size() - 1 do
      local w_item = worn:get(i)
      local item = w_item and w_item:getItem()
      if item and item ~= primary and item ~= secondary then
        local loc = _string_lower(_tostring(w_item:getLocation() or ""))
        if loc ~= "keyring" and loc ~= "back" then
          _hide_cache[item] = true
        end
      end
    end

    local new_list = {}
    for _, group in _ipairs(self.itemslist) do
      if group and group.items then
        local visible_items = {}
        visible_items[1] = group.items[1]

        for i = 2, #group.items do
          local item = group.items[i]
          if not _hide_cache[item] then
            _table_insert(visible_items, item)
          end
        end

        if #visible_items > 1 then
          group.items = visible_items
          group.count = #visible_items
          _table_insert(new_list, group)
        end
      end
    end

    self.itemslist = new_list
    if self.updateScrollbars then self:updateScrollbars() end
  end

  _is_patched = true
  log.debug("worn_items_toggle.lua initialized")
end

Events.OnGameStart.Add(_patch_worn_items)
if _get_core() then _patch_worn_items() end

return {
  init = _patch_worn_items
}
