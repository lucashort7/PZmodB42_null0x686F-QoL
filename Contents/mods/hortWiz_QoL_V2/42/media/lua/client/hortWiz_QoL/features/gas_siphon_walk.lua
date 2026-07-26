local log = require("hortWiz_QoL/log")
local setup = require("hortWiz_QoL/setup")

local _is_patched = false
local _tostring = tostring
local _get_core = getCore

local function _can_add(container, who, item)
  return container and container.hasRoomFor and container:hasRoomFor(who, item)
end

local function _patch_gasoline()
  if _is_patched then return end
  local patched_count = 0

  if ISRefuelFromGasPump and not ISRefuelFromGasPump.__HORT_PATCHED then
    ISRefuelFromGasPump.__HORT_PATCHED = true
    local _old_new = ISRefuelFromGasPump.new
    function ISRefuelFromGasPump:new(character, part, fuelStation)
      local o = _old_new(self, character, part, fuelStation)
      if setup.is_feature_enabled("vehicle_gas") then
        o.stopOnAim = false
      end
      return o
    end
    patched_count = patched_count + 1
  end

  if ISTakeGasolineFromVehicle and not ISTakeGasolineFromVehicle.__HORT_PATCHED then
    ISTakeGasolineFromVehicle.__HORT_PATCHED = true
    local _old_new = ISTakeGasolineFromVehicle.new
    function ISTakeGasolineFromVehicle:new(character, part, item, otherItems)
      local o = _old_new(self, character, part, item, otherItems)
      if setup.is_feature_enabled("vehicle_gas") then
        o.stopOnAim = false
        o._origPrimary = character:getPrimaryHandItem()
        o._origSecondary = character:getSecondaryHandItem()
        if o.item then o._itemOrigin = o.item:getContainer() end

        local inv = character:getInventory()
        local hose = nil
        if inv and inv.getFirstTagRecurse then
          if ItemTag and ItemTag.SIPHON_GAS then
            hose = inv:getFirstTagRecurse(ItemTag.SIPHON_GAS)
          else
            hose = inv:getFirstTagRecurse("SiphonGas")
          end
        end

        if hose then
          o._hoseItem = hose
          o._hoseOrigin = hose:getContainer()
        end

        if o._hoseOrigin and o._hoseOrigin ~= inv then
          o._hoseReturnTarget = o._hoseOrigin
        elseif o._itemOrigin and o._itemOrigin ~= inv then
          o._hoseReturnTarget = o._itemOrigin
        else
          o._hoseReturnTarget = nil
        end
      end
      return o
    end

    local _old_perform = ISTakeGasolineFromVehicle.perform
    function ISTakeGasolineFromVehicle:perform()
      if not setup.is_feature_enabled("vehicle_gas") then
        return _old_perform(self)
      end

      local next_item = self:nextItem()
      if next_item then
        return _old_perform(self)
      end

      local player = self.character
      local inv = player and player:getInventory() or nil
      local hose = self._hoseItem

      if hose then
        if player:getPrimaryHandItem() == hose or player:getSecondaryHandItem() == hose then
          ISTimedActionQueue.add(ISUnequipAction:new(player, hose, 10))
        end
        if self._hoseOrigin and self._hoseReturnTarget and self._hoseOrigin ~= self._hoseReturnTarget then
          ISTimedActionQueue.add(ISInventoryTransferAction:new(player, hose, self._hoseOrigin, self._hoseReturnTarget))
        end
      end

      if self._origPrimary or self._origSecondary then
        if self._origPrimary and self._origSecondary and self._origPrimary == self._origSecondary then
          ISTimedActionQueue.add(ISEquipWeaponAction:new(player, self._origPrimary, 50, true, true))
        else
          if self._origPrimary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(player, self._origPrimary, 50, true, false))
          end
          if self._origSecondary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(player, self._origSecondary, 50, false, false))
          end
        end
      end

      if self.item and self._itemOrigin and self._itemOrigin ~= inv then
        if _can_add(self._itemOrigin, player, self.item) then
          ISTimedActionQueue.add(ISInventoryTransferAction:new(player, self.item, self.item:getContainer(), self._itemOrigin))
        end
      end

      _old_perform(self)
    end
    patched_count = patched_count + 1
  end

  if ISAddGasolineToVehicle and not ISAddGasolineToVehicle.__HORT_PATCHED then
    ISAddGasolineToVehicle.__HORT_PATCHED = true
    local _old_new = ISAddGasolineToVehicle.new
    function ISAddGasolineToVehicle:new(character, part, item, otherItems)
      local o = _old_new(self, character, part, item, otherItems)
      if setup.is_feature_enabled("vehicle_gas") then
        o.stopOnAim = false
        o._origPrimary = character:getPrimaryHandItem()
        o._origSecondary = character:getSecondaryHandItem()
        if o.item then o._itemOrigin = o.item:getContainer() end
      end
      return o
    end

    local _old_perform = ISAddGasolineToVehicle.perform
    function ISAddGasolineToVehicle:perform()
      if not setup.is_feature_enabled("vehicle_gas") then
        return _old_perform(self)
      end

      local next_item = self:nextItem()
      if next_item then
        return _old_perform(self)
      end

      if self.item and self._itemOrigin then
        local cur_cont = self.item:getContainer()
        if cur_cont and cur_cont ~= self._itemOrigin then
          ISTimedActionQueue.addAfter(self, ISInventoryTransferAction:new(self.character, self.item, cur_cont, self._itemOrigin))
        end
      end

      if self._origPrimary or self._origSecondary then
        if self._origPrimary and self._origSecondary and self._origPrimary == self._origSecondary then
          ISTimedActionQueue.addAfter(self, ISEquipWeaponAction:new(self.character, self._origPrimary, 50, true, true))
        else
          if self._origSecondary then
            ISTimedActionQueue.addAfter(self, ISEquipWeaponAction:new(self.character, self._origSecondary, 50, false, false))
          end
          if self._origPrimary then
            ISTimedActionQueue.addAfter(self, ISEquipWeaponAction:new(self.character, self._origPrimary, 50, true, false))
          end
        end
      end

      _old_perform(self)
    end
    patched_count = patched_count + 1
  end

  _is_patched = true
  log.debug("gas_siphon_walk.lua initialized with " .. _tostring(patched_count) .. " patches")
end

Events.OnGameStart.Add(_patch_gasoline)
if _get_core() then _patch_gasoline() end

return {
  init = _patch_gasoline
}
