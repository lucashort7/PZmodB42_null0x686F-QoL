if debugScenarios == nil then
  debugScenarios = {}
end

-- Test rig for null0x686F QoL "Dismantle All Electronics" (AGGY-0010), driven
-- by vanilla's own CraftRecipe/HandcraftLogic system instead of a hand-rolled
-- TimedAction. Spawns one item per underlying vanilla dismantle recipe so all
-- 3 can be exercised in a single QA pass:
--
-- Recipe                      | Item                      | Eligibility source
-- ----------------------------|----------------------------|---------------------------------------------
-- DismantleElectronics        | Base.Camera                | confirmed base:camera tag (script)
-- DismantleElectronics        | Base.FlashLight_AngleHead  | Java-computed base:flashlight, confirm in-game
-- DismantleMiscElectronics    | Base.Speaker                | fullType whitelist, bonus output Amplifier
-- DismantleElectronicsDevice  | Base.WalkieTalkie1          | fullType whitelist (confirmed in recipes_radio.txt)
--
-- Tool | Base.Screwdriver -> Tags include base:screwdriver (Java-computed),
--        kept (not consumed) by all 3 recipes
--
-- Right-click any item here to see "Dismantle All Electronics". Comment out
-- the tool line to see it go notAvailable (reddish) with a tooltip
-- explaining the missing tool, instead of disappearing.
--
-- Also worth a manual check while here: favorite an item before dismantling
-- -- unconfirmed whether vanilla's HandcraftLogic/CraftRecipe path respects
-- favorite-item protection the way the old hand-rolled action did.

debugScenarios.DismantleAllElectronics = {
  name = "null0x686F Dismantle All Electronics QA",
  startLoc = { x = 11778, y = 6749, z = 0 }, -- other

  setSandbox = function()
    SandboxVars.Zombies = 6 -- Sandbox_ZombieCount_option6 = "None" (population multiplier 0.0)
  end,

  onStart = function()
    local inv = getPlayer():getInventory()

    -- DismantleElectronics (tag-based)
    inv:AddItem("Base.Camera")
    inv:AddItem("Base.FlashLight_AngleHead")

    -- DismantleMiscElectronics (fullType whitelist, has a bonus output)
    inv:AddItem("Base.Speaker")

    -- DismantleElectronicsDevice (fullType whitelist)
    inv:AddItem("Base.WalkieTalkie1")

    -- tool (comment out to test missing-tool behavior)
    inv:AddItem("Base.Screwdriver")

    -- clean weather (pattern from Trailer3Scenario.lua)
    local clim = getClimateManager()
    local w = clim:getWeatherPeriod()
    if w:isRunning() then
      clim:stopWeatherAndThunder()
    end

    -- remove fog
    local var = clim:getClimateFloat(5)
    var:setEnableOverride(true)
    var:setOverride(0, 1)
  end
}
