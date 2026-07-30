local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _string_lower = string.lower
local _tostring = tostring
local _ipairs = ipairs
local _table_insert = table.insert
local _table_wipe = table.wipe
local _get_specific_player = getSpecificPlayer

local _hide_cache = {}

local _TEXTURE_SHOWN = "media/ui/null0x686F_qol_eye.png"
local _TEXTURE_HIDDEN = "media/ui/null0x686F_qol_eye_crossed.png"
local _texture_shown_cache
local _texture_hidden_cache

local function _get_shown_texture()
  if not _texture_shown_cache then
    _texture_shown_cache = getTexture(_TEXTURE_SHOWN)
  end
  return _texture_shown_cache
end

local function _get_hidden_texture()
  if not _texture_hidden_cache then
    _texture_hidden_cache = getTexture(_TEXTURE_HIDDEN)
  end
  return _texture_hidden_cache
end

local function _on_fill_inventory_menu(player_num, context)
  if not setup.is_feature_enabled("hide_worn") then return end

  local player = _get_specific_player(player_num)
  if not player then return end

  local is_hiding = setup.is_hiding_worn_items()
  local label = is_hiding and "Show Worn Items" or "Hide Worn Items"

  local option = context:addOption(label, player, function()
    setup.set_hiding_worn_items(not is_hiding)

    local container = player:getInventory()
    if container and container.setDrawDirty then
      container:setDrawDirty(true)
    end
  end)

  option.iconTexture = is_hiding and _get_hidden_texture() or _get_shown_texture()
end

local function _patch_worn_items()
  if _is_patched then return end
  if not ISInventoryPane then return end

  local original_refresh = ISInventoryPane.refreshContainer

  function ISInventoryPane:refreshContainer()
    original_refresh(self)

    if not setup.is_feature_enabled("hide_worn") then return end
    if not setup.is_hiding_worn_items() then return end

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

  Events.OnFillInventoryObjectContextMenu.Add(_on_fill_inventory_menu)

  _is_patched = true
  log.debug("worn_items_toggle.lua initialized")
end

return {
  init = _patch_worn_items
}
