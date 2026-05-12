# Automatic Dreamland — Game Design Document

**Status:** Draft

---

## Elevator Pitch

A classic RPG with auto-battler combat. A dragon attacks your village. Travel town to town, recruit party members, defeat bosses, and prepare for the final assault on the dragon's lair. The battle is won before it starts — strategy lives in prep, not execution.

---

## Core Details

- **Tone:** Earnest, classic. Plays it straight.
- **Engine:** Godot 4.x
- **Perspective:** 2D
- **Structure:** 5-6 towns, linear progression, boss per town, dragon's lair finale

---

## Party & Roster

- **4 active party members** in combat at a time
- **6-8 total recruitable characters** across the journey
- Characters recruited at different towns along the journey
- Bench characters assigned to **stations** (see Bench Station System)

### Class System

9 base classes, each branching into 2 specializations (18 total specs):

| Base Class | Spec A | Spec B |
|------------|--------|--------|
| Warrior | TBD | TBD |
| Mage | TBD | TBD |
| Healer | TBD | TBD |
| Rogue | TBD | TBD |
| Ranger | TBD | TBD |
| Monk | TBD | TBD |
| Robot | TBD | TBD |
| Alien | TBD | TBD |
| Summoner | TBD | TBD |

- Each character starts as a base class and levels into a specialization
- Specialization choice can be **respec'd at towns** for a cost

### Leveling

- On level-up between rounds, player manually assigns stat increases
- Shapes characters toward their role or covers weaknesses
- Reinforces core identity: all meaningful decisions happen outside of combat

---

## Combat (Auto-Battler)

### Pre-Fight Setup

- Choose 4 active party members from roster
- Equip gear and choose ability loadouts
- Set formation (front row / back row — front takes more damage, back is safer)
- Set targeting priority per character (focus weakest, focus strongest, protect healer, etc.)

### During Combat

- Fully automatic — characters act based on loadout, stats, and targeting rules
- **1-2 commander actions** per fight — emergency levers (call retreat, use item, trigger combo)
- Speed/pause controls available for watching

### On Loss

- Game over screen, reload from last town visit
- Progress between towns is the risk — wipe on the road, back to last town
- Encourages smart prep before leaving each town

---

## Bench Station System

Characters not in the active party are assigned to stations. Each station provides a passive buff scaled by the assigned character's power/level.

### Stations (4)

| Station | Buff |
|---------|------|
| **Armory** | Buffs active party's attack/defense stats |
| **Sanctum** | Buffs active party's magic/resistance stats |
| **Watchtower** | Reveals enemy info before fights (types, weaknesses, formation) |
| **Commissary** | Passive HP/MP regen between fights, bonus items/potions |

- One bench character per station
- Buff strength scales with assigned character's power/level
- System designed to expand — more stations and complex interactions possible later

---

## World Structure

### Towns (5-6)

Each town has:

- A **boss** to defeat before moving on
- **1-2 recruitable characters**
- **Shops** (gear, items)
- **Respec option** (change specialization for a cost)
- Serves as **save checkpoint**

### Between Towns

- Road encounters
- Resource gathering
- Story beats

### Finale

- The **dragon's lair** — final dungeon after all towns cleared
- The dragon is the final boss

### Town Progression

| # | Town | Biome | Identity | Boss |
|---|------|-------|----------|------|
| 1 | Starting Village | Plains | Tutorial, fetch quest, dragon destroys it | Tutorial enemies |
| 2 | Forest Town | Woodland | First real hub, rustic hunters/woodcutters | Corrupted forest creature |
| 3 | Mining Town | Mountains | Tough miners, something wrong underground | Mine boss (TBD) |
| 4 | Port City | Coast | Biggest settlement, politics, trade | Sea boss (TBD) |
| 5 | Volcanic Settlement | Ashlands | Dragon's territory, hardened survivors | Dragon's servant (TBD) |
| 6 | Doorstep Camp | Dragon Territory | Last stand camp, final prep | Dragon's gatekeeper (TBD) |
| Final | Dragon's Lair | — | Final dungeon | The Dragon |

### Town 1: Starting Village (Plains)
- Pastoral farming village, your home
- Fetch quest as combat tutorial — learn auto-battler basics
- Return to find the village destroyed by the dragon
- Potentially save someone — first party member recruit
- Leave with nothing. The journey begins.

### Town 2: Forest Town (Woodland)
- Woodcutters, hunters, close enough to see the smoke from your village
- First real shops, respec, and stations
- Rustic, self-sufficient people — wary but willing to help
- 1-2 recruits available
- Boss: corrupted forest creature — warped by the dragon's presence

### Town 3: Mountain Mining Town (Mountains)
- Built into cliffs around a mine
- Tough, hardworking people. Rich in resources but something's gone wrong underground.
- Shops have better gear — mining town means metal and weapons
- 1-2 recruits
- Boss: something from deep in the mine, awakened or corrupted by the dragon

### Town 4: Coastal Port City (Coast)
- Biggest settlement so far. Busy, political, a real city.
- Navy that's useless against a dragon. Trade disrupted.
- Best shops yet — exotic goods from overseas
- 1-2 recruits
- Boss: something from the sea, corrupted or emboldened by the dragon's chaos

### Town 5: Volcanic Settlement (Ashlands)
- In the dragon's territory. Ash in the air, scorched earth.
- People have lived under the dragon's shadow the longest — hardened, fatalistic.
- Gear is endgame quality — forged in volcanic heat
- 1-2 recruits — the toughest people you'll meet
- Boss: a lieutenant or servant of the dragon itself

### Town 6: Dragon's Doorstep Camp (Dragon Territory)
- Makeshift camp of survivors, failed dragon slayers, and desperate allies
- Last chance to prep — final gear, respec, station reassignment
- 1-2 recruits — grizzled veterans who've faced the dragon before
- Boss: the dragon's guardian or gatekeeper
- After this: the dragon's lair

---

## Open Questions

- Character designs and which class each one is
- Specialization details for all 9 base classes
- Specific boss designs for each town
- Stat system (which stats exist, how they interact)
- Gear system depth
- Commander action specifics
- Art style
- How robot and alien classes fit the earnest fantasy tone
- Station expansion plans
- The dragon — identity, phases, lore
- Town names
