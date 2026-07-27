# null0x686F QoL

![Project Zomboid](https://img.shields.io/badge/Project%20Zomboid-B42-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Performance](https://img.shields.io/badge/Performance-O(1)-brightgreen)

Quality of Life suite for Project Zomboid Build 42, built from scratch with performance in mind. No `OnTick` loops, no FPS drops.

## Requires
- **null0x686F CoreLib** (hard dependency).

## Features
- **Rip All Clothing** — batch-rip eligible clothing, tool-gated by fabric type.
- **Dismantle All Electronics** — batch-dismantle eligible electronics, driven by the game's own craft recipes (inherits correct animation/XP/bonus items automatically).
- **Zombie Outline** — customizable outline color for targeted zombies.
- **Inventory Title** — inventory header shows `[Player Name]'s Inventory`.
- **Gas Siphon Walk** — refuel/siphon while walking/aiming without cancelling.
- **Fence Interaction Priority** — prioritizes vaulting fences over ground item interactions.
- **Worn Items Toggle** — hides equipped clothes, keeps backpack/keyring visible.
- **Auto Equip Broken Weapon** — re-equips a same-type replacement when your weapon breaks.
- **Walk & Equip** — equip/adjust clothing while walking or aiming.
- **Auto Unset Alarms** — turns off looted alarm clocks/watches automatically.

## Installation (Manual)
1. Download the latest `.zip` from [Releases](../../releases).
2. Extract the `null0x686F_QoL` folder into `C:\Users\YOUR_USER\Zomboid\mods\`.
3. Install **null0x686F CoreLib** too.
4. Enable both mods in the main menu.

## Configuration
Supports **ModOptions** (optional, soft-dependency) for a dedicated in-game settings tab.
