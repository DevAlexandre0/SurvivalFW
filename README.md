# SurvivalFW

A modular survival framework for FiveM servers (GTA V). SurvivalFW delivers survival mechanics, inventory and trading, medical depth, environmental effects, wildlife spawning, and a lightweight NUI shell. Version **1.3.1** consolidates the project into a single `sfw` resource with both client and server logic.

---

## 📁 Repository Layout

- resources/
- └─ sfw/
- ├─ client/ -- client-side Lua scripts
- ├─ server/ -- server-side Lua scripts
- ├─ shared/ -- configuration + utility modules
- ├─ nui/sfw_shell/ -- minimal HTML/CSS/JS UI shell
- └─ fxmanifest.lua
- spec/ -- Busted unit tests
- sql/ -- database migration files

---

## ✨ Features

- **Identity & Appearance** – First‑time player registration with citizen ID and hair customization.
- **Inventory System** – Slot-based containers, weight limits, stack merging, rate‑limited moves.
- **Medical Depth** – Bleeding, fractures, painkillers, morphine, splints, with persistent health values.
- **Trading & Crafting** – Dynamic pricing, scarcity modifiers, recipe-based crafting benches.
- **Environment & Wildlife** – Insulation, temperature ticks, biome-based wildlife rules, radial interactions.
- **Stashes & Radial Interaction** – World stashes, vehicle context actions, quick craft options.
- **Admin & Metrics** – Commands for wildlife rule refresh, med flush, metrics tracking.
- **NUI Shell** – Minimal HUD and panel interface served from `nui/sfw_shell`.

---

## 📦 Installation

1. **Prerequisites**
   - FiveM server (cerulean build, Lua 5.4).
   - [`oxmysql`](https://github.com/overextended/oxmysql) resource.
   - Standard `spawnmanager` resource.

2. **Deploy the Resource**
   ```cfg
   ensure oxmysql
   ensure spawnmanager
   ensure sfw
Database Setup

Apply migrations in sql/ to create/update tables for players, inventory, trading, crafting, etc.

Configuration

Edit shared/10_config.lua to tweak clothing stats, items, crafting recipes, interaction zones, wildlife species, etc.

Customize HTML/CSS/JS assets under nui/sfw_shell if desired.

🕹️ Usage
# Player Join Flow
- Identity registration → hair/appearance setup → spawn.

# Inventory & Crafting
- Commands or contextual zones trigger NUI panels (fw_trader, fw_stash, fw_craft).
- Radial menu (fw_radial, default key E) builds context-specific actions.

# Medical
- Commands: splint, morphine, painkiller (ACL restricted).
- Bleeding and injuries handled server-side.

# Admin/Debug
- medflush (console) saves all cached health.
- wildrules refreshes wildlife rules.
- Metrics exposed via FW.Metrics.SetG.

🛠️ Development
Tests: spec/ contains Busted unit tests (Lua 5.4).

Style: .luacheckrc enforces Lua code style.

Exports: Provides helper functions (SFW_PlayerContainerId, SFW_FetchStacks, SFW_TraderPayload, etc.) for cross-resource integration.

📜 License & Contribution
Author: SFW Team

Version: 1.3.1

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

Contributions should follow existing module structure and Lua coding conventions. Use built-in rate limiting (FW.RL.Check) for networked operations and maintain database contracts for new tables or queries.
