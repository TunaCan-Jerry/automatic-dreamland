# Automatic Dreamland — Battle System MVP Spec

## Overview

A playable vertical slice of the battle system: a tactics auto-battler on a hex grid. Characters auto-move, auto-target, and auto-fight. The player's strategy lives in pre-fight setup (placement, loadouts, targeting priorities) and limited commander actions during combat.

## Scope

### In Scope
- Shared hex grid battlefield (~18 hexes for MVP, scalable to ~30+)
- Pre-fight placement screen with drag-to-place
- Ability loadout and targeting priority selection per character
- Auto-battler combat with hex pathfinding and movement
- Turn order based on Speed stat
- CombatAI for both allies and enemies
- 1 commander action per fight (use item or call retreat)
- Win/lose state
- 2-3 ally test characters with basic stats and abilities
- 3-4 enemy test characters
- Speed/pause controls
- Placeholder art (colored shapes with labels)

### Out of Scope
- Leveling / stat allocation
- Skill trees
- Gear system
- Stations / support characters
- Town navigation / overworld
- Story / dialogue
- Sound / music
- Save/load

## Architecture: Hybrid (Data + Scene)

### Data Layer (Pure GDScript, no scenes)

#### HexGrid (`scripts/data/hex_grid.gd`)
- Hex tiles stored as dictionary: axial coordinates (Vector2i) → tile data
- Tile data: occupied (bool), occupant reference
- Grid shape: radius-2 hex cluster per side (7 hexes each = 14 total), separated by 2 empty hex columns in the middle (neutral zone). ~18 hexes total. Scales by increasing radius.
- Ally placement zone: left cluster. Enemy placement zone: right cluster. Neutral zone: middle columns.
- Enemies are pre-placed per encounter (defined in encounter data).
- Pathfinding: A* on hex grid
- Utility: adjacency list, range calculation (hex distance)
- Hex math: axial ↔ pixel coordinate conversion
- Grid size configurable (start ~18 hexes, scale to ~30+)

#### BattleState (`scripts/data/battle_state.gd`)
- Combatant list: array of combatant data (allies + enemies)
- Combatant data: name, stats (HP, MP, Attack, Defense, Magic, Resistance, Speed, Accuracy, Evasion, Luck), current HP/MP, position (axial coords), targeting priority, ability loadout, team (ally/enemy), movement allowance (fixed: 3 hexes per turn for MVP), per-ability cooldown counters (dictionary: ability_name → turns remaining)
- Turn queue: sorted by Speed, random tiebreak. Rebuilt each round (after all combatants have acted). Dead combatants removed immediately.
- Tracks active status effects (list of {effect_type, stat_modified, amount, remaining_turns})
- Win condition: all enemies dead
- Lose condition: all allies dead
- Commander action pool: 1 per fight

#### CombatAI (`scripts/data/combat_ai.gd`)
- Per-turn decision for each combatant:
  1. Select target based on targeting priority
  2. If target in ability/attack range → use ability or basic attack
  3. If not in range → pathfind toward target, move up to movement allowance
  4. If moved into range → attack
- Targeting priorities (MVP set):
  - Attack nearest
  - Attack weakest (lowest HP)
  - Attack strongest (highest Attack)
  - Protect allies (target the enemy closest to the lowest-HP ally)
- Same AI logic for allies and enemies — player advantage comes from better configuration
- Ability usage: use highest priority available ability, fall back to basic attack

#### CombatResolver (`scripts/data/combat_resolver.gd`)
- Resolves attack/ability actions into damage/healing
- **Physical damage formula:** `max(1, attacker.Attack * ability.power_mult - defender.Defense)`
- **Magic damage formula:** `max(1, attacker.Magic * ability.power_mult - defender.Resistance)`
- **Hit chance:** `clamp(attacker.Accuracy - defender.Evasion, 5, 99)` (always 5%-99%)
- **Crit chance:** `clamp(attacker.Luck * 2, 1, 30)` (1%-30%). Crits deal 1.5x damage.
- **Healing formula:** `caster.Magic * ability.power_mult`
- Applies status effects (buff/debuff: modifies a stat by an amount for N turns)
- Status effects tick down at the start of the affected combatant's turn
- Returns result data (damage dealt, healed, crit, miss, kill, status applied) for scene layer to animate

#### Basic Attack
- Every combatant has an implicit basic attack: melee, range 1 (adjacent hex), physical damage, power_mult 1.0, 0 MP cost
- Used when no ability is available (out of MP, all on cooldown, or no ability in range)
- CombatAI falls back to basic attack automatically

