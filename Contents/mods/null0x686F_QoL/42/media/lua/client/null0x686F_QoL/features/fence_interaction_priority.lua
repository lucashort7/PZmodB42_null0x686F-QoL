local log = require("null0x686F_QoL/log")
local setup = require("null0x686F_QoL/setup")

local _is_patched = false
local _get_core = getCore

local function _patch_fence_priority()
  if _is_patched then return end

  local original_on_key_press = ISWorldObjectContextMenu.onKeyPress
  if original_on_key_press then
    ISWorldObjectContextMenu.onKeyPress = function(key)
      if not setup.is_feature_enabled("fence_priority") then
        return original_on_key_press(key)
      end
      local player = getSpecificPlayer(0)
      if player and key == getCore():getKey("Interact") then
        local square = player:getCurrentSquare()
        if square and (square:Is(IsoFlagType.collideW) or square:Is(IsoFlagType.collideN) or square:Is(IsoFlagType.HopsW) or square:Is(IsoFlagType.HopsN)) then
          return original_on_key_press(key)
        end
      end
      return original_on_key_press(key)
    end
  end

  _is_patched = true
  log.debug("fence_interaction_priority.lua initialized")
end

return {
  init = _patch_fence_priority
}
