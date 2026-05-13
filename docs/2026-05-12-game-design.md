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

### Narrative Structure

The protagonist doesn't realize they're on a revenge quest. They think they're just surviving and helping people. Town by town they dismantle the dragon's network without seeing the pattern. The realization hits around Town 4 — the dragon knows their name now.

**Early game:** You're a nobody. The dragon doesn't know you exist.
**Mid game:** Lieutenants start falling. The dragon learns your name.
**Late game:** The dragon is actively hunting you. The power dynamic flips.

The dragon destroyed your village not out of malice but indifference. You were in the way. The revenge is born from insignificance.

### Town Arc Template

Each town follows the same escalation:

1. **Arrive, meet locals, help out** — quests, visit nearby villages, recruit characters
2. **Low-level goons** — your help attracts attention from the lieutenant's enforcers
3. **Mid-level mook** — enforcers report back, someone tougher shows up
4. **Mook defeated** — the lieutenant's grip on the town crumbles
5. **Lieutenant flees** — retreats to the dragon's castle. Drops items, story clues, or frees prisoners in their haste
6. **Town liberated**

You never fight the lieutenants at their towns. They are the dragon's ruling class — out of touch, above getting their hands dirty. You fight their enforcers and dismantle their power structure. The lieutenants themselves are faced for the first time at the dragon's castle, in their true monstrous forms.

### The Dragon's Ruling Class

All lieutenants present as humanoid — governors, bosses, guild masters. Each is a monster in disguise. Their true forms are revealed only at the final castle battle.

### Town Progression

| # | Town | Biome | Lieutenant (Humanoid) | Lieutenant True Form | Enforcer Boss |
|---|------|-------|-----------------------|---------------------|---------------|
| 1 | Starting Village | Plains | — (dragon attacks directly) | — | Tutorial enemies |
| 2 | Lumber Camp | Woodland | Corpo tyrant / false benefactor | Parasitic creature (pathetic but dangerous) | Leader of goons (TBD) |
| 3 | Mining Town | Mountains | Mine owner | Burrower/hoarder (greedy dragon echo) | Pinkerton leader (true believer) |
| 4 | Port City | Coast | Governor/merchant prince | Deep one / octopus creature | Admiral (corrupt war hero, loyal to the system) |
| 5 | Volcanic Settlement | Ashlands | High priest of dragon cult | Perverted angel — biblically accurate, mixed with beast | Grand inquisitor (servant's grandchild, proving loyalty) |
| 6 | Dragon's Castle | Dragon Territory | — | — | All lieutenants in true form |

### Town 1: Starting Village (Plains)
- Pastoral farming village, your home
- Fetch quest as combat tutorial — learn auto-battler basics
- Return to find the village destroyed by the dragon
- The dragon didn't target you specifically — you were nothing
- Potentially save someone — first party member recruit
- Leave with nothing. The journey begins.

### Town 2: Lumber Camp (Woodland)
- Large lumber site / work camp, not a proper town
- Lieutenant is a corpo tyrant who uses false benefactor angle — "I'm providing jobs" — because actual guards cost more than manipulation
- Workers are technically "free to leave" but have nowhere to go
- Sympathetic NPC: leader of the workers
- Enforcer boss: leader of the lieutenant's goons
- Lieutenant flees when power structure crumbles
- Lieutenant's true form: parasitic creature — feeds off labor/exhaustion. Pathetic but dangerous.

### Town 3: Mountain Mining Town (Mountains)
- Built into cliffs around a mine
- Lieutenant is the mine owner — sits in mansion above while workers dig deeper
- Enforced by a thinly veiled Pinkerton group
- Enforcer boss: Pinkerton leader — a true believer who genuinely thinks miners are ungrateful troublemakers. Sleeps well at night.
- Lieutenant flees when Pinkertons are defeated
- Lieutenant's true form: burrower/hoarder — digs and collects obsessively. A smaller, greedier echo of the dragon.

### Town 4: Coastal Port City (Coast)
- Biggest settlement. Busy, political.
- Lieutenant is the governor/merchant prince — wealth and political power are the same thing
- Navy exists to protect trade routes for the governor, not fight the dragon
- Enforcer boss: the admiral — a war hero gone corrupt. Genuinely believes they're preserving order and decency. Loyalty to the power structure IS the corruption, even if they think they're good.
- This is roughly where the protagonist realizes the pattern — the dragon knows their name
- Lieutenant flees when admiral is defeated
- Lieutenant's true form: deep one / octopus creature — tentacles, the sea, control.

### Town 5: Volcanic Settlement (Ashlands)
- In the dragon's territory. Ash in the air.
- **Different from other towns:** the citizens LOVE the dragon. They live gilded lives. Wealthy, comfortable, taken care of. The servants — the underclass — are the ones suffering.
- Lieutenant is a high priest running a dragon cult preaching prosperity (and it's true — for the citizens)
- Liberating this town is complicated — you're disrupting a comfortable lie. Citizens may hate you for it.
- Enforcer boss: the grand inquisitor — grandchild of a servant who clawed their way up by being the most ruthless enforcer. The fervor isn't faith, it's fear of falling back down.
- Lieutenant's true form: perverted angel — biblically accurate angel mixed with bull or owl. Too many eyes, too many wings, twisted with something bestial. A false divinity.

### Town 6: The Dragon's Castle

Not a town — the dragon's castle itself. The endgame.

- Greeted at the door by a butler. Polite. Terrifying.
- Explore the castle, story beats, lore
- Reach the great hall — all lieutenants waiting in true monstrous forms
- **The dragon sits on his throne in the form of a handsome wealthy man and watches.** He's so far above you he doesn't stand up.
- Defeat all lieutenants in their true forms at full power
- **The dragon's confidence cracks.** He flees to the heart of the castle — his hoard.
- The chase: he transforms in stages as he runs. Scales breaking through skin, wings tearing his coat, knocking over his own furniture. Composed man falling apart.
- **Final battle on top of his stolen wealth.** Full dragon form. Every coin is something taken from someone. You're standing on the wreckage of the world he built.

### The Dragon

- Presents as a handsome, wealthy, composed man on a throne
- True form: full dragon — revealed in stages during the chase through his castle
- Power is performance — you stripped it away town by town, lieutenant by lieutenant
- Destroyed your village out of indifference, not malice
- Only learns your name when his lieutenants start falling
- The final battle is a scared animal fighting on top of a pile of stolen things

---

## Open Questions

- Character designs and which class each one is
- Specialization details for all 9 base classes
- Town 2 enforcer boss specifics
- Stat system (which stats exist, how they interact)
- Gear system depth
- Commander action specifics
- Art style
- How robot and alien classes fit the earnest fantasy tone
- Station expansion plans
- Small villages between towns (quest destinations, character hometowns)
- Town names
- The butler — who/what are they?
- Dragon's castle level design
- Nearby villages and side quest structure