#### CommanderActions (`scripts/data/commander_actions.gd`)
- Pool: 1 action per fight
- Available actions:
  - Use Item: heal target character (flat 30 HP restore)
  - Call Retreat: end fight immediately, reload pre-fight screen
- Commander action button is always visible during combat. Clicking it pauses the turn loop and presents action options. Player picks target and confirms. Turn loop resumes.

#### BattleManager (`scripts/battle/battle_manager.gd`)
- Orchestrator that connects data layer to scene layer
- Manages phase transitions (PRE_FIGHT → COMBAT → POST_COMBAT)
- Runs the turn loop: dequeue combatant → AI decision → resolve → animate → check win/lose → next
- Handles commander action pausing/resuming
- Feeds animation events to BattleScene and waits for completion
- References: BattleState, CombatAI, CombatResolver, CommanderActions, BattleScene

### Scene Layer (Godot scenes observing data)

#### BattleScene (`scenes/battle/battle.tscn`)
- Main scene: contains hex grid visual, character sprites, UI
- Two phases: PRE_FIGHT and COMBAT
- Reads BattleState, updates visuals each turn
- Manages animation queue (move, attack, damage, death)
- Waits for animation completion before advancing turns

#### HexTileScene (`scenes/battle/hex_tile.tscn`)
- Individual hex tile (Polygon2D or Sprite2D)
- States: empty, ally-occupied, enemy-occupied, highlighted, selected
- Color-coded by state
- Click input for pre-fight placement
- Hover highlight

#### CharacterSprite (`scenes/battle/character_sprite.tscn`)
- Placeholder: colored circle/shape with name label
- Green for allies, red for enemies
- HP bar above
- Animates: move between hexes (tween), attack (flash/bump), take damage (shake/flash), death (fade)

#### BattleUI (`scenes/battle/ui/battle_ui.tscn`)
- Turn order bar: shows queue of upcoming turns with character icons
- Commander action button(s): greyed out when spent
- Character info panel: stats, HP, abilities on hover/click
- Speed controls: 1x, 2x, pause
- Win/lose popup with "Retry" button

#### PreFightUI (`scenes/battle/ui/pre_fight_ui.tscn`)
- Shows full hex grid with ally placement zone highlighted
- Character roster panel on the side
- Drag characters from roster onto hex tiles
- Per-character panel: targeting priority dropdown, ability loadout toggles
- "Start Battle" button (disabled until all characters placed)

## Turn Flow

```
PRE-FIGHT PHASE:
  → PreFightUI active
  → Player drags characters onto ally hexes
  → Player sets targeting priority per character
  → Player sets ability loadout per character
  → Player clicks "Start Battle"
  → Transition to COMBAT phase

COMBAT PHASE:
  → BattleState sorts combatants by Speed → turn queue
  → Loop:
    → Dequeue next combatant
    → CombatAI decides action (move, attack, ability)
    → CombatResolver resolves the action
    → BattleScene animates the result
    → Wait for animation
    → Check win/lose
    → Between any turns: player can spend commander action
  → Until win or lose

POST-COMBAT:
  → Win: victory screen (XP/loot stubbed)
  → Lose: game over screen with "Retry" button (reloads pre-fight)
```

## Ability Schema

Each ability is defined as:

| Field | Type | Description |
|-------|------|-------------|
| name | String | Display name |
| type | String | "physical", "magic", "heal", "buff", "debuff" |
| power_mult | float | Multiplier for damage/healing formula (1.0 = basic attack equivalent) |
| mp_cost | int | MP consumed on use |
| range | int | Hex distance (1 = adjacent, 0 = self) |
| target | String | "enemy", "ally", "self", "all_enemies", "all_allies", "adjacent_allies", "adjacent_hexes". Always relative to the caster (e.g., "enemy" means "enemy of the caster", "all_allies" means "all units on caster's team"). "adjacent_hexes" = AoE hitting ALL hexes adjacent to the caster. |
| cooldown | int | Turns before reuse (0 = no cooldown) |
| status_effect | dict or null | {stat: String, amount: int, duration: int} — applied on hit |
| push | int | Hexes to push target (0 = none). Pushed into occupied/off-grid = push fails, target stays. |
| bonus_move | int | Extra movement hexes granted immediately this turn (one-time, not a lasting buff). Combatant can move bonus_move additional hexes on the turn the ability is used. |

### MVP Ability Definitions

**Ally Abilities:**

