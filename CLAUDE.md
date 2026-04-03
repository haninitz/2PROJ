# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Installer SFML via vcpkg (une seule fois)
vcpkg install sfml

# Compiler
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[chemin_vcpkg]/scripts/buildsystems/vcpkg.cmake
cmake --build build

# Lancer
./build/Debug/SupKontQuest.exe
```

Pour utiliser SFML sans vcpkg : télécharger SFML 2.5.x sur sfml-dev.org, extraire dans `C:/SFML-2.5.1`, décommenter `set(SFML_DIR ...)` dans `CMakeLists.txt`.

## Project Overview

**SupKontQuest** is a Risk/Warcraft III-inspired online strategy game. Players control camps on a map, produce units, manage an economy, and conquer territory. Supports 2–8 players (human or AI), online multiplayer, and 3 AI difficulty levels. Due: **May 31, 2026** (Group Paris-4).

Technology stack is not yet decided — any language or engine (Unity, Unreal, custom) is acceptable. Target platform: executable or web browser.

## Core Requirements

- **Maps:** 3+ different maps with camps, terrain obstacles, and water zones
- **Economy:** Income generated from owned camps; used to produce units
- **Units:** Infantry, Support, Range, Heavy, Anti-Armor, Motor (land); Transport, Frigate, Destroyer (sea)
- **Multiplayer:** Online matchmaking, 2–8 players
- **AI:** 3 difficulty levels
- **Internationalization:** At least 3 languages
- **Leaderboard:** Online ranking system

**Bonus features (up to 75 pts):** Isometric 3D rendering, in-game map editor, advanced social features (friends, messaging, profile customization).

## Architecture (UML Class Diagram — `SupKont-2026-03-13-090713.png`)

The class diagram defines the following major subsystems:

### Core Game Loop
- **Game** — central controller; owns the map, players, and game state
- **Map** — contains camps (bases), terrain, water zones, and unit positions
- **Player** — human or AI; owns camps, units, and economy resources

### Economy
- **Economy / Resource** — tracks income per turn from owned camps; manages spending on unit production

### Combat
- **Combat / CombatZone** — resolves battles when units contest a camp or territory
- **Military / Army** — groups of units assigned to a player or camp

### Units
- **UnitGroup / Armement** — collection of units acting together
- **Status** — unit state (health, movement points, orders)
- Land units: Infantry, Support, Range, Heavy, Anti-Armor, Motor
- Sea units: Transport, Frigate, Destroyer

### Movement & Pathfinding
- **Movement** — handles unit displacement across the map
- **Pathfinding** — computes routes respecting terrain and water obstacles

### Multiplayer / Online
- **Session / MatchMaking** — handles lobbies, player connections, and game sync

### AI
- Pluggable AI controller attached to Player; 3 difficulty variants

## Grading Weights (575 points max)

| Category       | Points |
|---------------|--------|
| Features       | 200    |
| Code quality   | 200    |
| Documentation  | 100    |
| Bonus          | 75     |

Code quality criteria: efficiency, maintainability, structure, OOP principles — prioritize clean object-oriented design following the UML diagram.
