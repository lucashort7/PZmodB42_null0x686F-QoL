local qol_setup = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")

local _is_patched = false
local _get_core = getCore
local _instanceof = instanceof

local _is_melee_outline_enabled = true
local _was_aiming = false

---@type IsoZombie|nil
local _last_highlighted_zombie = nil

-- Vanilla-option capture: reads PZ's own Core "melee outline" setting, not a
-- mod setting of ours. Only feature in the mod that touches a vanilla option
-- directly, so this stays local instead of a shared helper (revisit if a
-- second feature ever needs one).
local function _update_core_configs()
  local core = _get_core and _get_core() or nil
  if core and core.getOptionMeleeOutline then
    local val = core:getOptionMeleeOutline()
    if type(val) == "string" then
      _is_melee_outline_enabled = (val ~= "None" and val ~= "none" and val ~= "0")
    elseif type(val) == "number" then
      _is_melee_outline_enabled = (val > 0)
    elseif val ~= nil then
      _is_melee_outline_enabled = val and true or false
    else
      _is_melee_outline_enabled = true
    end
  else
    _is_melee_outline_enabled = true
  end
end

---@param player IsoPlayer
---@return boolean
local function _is_ranged_primary(player)
  local weapon = player and player:getPrimaryHandItem() or nil
  if not weapon or not _instanceof(weapon, "HandWeapon") then
    return false
  end
  return weapon:isRanged()
end

---@param player IsoPlayer
local function _apply_vanilla_zombie_outline_custom_color(player)
  if not qol_setup.is_feature_enabled("zombie_outline") then return end

  if not player then return end
  local is_local_player = player.isLocalPlayer and player:isLocalPlayer() or false
  local is_npc = (player.isNpc and player:isNpc()) or (player.isNPC and player:isNPC()) or false
  if not is_local_player or is_npc then return end

  local is_aiming = player:isAiming() and player:isWeaponReady()

  if is_aiming and not _was_aiming then
    if qol_setup.sync_mod_options then
      qol_setup.sync_mod_options()
    end
  end
  _was_aiming = is_aiming

  if not is_aiming then
    _last_highlighted_zombie = nil
    return
  end

  if _is_ranged_primary(player) then return end
  if not _is_melee_outline_enabled then return end

  local player_num = player:getPlayerNum()
  local r, g, b, a = qol_setup.get_zombie_outline_custom_color()

  if _last_highlighted_zombie and not _last_highlighted_zombie:isDead() then
    if _last_highlighted_zombie:isOutlineHighlight(player_num) then
      _last_highlighted_zombie:setOutlineHighlightCol(player_num, r, g, b, a)
      return
    end
  end

  local cell = player:getCell()
  if not cell then return end

  local zombies = cell:getZombieList()
  if not zombies or zombies:size() == 0 then return end

  for i = 0, zombies:size() - 1 do
    local zombie = zombies:get(i)
    if zombie and zombie:isOutlineHighlight(player_num) then
      zombie:setOutlineHighlightCol(player_num, r, g, b, a)
      _last_highlighted_zombie = zombie
      break
    end
  end
end

local function _init_zombie_outline()
  if _is_patched then return end
  Events.OnPlayerUpdate.Add(_apply_vanilla_zombie_outline_custom_color)
  Events.OnGameStart.Add(_update_core_configs)
  _update_core_configs()
  _is_patched = true
  log.debug("zombie_outline.lua initialized")
end

return {
  init = _init_zombie_outline,
  update_configs = _update_core_configs
}
