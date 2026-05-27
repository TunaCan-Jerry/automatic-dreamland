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

## Core Theme

**Our attachments and relationships with each other make us stronger.** Every recruit comes as a bonded pair — combat partner + support partner. Lovers, spouses, best friends, family. The party grows town by town, and more relationships = more power, both narratively and mechanically.

## Party & Roster

### Bonded Pairs

Every recruitment is a pair: one **combat character** (fights on the battlefield) and one **support character** (runs a station from the bench). Each pair is bonded — their relationship is why they both join.

- **6 bonded pairs = 12 characters total** (6 combat, 6 support)
- **All combat characters fight every battle** — no party cap. Your army grows as you recruit.
- **Support characters run stations** — each has a unique station shaped by their class/identity, effectiveness scales with their stats.
- Early game: 1-2 combat characters, scrappy fights. Endgame: 6 on the field, full squad.

### Recruitment

Characters are recruited at major towns and nearby villages:
- Some join immediately when asked
- Some decline at first — a side quest/cutscene at their home village triggers them joining
- Each recruitment is a story moment, not a menu prompt

### Class System

Each character — combat and support — has a **unique base class** that branches into 2 specializations via their skill tree. No two characters start the same.

12 characters = 12 base classes = 24 total specs.

**Combat Characters:**

| # | Town | Character | Base Class | Spec A | Spec B |
|---|------|-----------|------------|--------|--------|
| 1 | Starting Village | Protagonist | Leader (tanks + buffs) | TBD | TBD |
| 2 | Lumber Camp | Huntmaster | Ranger | Rogue | Beastmaster |
| 3 | Mining Town | Demo expert | Engineer | Demolitionist | Mechanist |
| 4 | Port City | Sailor | Gunner | Cannoneer | Pistoleer |
| 5 | Volcanic Settlement | TBD | TBD | TBD | TBD |
| 6 | Dragon's Castle | TBD | TBD | TBD | TBD |

**Support Characters:**

| # | Town | Character | Base Class | Spec A | Spec B | Bonded To |
|---|------|-----------|------------|--------|--------|-----------|
| 1 | Starting Village | Claira (love interest) | Healer | TBD | TBD | Protagonist |
| 2 | Lumber Camp | Carpenter | Axman | Warrior | Craftsman | Huntmaster |
| 3 | Mining Town | TBD | TBD | TBD | TBD | Demo expert |
| 4 | Port City | Angler | Angler | Provisioner | Navigator | Sailor |
| 5 | Volcanic Settlement | TBD | TBD | TBD | TBD | TBD |
| 6 | Dragon's Castle | TBD | TBD | TBD | TBD | TBD |

### The Protagonist — Leader

The protagonist's power is charisma — not slimy, genuine. People follow them because they care and are willing to help. They take the hard work, they take the danger, they never ask anyone to do anything they wouldn't do.

- Fights on the battlefield as a frontline tank/buffer
- Also provides the 1-2 commander actions per fight
- Leads from the front — passive aura makes everyone fight harder around them
- Their "class" is organizing people and instilling solidarity

### Combat vs. Narrative Death

Deaths in combat are mechanical — everyone heals up and revives after each round. Losing a fight = game over, reload from last town. Narrative deaths only happen in cutscenes and are permanent story beats.

### Claira — Healer (ref: Clara Barton)

Childhood friend and love interest. Fiery, stubborn, opinionated. She's not following you — she's coming with you because she decided to. Keeps you alive while telling you you're being an idiot.

- **Grandmother:** The village elder. A retired adventurer who became the village healer. Taught Claira the trade — herbs, medicine, practical skills.
- **Before the attack:** Apprentice healer, trained by her grandmother. Grew up hearing stories about grandma's younger days. Knew the old woman had an interesting past but never thought it would matter.
- **The attack:** Her grandmother uses the last of her adventuring magic to shield Claira. The barrier is fading when the protagonist arrives — a few minutes later and she'd have burned too. Claira survives because of her grandmother's sacrifice and the protagonist's timing. She carries that weight the whole game.
- **Personality:** Loyal but opinionated. Argues because she cares. Not a passive healer — active, fierce, present. The fire to the protagonist's warmth.
- **Role:** Support character, runs a station from the bench. Her bond with the protagonist is the emotional core of the story.

### The Elder (Claira's Grandmother)

Retired adventurer who became the village healer. She had an interesting past — adventured when she was young, settled down, built a quiet life. Practical, wise, not sentimental about the old days.

- Sends the protagonist on the fetch quest: deliver something to a nearby homestead, bring back a trinket.
- The trinket is hers — a relic from her adventuring days. Gives passive buffs, can invest points for more effects. Transforms into something significant halfway through Act 2 (details TBD).
- Dies in the dragon attack — spends her last magic shielding Claira. Her final act was protecting her granddaughter.
- The trinket becomes the protagonist's by default — there's no one left to give it to.
- Had real magic from her adventuring days, kept it quiet. The village knew her as a healer, not a mage.

### The Protagonist's Trinket

A mysterious item from the elder's adventuring past. Carried as a memento at first.

- Provides passive buffs from the start
- Invest points to unlock more effects (progression system TBD)
- Transforms halfway through Act 2, coinciding with the protagonist's realization that they're on a revenge quest
- Exact form and nature left as a McGuffin for now

---

## Opening Experience

### The Starting Village

Small, cozy, rustic. Everyone knows each other. About a minute to walk end to end. Room for secrets and side discoveries.

**Layout (entrance to back):**

