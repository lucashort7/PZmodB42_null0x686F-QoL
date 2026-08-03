-- data only: what the options screen offers, with no knowledge of how it is
-- built or read back. lived inline in modoptions.lua, which meant one file
-- owned the declaration, the widget construction, the read-back and a patch on
-- a third-party library.
--
-- holds getText() KEYS, not text. resolution happens when the UI is built --
-- calling getText() in a table literal would evaluate at file-parse time, and
-- the translation table is not guaranteed loaded that early.
--
-- the tooltip key is always the label key plus "_tooltip", so it is derived
-- rather than stored: two fields that must agree is two fields that can drift.

-- single source of truth for every boolean feature toggle: drives the
-- ModOptions tickboxes, the read-back in modoptions.sync(), and the debug
-- tab's toggle list, so the three cannot drift apart.
--
-- non-boolean settings (outline colour, broken-weapon behaviour) are built by
-- hand in modoptions.lua -- they do not fit this shape.
local FEATURE_DEFS = {
  {
    key = "zombie_outline",
    pzapi_key = "ZombieOutline_Enabled",
    section = "combat",
    label_key = "UI_null0x686F_QoL_zombie_outline",
  },
  {
    key = "inv_name",
    pzapi_key = "QoL_InvName",
    section = "inventory",
    label_key = "UI_null0x686F_QoL_inv_name",
  },
  {
    key = "hide_worn",
    pzapi_key = "QoL_HideWorn",
    section = "inventory",
    label_key = "UI_null0x686F_QoL_hide_worn",
  },
  {
    key = "quick_context",
    pzapi_key = "QoL_QuickContext",
    section = "inventory",
    label_key = "UI_null0x686F_QoL_quick_context",
  },
  {
    key = "walk_and_equip",
    pzapi_key = "QoL_WalkAndEquip",
    section = "inventory",
    label_key = "UI_null0x686F_QoL_walk_and_equip",
  },
  {
    key = "auto_unset_alarms",
    pzapi_key = "QoL_AutoUnsetAlarms",
    section = "survival",
    label_key = "UI_null0x686F_QoL_auto_unset_alarms",
  },
  {
    key = "auto_equip_broken_weapon",
    pzapi_key = "QoL_AutoEquipBroken",
    section = "weapons",
    label_key = "UI_null0x686F_QoL_auto_equip_broken_weapon",
  },
}

local SECTION_ORDER = { "combat", "inventory", "survival", "weapons" }

local SECTION_TITLE_KEYS = {
  combat = "UI_null0x686F_QoL_section_combat",
  inventory = "UI_null0x686F_QoL_section_inventory",
  survival = "UI_null0x686F_QoL_section_survival",
  weapons = "UI_null0x686F_QoL_section_weapons",
}

-- order is the contract with the combo box: PZAPI hands back the selected
-- index, so this table is what turns that number into a behaviour key.
local BROKEN_WEAPON_ORDER = { "drop", "destroy", "nothing" }

local BROKEN_WEAPON_LABEL_KEYS = {
  drop = "UI_null0x686F_QoL_broken_drop",
  destroy = "UI_null0x686F_QoL_broken_destroy",
  nothing = "UI_null0x686F_QoL_broken_nothing",
}

return {
  FEATURE_DEFS = FEATURE_DEFS,
  SECTION_ORDER = SECTION_ORDER,
  SECTION_TITLE_KEYS = SECTION_TITLE_KEYS,
  BROKEN_WEAPON_ORDER = BROKEN_WEAPON_ORDER,
  BROKEN_WEAPON_LABEL_KEYS = BROKEN_WEAPON_LABEL_KEYS,
}
