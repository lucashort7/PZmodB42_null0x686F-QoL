require "ISUI/ISInventoryPaneContextMenu"
require "Entity/ISEntityUI"

local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")
local core_tools = require("null0x686F_CoreLib/tools")

local _is_patched = false
local _get_core = getCore

-- Vanilla craftRecipe names that cover all "dismantle electronics" cases
-- (media/scripts/generated/recipes/recipes_electrical.txt and
-- recipes_radio.txt). Item eligibility for each recipe is fully vanilla-owned
-- via CraftRecipeManager.getUniqueRecipeItems -- we only hardcode these 3
-- stable recipe names, not the underlying tags/fullType whitelists, so bonus
-- outputs (e.g. Speaker -> Amplifier) come free.
local DISMANTLE_RECIPE_NAMES = {
  "DismantleElectronics",
  "DismantleMiscElectronics",
  "DismantleElectronicsDevice",
}

local _dismantle_recipe_name_set = {}
for i = 1, #DISMANTLE_RECIPE_NAMES do
  _dismantle_recipe_name_set[DISMANTLE_RECIPE_NAMES[i]] = true
end

-- all 3 recipes require a Screwdriver (kept, not consumed) as an ingredient,
-- but we still gate the menu option's own availability ourselves (rather than
-- letting getPossibleCraftCount silently come back 0) so we get the same
-- "notAvailable" + tooltip UX rip_all_clothing.lua established.
local function _find_dismantle_tool(player)
  return core_tools.find_tool_by_tag(player, ItemTag.SCREWDRIVER)
end

-- fast reject for menu-fill: does this one clicked item participate in any of
-- our 3 dismantle recipes, in any role? getUniqueRecipeItems returns every
-- recipe the item could be used in (not filtered to "dismantle"), so we
-- filter the result ourselves by recipe name.
local function _matches_dismantle_recipe(item, player, containers)
  local recipes = item and CraftRecipeManager.getUniqueRecipeItems(item, player, containers)
  if not recipes then return false end

  for i = 0, recipes:size() - 1 do
    local recipe = recipes:get(i)
    if recipe and _dismantle_recipe_name_set[recipe:getName()] then
      return true
    end
  end

  return false
end

-- one pass over every item in every nearby container, looking for a single
-- "seed" item (+ its CraftRecipe object) per recipe name. HandcraftLogic only
-- needs one matching item to select the recipe -- it auto-discovers every
-- other eligible item across the container list on its own.
local function _find_dismantle_seeds(player, containers)
  local seeds = {}
  local remaining = #DISMANTLE_RECIPE_NAMES

  for c = 0, containers:size() - 1 do
    local container = containers:get(c)
    local items = container and container:getItems()

    if items then
      for i = 0, items:size() - 1 do
        local item = items:get(i)
        local recipes = CraftRecipeManager.getUniqueRecipeItems(item, player, containers)

        if recipes then
          for r = 0, recipes:size() - 1 do
            local recipe = recipes:get(r)
            local name = recipe and recipe:getName()
            if name and _dismantle_recipe_name_set[name] and not seeds[name] then
              seeds[name] = { item = item, recipe = recipe }
              remaining = remaining - 1
            end
          end
        end

        if remaining <= 0 then return seeds end
      end
    end
  end

  return seeds
end

-- ISHandcraftAction's batched multi-craft path doesn't reliably keep open
-- inventory/loot panels in sync (same issue the "Dismantle All at Once"
-- reference mod worked around) -- force every touched container to redraw
-- once the whole batch finishes.
local function _force_containers_dirty(_, containers)
  if not containers then return end
  for c = 0, containers:size() - 1 do
    local container = containers:get(c)
    if container and container.setDrawDirty then
      container:setDrawDirty(true)
    end
  end
end

-- re-discovers everything fresh at click time (not menu-build time) so a
-- stale item list can't cause issues if the inventory changed meanwhile.
-- drives ALL nearby containers, not just the one right-clicked.
local function _dismantle_all_electronics(player)
  if not player then return end

  local tool = _find_dismantle_tool(player)
  log.debug("dismantle_all_electronics: tool =", tool and tool:getFullType() or "none found")
  if not tool then
    log.debug("dismantle_all_electronics: no screwdriver found, aborting")
    return
  end

  local containers = ISInventoryPaneContextMenu.getContainers(player)
  if not containers or containers:size() == 0 then return end

  local seeds = _find_dismantle_seeds(player, containers)
  local last_actions = nil

  for i = 1, #DISMANTLE_RECIPE_NAMES do
    local recipe_name = DISMANTLE_RECIPE_NAMES[i]
    local seed = seeds[recipe_name]

    if seed then
      local logic = HandcraftLogic.new(player, nil, nil)
      logic:setContainers(containers)
      logic:setRecipeFromContextClick(seed.recipe, seed.item)

      local qty = logic:getPossibleCraftCount(true)
      log.debug("dismantle_all_electronics:", recipe_name, "qty =", qty)

      if qty > 0 then
        local actions = ISEntityUI.HandcraftStartMultiple(player, logic, false, qty, true)
        if actions and #actions > 0 then
          last_actions = actions
        end
      end
    else
      log.debug("dismantle_all_electronics:", recipe_name, "no matching item found, skipping")
    end
  end

  if last_actions then
    last_actions[#last_actions]:setOnComplete(_force_containers_dirty, containers)
  end
end

local function _on_fill_inventory_menu(player_num, context, items)
  if not setup.is_feature_enabled("quick_context") then return end
  local player = getSpecificPlayer(player_num)
  if not player or not items or #items == 0 then return end

  local first = type(items[1]) == "table" and items[1].items and items[1].items[1] or items[1]
  if not first then return end

  local containers = ISInventoryPaneContextMenu.getContainers(player)
  if not containers or not _matches_dismantle_recipe(first, player, containers) then return end

  local tool = _find_dismantle_tool(player)

  local option = context:addOption("Dismantle All Electronics", player, function()
    _dismantle_all_electronics(player)
  end)

  if not tool then
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    tooltip.description = "Requires a Screwdriver"
    option.notAvailable = true
    option.toolTip = tooltip
  end
end

local function _init_dismantle_all_electronics()
  if _is_patched then return end
  Events.OnFillInventoryObjectContextMenu.Add(_on_fill_inventory_menu)
  _is_patched = true
  log.debug("dismantle_all_electronics.lua initialized")
end

Events.OnGameStart.Add(_init_dismantle_all_electronics)
if _get_core() then _init_dismantle_all_electronics() end

return {
  init = _init_dismantle_all_electronics
}
