# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/compare/v0.3.1...v0.4.0) (2026-08-03)


### Features

* **i18n:** move every player-visible string into Translate/EN ([#23](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/23)) ([c0ec09f](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/c0ec09fff21b1faf1bf61e6a04e480ede7e98654))
* added .gitignore for lua files + .claude/ ([91909dd](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/91909dd0b6947b93791fcf546f4915e2fc917bbb))

### Bug Fixes

* **qol:** [AGGY-0013] stop OnBreak patch from re-entering itself on every break ([9ed2f10](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/9ed2f1045bb2b1fb79308ac4056b8aabfd68038b))
* derive the feature count, and clear the last pre-rebrand residue ([#20](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/20)) ([557655f](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/557655f8a85b18264a26cb7172f2368321c11a83))
* **auto_unset_alarms:** hook visibility, not right-click ([#22](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/22)) ([dda78c5](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/dda78c507d316ad230ff893d111e578edaf31371))
* **auto_unset_alarms:** skip the player's own inventory pane ([#24](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/24)) ([e827e12](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/e827e124b0d71d938fe33420b38774c621c8ad5b))

### Code Refactoring

* **log:** drop the filename argument from newFileLogger ([#19](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/19)) ([6d5ecdd](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/6d5ecdd35724bbd4c20d6d55c25fbf49bc23fa38))
* **modoptions:** split five responsibilities, drop the duplicate patch ([#21](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/21)) ([373ce18](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/373ce18c6d2e5dcb7179cab038708f8677d454e9))

### Continuous Integration

* add luacheck gate ([#18](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/issues/18)) ([197c7bf](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/197c7bf0511446a7da94ad1cf4ba958df688fcce))

### Miscellaneous Chores

* remove per-repo sync_to_workshop.ps1, superseded by suite/scripts ([fc6a764](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/fc6a764d706e186b8a9a44e60ba3b252d91912eb))
* **qol:** [AGGY-0014] remove dry_towel_hotkey, gas_siphon_walk and fence_interaction_priority ([00d0bf8](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/00d0bf829557e8e749c54181c0f95d93e3542271))
* **qol:** [AGGY-0013] add full-flow trace logging to auto_equip_broken_weapon ([13603a7](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/13603a7c41554c012ba9f4d6bfa4ac2faaa29bb7))
* **qol:** [AGGY-0013] probe OnBreak helpers and harden _in_break ([002d6e7](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/002d6e7e4f51fa4172e17e2a3b14535b4e3be153))
* **qol:** [AGGY-0013] drop helper probe scaffolding after in-game confirmation ([ec8ff0f](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/ec8ff0fcefd5b15d62a0537728fbba5f72c93f46))

## [0.3.1](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/compare/v0.3.0...v0.3.1) (2026-07-31)


### Bug Fixes

* move "all features loaded" log inside the OnCreatePlayer loop ([d6741ee](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/d6741eeb15bac9bd3e1f7d6e44c8bfb704e16e3e))
* remove OnApplyMainMenu/OnApplyInGame dead callbacks ([c9a84d0](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/c9a84d09ccb4814b1e4fcebb18c246401662f855))

## [0.3.0](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/compare/v0.2.0...v0.3.0) (2026-07-30)


### Features

* **qol:** [AGGY-0007] add worn items hide/show context menu toggle ([3aae2eb](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/3aae2ebb0ab085f39661cf3215e31f5dd8fd234f))

## [0.2.0](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/compare/v0.1.0...v0.2.0) (2026-07-29)


### Features

* migrate to release-please + reusable Steam Workshop deploy ([1857c77](https://github.com/lucashort7/PZmodB42_null0x686F-QoL/commit/1857c7720cd18edb77a69f0cb8e883bbaf351f59))

## [0.1.0] - 2026-07-27

### Added
- Rip All Clothing, tool-gated batch clothing rip.
- Dismantle All Electronics, driven by vanilla CraftRecipe/HandcraftLogic.
- Zombie Outline, Inventory Title, Gas Siphon Walk, Fence Interaction Priority, Worn Items Toggle, Auto Equip Broken Weapon, Walk & Equip, Auto Unset Alarms.
