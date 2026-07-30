require("TimedActions/ISBaseTimedAction")
require "ISUI/ISInventoryPaneContextMenu"

local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _get_core = getCore

ISRipClothingAction = ISBaseTimedAction:derive("ISRipClothingAction")

function ISRipClothingAction:isValid()
  return self.character:getInventory():contains(self.item)
    and (self.tool == nil or self.character:getInventory():contains(self.tool))
end

function ISRipClothingAction:update()
  self.item:setJobDelta(self:getJobDelta())
end

function ISRipClothingAction:start()
  self.item:setJobType("Ripping")
  self.item:setJobDelta(0.0)
  self:setActionAnim("Craft")
end

function ISRipClothingAction:stop()
  ISBaseTimedAction.stop(self)
  self.item:setJobDelta(0.0)
end

function ISRipClothingAction:perform()
  local fabric_type = self.item.getFabricType and self.item:getFabricType()
  local fabric_def = fabric_type and ClothingRecipesDefinitions and ClothingRecipesDefinitions["FabricType"] and ClothingRecipesDefinitions["FabricType"][fabric_type]
  local result_material = fabric_def and fabric_def.material or "Base.RippedSheets"

  local inv = self.character:getInventory()
  inv:Remove(self.item)
  inv:AddItem(result_material)

  ISBaseTimedAction.perform(self)
end

function ISRipClothingAction:new(character, item, tool, time)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.character = character
  o.item = item
  o.tool = tool
  o.stopOnWalk = false
  o.stopOnRun = true
  o.maxTime = time or 40
  return o
end

local FABRIC_TYPES = { "Cotton", "Denim", "Leather" }

-- Cotton tears by hand; Denim/Leather (and anything else) need a cutting tool.
local function _fabric_needs_tool(fabric_type)
  return fabric_type ~= "Cotton"
end

-- Rag/DenimStrips/LeatherStrips also carry a FabricType (so vanilla sewing
-- recipes can match "any Cotton material"), but they're base:normal items,
-- not Clothing -- getFabricType() alone isn't enough to spot rippable items.
local function _get_rippable_fabric_type(item)
  if not item or not instanceof(item, "Clothing") then return nil end
  return item.getFabricType and item:getFabricType()
end

local core_tools = require("null0x686F_CoreLib/utils/item_finder")

local function _find_rip_tool(player)
  return core_tools.find_tool_by_tag(player, { ItemTag.SCISSORS, ItemTag.SHARP_KNIFE })
end

-- One pass over the container: buckets eligible items (not equipped, not
-- favorite) per fabric type, and counts what got skipped for logging.
local function _scan_rippable_items(player, container)
  local buckets = { Cotton = {}, Denim = {}, Leather = {} }
  local skipped_equipped, skipped_favorite = 0, 0

  local items = container and container:getItems()
  if not items then return buckets, skipped_equipped, skipped_favorite end

  for i = 0, items:size() - 1 do
    local item = items:get(i)
    local fabric_type = _get_rippable_fabric_type(item)
    if fabric_type then
      if player:isEquippedClothing(item) then
        skipped_equipped = skipped_equipped + 1
      elseif item:isFavorite() then
        skipped_favorite = skipped_favorite + 1
      elseif buckets[fabric_type] then
        table.insert(buckets[fabric_type], item)
      end
    end
  end

  return buckets, skipped_equipped, skipped_favorite
end

local function _queue_rip(player, items, tool)
  local inv = player:getInventory()
  for i = 1, #items do
    local item = items[i]
    if item:getContainer() ~= inv then
      ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), inv))
    end
    ISTimedActionQueue.add(ISRipClothingAction:new(player, item, tool, 40))
  end
end

-- fabric_filter == nil means "Rip All" (every fabric type); otherwise only
-- that one type. Re-scans the container fresh so a stale item list from
-- menu-build time can't cause issues if inventory changed meanwhile.
local function _rip_clothing(player, container, fabric_filter)
  if not player or not container then return end

  local tool = _find_rip_tool(player)
  log.debug("rip_all_clothing: tool =", tool and tool:getFullType() or "none found")

  local buckets, skipped_equipped, skipped_favorite = _scan_rippable_items(player, container)

  local to_rip = {}
  local skipped_no_tool = 0
  local types = fabric_filter and { fabric_filter } or FABRIC_TYPES
  for i = 1, #types do
    local ftype = types[i]
    local bucket = buckets[ftype]
    for j = 1, #bucket do
      local item = bucket[j]
      if not tool and _fabric_needs_tool(ftype) then
        skipped_no_tool = skipped_no_tool + 1
      else
        table.insert(to_rip, item)
      end
    end
  end

  if skipped_equipped > 0 or skipped_favorite > 0 or skipped_no_tool > 0 then
    log.debug("rip_all_clothing: skipped", skipped_equipped, "equipped,", skipped_favorite, "favorite,", skipped_no_tool, "needing a tool")
  end

  log.debug("rip_all_clothing: queuing", #to_rip, "item(s) for ripping", fabric_filter or "(all types)")

  _queue_rip(player, to_rip, tool)
end

-- Adds a toolTip describing tool status to a Denim/Leather submenu option,
-- and grays it out (notAvailable) if no tool is available yet. No-op for
-- Cotton, which never needs a tool.
local function _add_tool_status(option, fabric_type, tool)
  if not _fabric_needs_tool(fabric_type) then return end

  local tooltip = ISInventoryPaneContextMenu.addToolTip()
  if tool then
    tooltip.description = "Tool found: " .. tool:getFullType()
  else
    tooltip.description = "Requires Scissors or a Sharp Knife"
    option.notAvailable = true
  end
  option.toolTip = tooltip
end

local function _on_fill_inventory_menu(player_num, context, items)
  if not setup.is_feature_enabled("quick_context") then return end
  local player = getSpecificPlayer(player_num)
  if not player or not items or #items == 0 then return end

  local first = type(items[1]) == "table" and items[1].items and items[1].items[1] or items[1]
  if not first then return end
  if not _get_rippable_fabric_type(first) then return end

  local container = first:getContainer() or player:getInventory()
  local buckets = _scan_rippable_items(player, container)
  local tool = _find_rip_tool(player)

  local total = 0
  local needs_tool_available = false
  for i = 1, #FABRIC_TYPES do
    local ftype = FABRIC_TYPES[i]
    local count = #buckets[ftype]
    total = total + count
    if count > 0 and _fabric_needs_tool(ftype) then
      needs_tool_available = true
    end
  end
  if total == 0 then return end

  local anchor = context:addOption("Rip Clothing")
  local submenu = context:getNew(context)
  context:addSubMenu(anchor, submenu)

  local all_option = submenu:addOption("Rip All", player, function()
    _rip_clothing(player, container, nil)
  end)
  if not tool and needs_tool_available then
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    tooltip.description = "Denim/Leather items will be skipped (no Scissors or Sharp Knife)"
    all_option.toolTip = tooltip
  end

  for i = 1, #FABRIC_TYPES do
    local ftype = FABRIC_TYPES[i]
    if #buckets[ftype] > 0 then
      local option = submenu:addOption("Rip " .. ftype .. " Only", player, function()
        _rip_clothing(player, container, ftype)
      end)
      _add_tool_status(option, ftype, tool)
    end
  end
end

local function _init_quick_context_actions()
  if _is_patched then return end
  Events.OnFillInventoryObjectContextMenu.Add(_on_fill_inventory_menu)
  _is_patched = true
  log.debug("rip_all_clothing.lua initialized")
end

return {
  init = _init_quick_context_actions
}
