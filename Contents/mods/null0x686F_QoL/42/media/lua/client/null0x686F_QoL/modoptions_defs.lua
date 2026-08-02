-- data only: what the options screen offers, with no knowledge of how it is
-- built or read back. lived inline in modoptions.lua, which meant one file
-- owned the declaration, the widget construction, the read-back and a patch on
-- a third-party library.
--
-- this is also where the getText() keys will go when the strings move to
-- Translate/EN -- they belong with the declaration, not with the UI code.

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
    label = "Enable Custom Zombie Outline",
    tooltip = "Toggles custom color highlighting for zombies when aiming.",
  },
  {
    key = "inv_name",
    pzapi_key = "QoL_InvName",
    section = "inventory",
    label = "Player Name in Inventory",
    tooltip = "Adds the character's name to the inventory window title.",
  },
  {
    key = "hide_worn",
    pzapi_key = "QoL_HideWorn",
    section = "inventory",
    label = "Hide Worn Items",
    tooltip = "Hides worn clothing from the main inventory list to declutter.",
  },
  {
    key = "quick_context",
    pzapi_key = "QoL_QuickContext",
    section = "inventory",
    label = "Quick Context Menu Actions",
    tooltip = "Adds 1-click context menu shortcuts for Rip All Clothing, "
      .. "Swap Gas Mask Filter, and Bandages.",
  },
  {
    key = "walk_and_equip",
    pzapi_key = "QoL_WalkAndEquip",
    section = "inventory",
    label = "Walk/Aim While Equipping Clothing",
    tooltip = "Allows walking or aiming while putting on/adjusting clothing "
      .. "without interrupting the action.",
  },
  {
    key = "auto_unset_alarms",
    pzapi_key = "QoL_AutoUnsetAlarms",
    section = "survival",
    label = "Auto-Unset Alarms",
    tooltip = "Automatically turns off alarms on looted digital watches and clocks.",
  },
  {
    key = "auto_equip_broken_weapon",
    pzapi_key = "QoL_AutoEquipBroken",
    section = "weapons",
    label = "Auto-Handle Broken Weapons",
    tooltip = "Automatically handles your weapon when it breaks, and lets you "
      .. "re-equip a fresh copy with a hotkey.",
  },
}

local SECTION_ORDER = { "combat", "inventory", "survival", "weapons" }

local SECTION_TITLES = {
  combat = "--- Combat & Visual Highlights ---",
  inventory = "--- Inventory & Clothing ---",
  survival = "--- Survival & World Interactions ---",
  weapons = "--- Weapons ---",
}

-- order is the contract with the combo box: PZAPI hands back the selected
-- index, so this table is what turns that number into a behaviour key.
local BROKEN_WEAPON_ORDER = { "drop", "destroy", "nothing" }

local BROKEN_WEAPON_LABELS = {
  drop = "Drop on Ground",
  destroy = "Destroy",
  nothing = "Do Nothing",
}

return {
  FEATURE_DEFS = FEATURE_DEFS,
  SECTION_ORDER = SECTION_ORDER,
  SECTION_TITLES = SECTION_TITLES,
  BROKEN_WEAPON_ORDER = BROKEN_WEAPON_ORDER,
  BROKEN_WEAPON_LABELS = BROKEN_WEAPON_LABELS,
}
