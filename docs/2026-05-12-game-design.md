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

---

## Open Questions

- Specific town themes and boss identities
- Character designs and which class each one is
- Specialization details for all 9 base classes
- Stat system (which stats exist, how they interact)
- Gear system depth
- Commander action specifics
- Art style
- How robot and alien classes fit the earnest fantasy tone
- Station expansion plans
- Story details beyond "dragon attacks village"
