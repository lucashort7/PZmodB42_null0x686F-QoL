local qol_setup = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")
local zombie_outline = require("null0x686F_QoL/features/zombie_outline")
local mod_options = require("null0x686F_QoL/modoptions")

-- ==============================================================================
-- QoL Features Loader (1 file per feature)
-- ==============================================================================
local features_map = {
  dry_towel_hotkey = require("null0x686F_QoL/features/dry_towel_hotkey"),
  inventory_title = require("null0x686F_QoL/features/inventory_title"),
  worn_items_toggle = require("null0x686F_QoL/features/worn_items_toggle"),
  gas_siphon_walk = require("null0x686F_QoL/features/gas_siphon_walk"),
  auto_unset_alarms = require("null0x686F_QoL/features/auto_unset_alarms"),
  fence_interaction_priority = require("null0x686F_QoL/features/fence_interaction_priority"),
  rip_all_clothing = require("null0x686F_QoL/features/quick_context_actions/rip_all_clothing"),
  dismantle_all_electronics = require("null0x686F_QoL/features/quick_context_actions/dismantle_all_electronics"),
  walk_and_equip = require("null0x686F_QoL/features/walk_and_equip"),
  auto_equip_broken_weapon = require("null0x686F_QoL/features/auto_equip_broken_weapon"),
  zombie_outline = zombie_outline,
}
-- ==============================================================================

_G.__Null0x686FQoL = _G.__Null0x686FQoL or {
  __setup_hooks = false,
  __feature_hooks = false
}

log.info("==================================================")
log.info("null0x686F_QoL_V2 :: Single-Feature Architecture Boot")
log.info("==================================================")

local function _init_feature_hooks()
  local state = _G.__Null0x686FQoL
  if state.__feature_hooks then return true end

  local status, _ = pcall(function ()
    Events.OnCreatePlayer.Add(function ()
      for k, v in pairs(features_map) do
        v.init()
        log.debug(k .. " hook loaded!")
      end
      log.info("null0x686F_QoL_V2 :: All 11 features loaded successfully!")
    end)
  end)

  state.__feature_hooks = status
end

local function _patch_main_options()
  local state = _G.__Null0x686FQoL
  if MainOptions and MainOptions.apply and not state.__setup_hooks then
    local original_apply = MainOptions.apply
    function MainOptions:apply(...)
      log.info("MainOptions:apply() intercepted by null0x686F_QoL!")
      original_apply(self, ...)
      -- zombie_outline caches its RGBA locally (perf: avoids reading setup.lua
      -- every render tick), so it's the only feature that needs an explicit
      -- push here when Mod Options settings are saved. Every other feature reads
      -- setup.lua live on each event firing, no refresh needed.
      if zombie_outline and zombie_outline.update_configs then
        zombie_outline.update_configs()
      end
      if qol_setup.sync_mod_options then
        qol_setup.sync_mod_options("MainOptions:apply patch")
      end
    end

    state.__setup_hooks = true
  end
end

Events.OnGameStart.Add(_patch_main_options)
_patch_main_options()
_init_feature_hooks()

-- mod_options.init() registers on OnGameBoot/OnGameStart internally -- must be
-- called directly here (file scope), NOT through the OnCreatePlayer-gated
-- features_map loop above. The ModOptions UI needs to exist from the main
-- menu, before any save/player is loaded; gating it on OnCreatePlayer would
-- hide it until a save is already in progress.
mod_options.init()
