local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _get_core = getCore

local function _patch_wear_clothing()
  if ISWearClothing and not ISWearClothing.__HORT_PATCHED then
    ISWearClothing.__HORT_PATCHED = true
    local _old_new = ISWearClothing.new
    function ISWearClothing:new(character, item)
      local o = _old_new(self, character, item)
      if setup.is_feature_enabled("walk_and_equip") then
        o.stopOnWalk = false
        o.stopOnAim = false
      end
      return o
    end
  end
end

local function _patch_clothing_extra()
  if ISClothingExtraAction and not ISClothingExtraAction.__HORT_PATCHED then
    ISClothingExtraAction.__HORT_PATCHED = true
    local _old_new = ISClothingExtraAction.new
    function ISClothingExtraAction:new(character, item, extra)
      local o = _old_new(self, character, item, extra)
      if setup.is_feature_enabled("walk_and_equip") then
        o.stopOnWalk = false
        o.stopOnAim = false
      end
      return o
    end
  end
end

local function _init_walk_and_equip()
  if _is_patched then return end
  _patch_wear_clothing()
  _patch_clothing_extra()
  _is_patched = true
  log.debug("walk_and_equip.lua initialized")
end

Events.OnGameStart.Add(_init_walk_and_equip)
if _get_core() then _init_walk_and_equip() end

return {
  init = _init_walk_and_equip
}
