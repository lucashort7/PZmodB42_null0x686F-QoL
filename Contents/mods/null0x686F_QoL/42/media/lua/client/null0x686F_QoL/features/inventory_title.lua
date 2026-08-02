local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _get_specific_player = getSpecificPlayer

local function _patch_inventory_title()
  if _is_patched then return end
  if not ISInventoryPage then return end

  local original_prerender = ISInventoryPage.prerender
  function ISInventoryPage:prerender()
    original_prerender(self)

    if not setup.is_feature_enabled("inv_name") then return end

    if self.onCharacter then
      local player = _get_specific_player(self.player)
      if player and self.inventory == player:getInventory() then
        local desc = player:getDescriptor()
        local name = ((desc and desc:getForename()) or "") .. " " .. ((desc and desc:getSurname()) or "")
        name = name:gsub("^%s*(.-)%s*$", "%1")
        if name ~= "" then
          self.title = name .. "'s Inventory"
        end
      end
    end
  end

  _is_patched = true
  log.debug("inventory_title.lua initialized")
end

return {
  init = _patch_inventory_title
}