| Name | Type | Power | MP | Range | Target | CD | Status Effect | Push | Bonus Move |
|------|------|-------|----|-------|--------|----|---------------|------|------------|
| Rally | buff | — | 10 | 1 | adjacent_allies | 3 | {Attack, +5, 3 turns} | 0 | 0 |
| Shield Bash | physical | 1.2 | 8 | 1 | enemy | 2 | — | 1 | 0 |
| Power Shot | physical | 1.8 | 10 | 3 | enemy | 2 | — | 0 | 0 |
| Quick Step | buff | — | 5 | 0 | self | 3 | — | 0 | 2 |
| Heal | heal | 1.5 | 12 | 2 | ally | 0 | — | 0 | 0 |
| Barrier | buff | — | 10 | 1 | ally | 3 | {Defense, +8, 2 turns} | 0 | 0 |

**Enemy Abilities:**

| Name | Type | Power | MP | Range | Target | CD | Status Effect | Push | Bonus Move |
|------|------|-------|----|-------|--------|----|---------------|------|------------|
| Slash | physical | 1.0 | 0 | 1 | enemy | 0 | — | 0 | 0 |
| Arrow | physical | 1.0 | 0 | 2 | enemy | 0 | — | 0 | 0 |
| Dark Bolt | magic | 1.5 | 8 | 3 | enemy | 0 | — | 0 | 0 |
| Hex | debuff | — | 10 | 2 | enemy | 3 | {Defense, -5, 3 turns} | 0 | 0 |
| Cleave | physical | 1.3 | 5 | 1 | adjacent_hexes | 2 | — | 0 | 0 |
| War Cry | buff | — | 10 | 0 | all_allies | 4 | {Attack, +4, 3 turns} | 0 | 0 |

---

## Test Characters

### Allies (3)

| Name | Role | HP | MP | Atk | Def | Mag | Res | Spd | Acc | Eva | Luck | Abilities |
|------|------|----|----|-----|-----|-----|-----|-----|-----|-----|------|-----------|
| Leader | Tank/Buffer | 120 | 40 | 12 | 15 | 8 | 10 | 8 | 85 | 5 | 5 | Rally (buff adjacent allies +Atk), Shield Bash (damage + push 1 hex) |
| Ranger | DPS/Range | 80 | 30 | 15 | 8 | 5 | 6 | 12 | 90 | 15 | 8 | Power Shot (high damage, 3 hex range), Quick Step (move 2 extra hexes) |
| Healer | Support | 70 | 60 | 5 | 6 | 15 | 12 | 10 | 95 | 10 | 10 | Heal (restore HP, 2 hex range), Barrier (reduce next damage taken, adjacent) |

### Enemies (4)

| Name | Role | HP | MP | Atk | Def | Mag | Res | Spd | Acc | Eva | Luck | Abilities |
|------|------|----|----|-----|-----|-----|-----|-----|-----|-----|------|-----------|
| Goblin | Melee fodder | 40 | 0 | 10 | 5 | 2 | 3 | 11 | 75 | 12 | 3 | Slash (basic melee) |
| Goblin Archer | Ranged | 30 | 0 | 8 | 4 | 2 | 3 | 13 | 80 | 8 | 3 | Arrow (2 hex range) |
| Goblin Shaman | Caster | 35 | 40 | 3 | 4 | 12 | 8 | 9 | 85 | 5 | 5 | Dark Bolt (magic damage, 3 hex range), Hex (debuff -Def, 2 hex range) |
| Goblin Chief | Boss | 100 | 20 | 14 | 12 | 6 | 8 | 7 | 80 | 3 | 5 | Cleave (damage adjacent hexes), War Cry (buff all goblins +Atk) |

## File Structure

```
automatic_dreamland/
├── project.godot
├── docs/
│   └── specs/
│       └── 2026-05-14-battle-mvp-spec.md
├── scripts/
│   ├── data/
│   │   ├── hex_grid.gd
│   │   ├── battle_state.gd
│   │   ├── combat_ai.gd
│   │   ├── combat_resolver.gd
│   │   └── commander_actions.gd
│   └── battle/
│       ├── battle_manager.gd
│       ├── hex_tile.gd
│       ├── character_sprite.gd
│       ├── battle_ui.gd
│       └── pre_fight_ui.gd
└── scenes/
    └── battle/
        ├── battle.tscn
        ├── hex_tile.tscn
        ├── character_sprite.tscn
        └── ui/
            ├── battle_ui.tscn
            └── pre_fight_ui.tscn
```

## Open Questions (Post-MVP)

- Movement allowance: stat-based instead of fixed 3?
- Terrain types on hexes (blocking, slow, buff zones)
- Line of sight mechanics (blocked by terrain/units)
- More ability targeting shapes (cone, line, area)
- CombatantData as Godot Resource for reusability
- Animation polish and timing
- Sound effects
- Bonded pair mechanics on the battlefield
- How the grid scales from 18 to 30+ hexes as party grows
