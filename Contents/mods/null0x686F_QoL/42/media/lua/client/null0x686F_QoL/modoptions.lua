local qol_setup = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")
local defs = require("null0x686F_QoL/modoptions_defs")

local MOD_ID = "null0x686F_QoL"
local MOD_NAME_KEY = "UI_null0x686F_QoL_options_title"

local _is_patched = false

local function _build_options(options)
  local def_r, def_g, def_b, def_a = qol_setup.get_zombie_outline_custom_color()

  for i, section in ipairs(defs.SECTION_ORDER) do
    options:addTitle(getText(defs.SECTION_TITLE_KEYS[section]))

    for _, def in ipairs(defs.FEATURE_DEFS) do
      if def.section == section then
        options:addTickBox(def.pzapi_key,
          getText(def.label_key),
          qol_setup.is_feature_enabled(def.key),
          getText(def.label_key .. "_tooltip"))
      end
    end

    if section == "combat" then
      options:addColorPicker("ZombieOutline_Color",
        getText("UI_null0x686F_QoL_outline_color"),
        def_r, def_g, def_b, def_a,
        getText("UI_null0x686F_QoL_outline_color_tooltip"))
    elseif section == "weapons" then
      local combo = options:addComboBox("QoL_BrokenWeaponBehavior",
        getText("UI_null0x686F_QoL_broken_behavior"),
        getText("UI_null0x686F_QoL_broken_behavior_tooltip"))
      local current = qol_setup.get_broken_weapon_behavior()
      for _, behavior in ipairs(defs.BROKEN_WEAPON_ORDER) do
        combo:addItem(getText(defs.BROKEN_WEAPON_LABEL_KEYS[behavior]), behavior == current)
      end
    end

    if i < #defs.SECTION_ORDER then
      options:addTitle(" ")
    end
  end
end

-- reads the options screen back into the mod's own state.
--
-- CoreLib's PZAPI patch has already flushed each widget into its option table
-- by the time this runs, so the values read here are the live ones. It also
-- means the colour arrives as option.color and needs no probing: the QoL copy
-- of that logic (three pcall-guarded API shapes) was removed as dead.
local function sync(source)
  if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions) then return end

  local opts = PZAPI.ModOptions:getOptions(MOD_ID)
  if not opts then return end

  local summary = {}

  for _, def in ipairs(defs.FEATURE_DEFS) do
    local opt = opts:getOption(def.pzapi_key)
    if opt then
      local value = opt:getValue() and true or false
      qol_setup.set_feature_enabled(def.key, value)
      summary[#summary + 1] = string.format("%s=%s", def.key, tostring(value))
    end
  end

  local opt_color = opts:getOption("ZombieOutline_Color")
  if opt_color and opt_color.color then
    local c = opt_color.color
    qol_setup.update_zombie_outline_custom_color(c.r, c.g, c.b, c.a)
    summary[#summary + 1] = string.format("RGBA=%.2f,%.2f,%.2f,%.2f", c.r, c.g, c.b, c.a)
  end

  local opt_behavior = opts:getOption("QoL_BrokenWeaponBehavior")
  if opt_behavior then
    local behavior = defs.BROKEN_WEAPON_ORDER[opt_behavior:getValue()] or "drop"
    qol_setup.set_broken_weapon_behavior(behavior)
    summary[#summary + 1] = string.format("BrokenWeaponBehavior=%s", behavior)
  end

  log.debug(string.format("sync(%s) -> {%s}", tostring(source or "unknown"), table.concat(summary, ", ")))
end

local function _init_mod_options()
  if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create) then return end

  local options = PZAPI.ModOptions:create(MOD_ID, getText(MOD_NAME_KEY))
  if not options then return end

  _build_options(options)

  -- Options:apply() is PZAPI's extension point -- an empty function in
  -- PZAPI/ModOptions.lua meant to be overridden per mod. Overriding it replaces
  -- the monkeypatch on PZAPI.ModOptions:save that used to live here: CoreLib
  -- already patches save once for the whole suite, and its patch dispatches
  -- apply() on every save path, so a second patch here was duplicating shared
  -- infrastructure.
  --
  -- It fires TWICE per Apply, and that is structural, not a leftover patch:
  -- MainOptions:apply() dispatches it directly (MainOptions.lua:3762) and then
  -- calls PZAPI.ModOptions:save() six lines later, whose CoreLib patch
  -- dispatches it again. sync() is idempotent and the later call sees the
  -- fresher table, so last-write-wins is correct -- the source argument is what
  -- makes the pair legible in the log instead of looking like a bug.
  options.apply = function()
    sync("options:apply")
  end

  -- OnApplyMainMenu/OnApplyInGame (PZAPI's own callbacks) were confirmed via
  -- in-game log never to fire on this build. Don't re-add them without
  -- re-confirming first.
end

local function init()
  if _is_patched then return end

  Events.OnGameBoot.Add(_init_mod_options)
  Events.OnGameStart.Add(function() sync("OnGameStart") end)

  _is_patched = true
end

return {
  init = init,
  sync = sync,
}