```
[Village Exit / Road]
        |
    [Tavern] — near the entrance, first thing travelers see
        |
  [Village Square + Fountain] — center of town
      /       \
[Your House] [Claira's House] — near each other, residential area
        |
    [Fields] — farmland, farmers working
        |
  [Elder's House + Garden] — far edge, peaceful, removed
```

**NPCs (~14 people):**

| Location | NPCs | Dialogue |
|----------|------|----------|
| Tavern | Tavern keeper + 2-3 patrons | Keeper: cheerful gossip, knew your parents, treats you like family. Patrons: 1-2 lines of flavor. |
| Village Square | 2-3 kids playing near fountain | Running around, laughing. A line or two if talked to. |
| Square bench | Old couple | Warm and sweet. One line that sticks with you after the village is gone — a hint of something. |
| Fields | 2-3 farmers (including your dad) | Friendly waves, small talk. Dad's working. |
| Claira's house area | Claira (in the square initially) | Real conversation — everyday banter, teasing. |
| Elder's house | The elder | Real conversation — tea, warmth, then the errand. |
| Your house | Empty (you just left) | A family photo inside: mom, dad, you. Mom works at the library. |

**The protagonist's family:** Mom (librarian), Dad (farmer in the fields). Ordinary people. Both die in the attack.

### Opening Flow

1. **Leave your house** — the day starts normally.
2. **Explore the village** — talk to tavern keeper (gossip + warmth), old couple (sweet + one haunting line), farmers, kids. See the family photo in your house. Dad's in the fields.
3. **Find Claira at the square** — everyday banter, she gives you grief about something.
4. **Walk together toward the elder's house** — passing through the residential area and fields.
5. **Behind the tree** — Claira pulls you aside. Quick kiss, teasing, intimate. A private moment that's just yours. The relationship is already real.
6. **Arrive at the elder's** — tea, warmth, grandma energy. She asks about your day, fusses over you.
7. **The errand** — casual. "Can you run this to the Millers' and bring back something for me?" The trinket request is buried in a normal visit.
8. **Leave the village alone** — Claira stays with grandma. She has things to do. Business as usual.
9. **The road** — encounter some critters. Auto-battler tutorial. Just you, solo.
10. **The homestead** — deliver the package, pick up the trinket. Brief interaction.
11. **Head back** — see smoke on the horizon.
12. **Arrive to destruction** — the village is gone. The dragon already left. It didn't even linger. Everyone is dead.
13. **Find Claira** — her grandmother's magical barrier is fading. You pull her out just in time. A few minutes later and she'd have burned too. The elder spent her last magic on this.
14. **Leave with nothing** — the trinket, Claira, and the road ahead.

No prophecy, no chosen one. The dragon didn't target the village — it was just in the way.

---

## Progression System

All meaningful decisions happen outside of combat.

### Stats (10)

HP, MP, Attack, Defense, Magic, Resistance, Speed, Accuracy, Evasion, Luck

- Both combat and support characters have the same stat set
- Support character stats influence the effectiveness of their station

### Leveling — Stat Points (Persona-style)

- On level-up, distribute stat points across 10 stats
- **Starts at 3 points per level, scales to 5** — early game forces hard choices, late game lets you fill gaps
- Hard cap per stat (balancing knob)
- Applies to both combat and support characters — building support characters is just as strategic

### Skill Tree

- Each character has a unique passive skill tree
- **Skill points awarded at milestone levels** (not every level — spacing is a balancing knob)
- Tree has a **binary fork** — the branch you take IS your specialization
- Unlocks passives and abilities
- **Respec at towns** for a cost
- Both combat and support characters have full skill trees with specialization forks

### Gear

- Equip weapons, armor, accessories
- Bought at shops, found as loot
- Available for both combat and support characters

### Abilities

- Learned through the skill tree
- Combat characters: choose which abilities to equip for each fight (loadout)
- Support characters: abilities enhance their station effects

---

## Combat (Auto-Battler)

### Pre-Fight Setup

- All combat characters fight every battle — no party selection, army grows over time
- Equip gear and choose ability loadouts per character
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

## Station System

Each support character runs a **unique station** determined by their class and identity. The station's effect scales with the support character's relevant stats. Building support characters (stat points, skill tree, gear) directly improves their station output.

- **Hybrid system:** character determines WHAT the station does, stats determine HOW WELL
- Station count grows as you recruit — more pairs = more stations active
- Support character skill tree specialization can change or enhance station behavior
- Specific stations TBD per support character

---

## World Structure

### Towns (5-6)

Each town has:

- A **boss** to defeat before moving on
- **1 recruitable bonded pair** (combat + support character)
- **Shops** (gear, items)
- **Respec option** (change specialization for a cost)
- Serves as **save checkpoint**

### Between Towns

- **Visible encounters** — enemies on the map, you choose to engage or avoid. No random encounters. You see what's coming and prep accordingly. Cool creatures to discover.
- **Camps** — rest stops for quick party management. Swap gear, reassign stations, but no shops or respec.
- **Small villages** — quest destinations and character hometowns. Side content, story beats, recruitment cutscenes. Some characters decline to join at the main town and are recruited through a story moment at their home village.
- Resource gathering

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

- Town 5 + 6 bonded pairs (combat + support characters)
- Mining Town support character (waiting for narrative)
- Specialization details for all character skill trees
- Support character station specifics (what does each station do?)
- Bonded pair mechanics — does the bond have a gameplay effect?
- Gear system depth
- Commander action specifics
- Art style
- Protagonist's specialization fork
- Town 2 enforcer boss specifics
- Town names
- The butler — who/what are they?
- Dragon's castle level design
- Small village locations, quests, and character hometowns
- Creature/enemy bestiary for visible encounters
- Stat cap values (balancing knob)
- Skill point milestone spacing (balancing knob)
