local hort_wiz_qol = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")

log.info("==================================================")
log.info("null0x686F_QoL_V2 :: Single-Feature Architecture Boot")
log.info("==================================================")

-- ==============================================================================
-- QoL Features Loader (1 file per feature)
-- ==============================================================================
require("null0x686F_QoL/features/dry_towel_hotkey")
require("null0x686F_QoL/features/inventory_title")
require("null0x686F_QoL/features/worn_items_toggle")
require("null0x686F_QoL/features/gas_siphon_walk")
require("null0x686F_QoL/features/auto_unset_alarms")
require("null0x686F_QoL/features/fence_interaction_priority")
-- Quick Context Actions theme: 1 file per action (Rip All Clothing, Dismantle, Wash Clothing, Grab Items, ...)
require("null0x686F_QoL/features/quick_context_actions/rip_all_clothing")
require("null0x686F_QoL/features/quick_context_actions/dismantle_all_electronics")
require("null0x686F_QoL/features/walk_and_equip")
require("null0x686F_QoL/features/auto_equip_broken_weapon")
local zombie_outline = require("null0x686F_QoL/features/zombie_outline")
-- ==============================================================================

local _is_main_options_patched = false
local function _patch_main_options()
  if MainOptions and MainOptions.apply and not _is_main_options_patched then
    local original_apply = MainOptions.apply
    function MainOptions:apply(...)
      log.info("MainOptions:apply() intercepted by null0x686F_QoL!")
      original_apply(self, ...)
      if zombie_outline and zombie_outline.update_configs then
        zombie_outline.update_configs()
      end
      if hort_wiz_qol.sync_mod_options then
        hort_wiz_qol.sync_mod_options()
      end
    end

    _is_main_options_patched = true
  end
end

Events.OnGameStart.Add(_patch_main_options)
_patch_main_options()

log.info("null0x686F_QoL_V2 :: All 11 features loaded successfully!")
