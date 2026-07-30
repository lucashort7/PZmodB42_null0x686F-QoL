require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISTickBox")
require("ISUI/ISButton")

local setup = require("null0x686F_QoL/setup")
local log = require("null0x686F_QoL/log")

local _pairs = pairs
local _ipairs = ipairs
local _tostring = tostring
local _string_format = string.format

QoLOptionsTabUI = ISPanel:derive("QoLOptionsTabUI")

local _features_def = {
  { id = "inv_name", label = "Custom Player Name in Inventory Title", default = true },
  { id = "hide_worn", label = "Hide Worn Clothes in Inventory Pane", default = true },
  { id = "vehicle_gas", label = "Allow Gas Siphoning While Walking/Aiming", default = true },
  { id = "auto_unset_alarms", label = "Auto-Unset Alarms on Looted Watches", default = true },
  { id = "fence_priority", label = "Prioritize Hop Fence Context Action", default = true },
  { id = "quick_context", label = "Quick Context Action: Rip All Clothing", default = true },
  { id = "zombie_outline", label = "Custom Zombie Target Outline Highlight", default = true },
}

function QoLOptionsTabUI:initialise()
  ISPanel.initialise(self)

  local font = (UIFont and UIFont.Small) and UIFont.Small or 0

  self.title_lbl = ISLabel:new(12, 10, 20, "null0x686F QoL V2 - Live Feature Control", 1, 1, 1, 1, font, true)
  self:addChild(self.title_lbl)

  self.tickbox = ISTickBox:new(12, 35, self.width - 24, #_features_def * 26, "", self, self.on_tick_toggled)
  self.tickbox:initialise()
  self:addChild(self.tickbox)

  self:populate_toggles()
end

function QoLOptionsTabUI:populate_toggles()
  self.tickbox.options = {}
  self.tickbox.optionData = {}
  self.tickbox.selected = {}
  self.tickbox.disabledOptions = {}
  self.tickbox.optionsIndex = {}
  self.tickbox.textures = {}
  self.tickbox.optionCount = 1

  for i, feat in _ipairs(_features_def) do
    local is_enabled = setup.is_feature_enabled(feat.id)
    local idx = self.tickbox:addOption(feat.label, feat.id)
    self.tickbox:setSelected(idx, is_enabled)
  end
end

function QoLOptionsTabUI:on_tick_toggled(index, selected)
  local feat_id = self.tickbox:getOptionData(index)
  if not feat_id then return end

  -- 1. Update setup.lua memory cache in O(1)
  setup.set_feature_enabled(feat_id, selected)

  -- 2. Bidirectional Sync with PZAPI.ModOptions (.ini persistence)
  if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
    local opts = PZAPI.ModOptions:getOptions("null0x686F_QoL")
    if opts then
      local opt = opts:getOption(feat_id)
      if opt and opt.setValue then
        opt:setValue(selected)
      end
    end
  end

  log.debug(_string_format("QoL Tab Sync -> %s set to %s", feat_id, _tostring(selected)))
end

function QoLOptionsTabUI:new(x, y, width, height)
  local o = ISPanel:new(x, y, width, height)
  setmetatable(o, self)
  self.__index = self
  o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.85 }
  o.borderColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }
  return o
end

local tab_registry = require("null0x686F_CoreLib/debug_panel/tab_registry")

local function _register_qol_tab()
  tab_registry.registerTab("QoL Options", QoLOptionsTabUI, "NULL0X686F")
end

Events.OnGameStart.Add(_register_qol_tab)

return QoLOptionsTabUI
