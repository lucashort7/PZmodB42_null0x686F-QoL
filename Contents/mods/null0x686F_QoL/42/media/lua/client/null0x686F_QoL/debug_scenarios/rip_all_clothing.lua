if debugScenarios == nil then
  debugScenarios = {}
end

-- Test rig for null0x686F QoL "Rip All Clothing" (AGGY-0008).
-- Item IDs confirmed against media/scripts/generated/items/clothing.txt and weapon.txt,
-- not just the PZ Wiki item list, since the wiki can drift from the installed build.
-- Originally confirmed on build 42.15, re-confirmed unchanged on 42.20 (2026-07-30).
--
-- Fabric  | Item                        | FabricType | Rip tag confirmed
-- --------|-----------------------------|------------|---------------------------
-- Cotton  | Base.Trousers               | Cotton     | base:ripclothingcotton  (rips by hand, no tool)
-- Denim   | Base.Trousers_Denim         | Denim      | base:ripclothingdenim   (needs Scissors/Sharp Knife)
-- Leather | Base.Trousers_LeatherBlack  | Leather    | base:ripclothingleather (needs Scissors/Sharp Knife)
--
-- Tools   | Base.Scissors     -> Tags include base:scissors
--         | Base.HuntingKnife -> Tags include base:sharpknife
--
-- Right-click any item here to see the "Rip Clothing" submenu (Rip All /
-- Rip Cotton Only / Rip Denim Only / Rip Leather Only). Comment either/both
-- tool lines out to see Denim/Leather Only go notAvailable (reddish) with a
-- tooltip explaining the missing tool, instead of disappearing.

debugScenarios.RipAllClothing = {
  name = "null0x686F Rip All Clothing QA",
  startLoc = { x = 11778, y = 6749, z = 0 }, -- other

  setSandbox = function()
    SandboxVars.Zombies = 6 -- Sandbox_ZombieCount_option6 = "None" (population multiplier 0.0)
  end,

  onStart = function()
    local inv = getPlayer():getInventory()

    -- one item per fabric type
    inv:AddItem("Base.Trousers")               -- Cotton
    inv:AddItem("Base.Trousers_Denim")          -- Denim
    inv:AddItem("Base.Trousers_LeatherBlack")   -- Leather

    -- tools (comment out to test missing-tool behavior)
    inv:AddItem("Base.Scissors")
    inv:AddItem("Base.HuntingKnife")

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
