# Battle System MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable tactics auto-battler on a hex grid in Godot 4.x — pre-fight setup, auto-combat with hex movement, commander actions, win/lose.

**Architecture:** Hybrid data + scene. Pure GDScript data layer handles all game logic (hex math, combat, AI, pathfinding). Godot scenes observe and render the data. BattleManager orchestrates the connection.

**Tech Stack:** Godot 4.x, GDScript, GUT (Godot Unit Test) for data layer tests.

**Spec:** `docs/specs/2026-05-14-battle-mvp-spec.md`

---

## File Structure

```
automatic_dreamland/
├── project.godot
├── addons/gut/                          # GUT testing addon
├── tests/
│   ├── test_hex_grid.gd                 # HexGrid unit tests
│   ├── test_combat_resolver.gd          # CombatResolver unit tests
│   ├── test_battle_state.gd             # BattleState unit tests
│   └── test_combat_ai.gd               # CombatAI unit tests
├── scripts/
│   ├── data/
│   │   ├── hex_grid.gd                  # Hex math, grid, pathfinding
│   │   ├── ability_data.gd              # Ability schema as dictionary
│   │   ├── combatant_data.gd            # Combatant stats + abilities
│   │   ├── encounter_data.gd            # Enemy pre-placement definitions
│   │   ├── battle_state.gd              # Turn queue, status effects, win/lose
│   │   ├── combat_resolver.gd           # Damage/healing/status formulas
│   │   ├── combat_ai.gd                 # Targeting, movement, ability decisions
│   │   └── commander_actions.gd         # Item use, retreat
│   └── battle/
│       ├── battle_manager.gd            # Orchestrator: phases, turn loop, animations
│       ├── hex_tile.gd                  # Script for hex tile scene
│       ├── character_sprite.gd          # Script for character sprite scene
│       ├── pre_fight_ui.gd              # Pre-fight placement and setup UI
│       └── battle_ui.gd                 # In-combat UI (turn order, commander, speed)
├── scenes/
│   └── battle/
│       ├── battle.tscn                  # Main battle scene
│       ├── hex_tile.tscn                # Hex tile scene
│       ├── character_sprite.tscn        # Character sprite scene
│       └── ui/
│           ├── pre_fight_ui.tscn        # Pre-fight UI scene
│           └── battle_ui.tscn           # Combat UI scene
└── resources/
    └── encounters/
        └── test_encounter.tres          # MVP test encounter data
```

---

## Task 1: Project Setup

**Files:**
- Create: `project.godot`
- Create: directory structure per file structure above
- Install: GUT addon

- [ ] **Step 1: Create Godot project**

Open terminal at `/Users/wells/projects/automatic_dreamland`. Create `project.godot`:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be edited manually.

config_version=5

[application]
config/name="Automatic Dreamland"
run/main_scene="res://scenes/battle/battle.tscn"
config/features=PackedStringArray("4.4")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720

[rendering]
renderer/rendering_method="gl_compatibility"
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p scripts/data scripts/battle scenes/battle/ui tests resources/encounters
```

- [ ] **Step 3: Install GUT**

```bash
cd /Users/wells/projects/automatic_dreamland
git clone https://github.com/bitwes/Gut.git addons/gut --depth 1
```

Add to `project.godot` under `[editor_plugins]`:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 4: Create `.gitignore`**

```
.godot/
.superpowers/
addons/gut/.git/
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: project setup with Godot 4.x and GUT testing"
```

---

## Task 2: Hex Grid Data Layer

**Files:**
- Create: `scripts/data/hex_grid.gd`
- Create: `tests/test_hex_grid.gd`

This is the foundation — all hex math, grid creation, adjacency, distance, and A* pathfinding. Pure data, no scenes.

Reference: https://www.redblobgames.com/grids/hexagons/ (axial coordinates)

- [ ] **Step 1: Write failing tests for hex math basics**

Create `tests/test_hex_grid.gd`:

```gdscript
extends GutTest

var grid: RefCounted

func before_each():
	grid = load("res://scripts/data/hex_grid.gd").new()

func test_axial_to_pixel_returns_vector2():
	var pixel = grid.axial_to_pixel(Vector2i(0, 0))
	assert_typeof(pixel, TYPE_VECTOR2)

func test_axial_to_pixel_origin():
	var pixel = grid.axial_to_pixel(Vector2i(0, 0))
	assert_eq(pixel, Vector2(0, 0))

func test_axial_neighbors_returns_6():
	var neighbors = grid.get_neighbors(Vector2i(0, 0))
	assert_eq(neighbors.size(), 6)

func test_hex_distance_adjacent():
	assert_eq(grid.hex_distance(Vector2i(0, 0), Vector2i(1, 0)), 1)

func test_hex_distance_two_away():
	assert_eq(grid.hex_distance(Vector2i(0, 0), Vector2i(2, 0)), 2)

func test_hex_distance_diagonal():
	assert_eq(grid.hex_distance(Vector2i(0, 0), Vector2i(1, -1)), 1)
```

- [ ] **Step 2: Run tests — verify they fail**

Run via Godot editor: open GUT panel, run `test_hex_grid.gd`.
Expected: FAIL — `hex_grid.gd` does not exist yet.

- [ ] **Step 3: Implement HexGrid — hex math**

Create `scripts/data/hex_grid.gd`:

```gdscript
class_name HexGrid
extends RefCounted

const HEX_SIZE := 32.0
const SQRT3 := 1.7320508

var tiles: Dictionary = {}  # Vector2i -> Dictionary {occupied, occupant}

func axial_to_pixel(hex: Vector2i) -> Vector2:
	var x = HEX_SIZE * (SQRT3 * hex.x + SQRT3 / 2.0 * hex.y)
	var y = HEX_SIZE * (3.0 / 2.0 * hex.y)
	return Vector2(x, y)

func pixel_to_axial(pixel: Vector2) -> Vector2i:
	var q = (SQRT3 / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / HEX_SIZE
	var r = (2.0 / 3.0 * pixel.y) / HEX_SIZE
	return axial_round(Vector2(q, r))

func axial_round(frac: Vector2) -> Vector2i:
	var q = round(frac.x)
	var r = round(frac.y)
	var s = round(-frac.x - frac.y)
	var q_diff = abs(q - frac.x)
	var r_diff = abs(r - frac.y)
	var s_diff = abs(s - (-frac.x - frac.y))
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	return Vector2i(int(q), int(r))

const DIRECTIONS = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var neighbor = hex + dir
		if tiles.has(neighbor):
			result.append(neighbor)
	return result

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var diff = a - b
	return (abs(diff.x) + abs(diff.x + diff.y) + abs(diff.y)) / 2
```

- [ ] **Step 4: Run tests — verify they pass**

Run `test_hex_grid.gd` via GUT. Expected: all tests PASS.
Note: `get_neighbors` test needs tiles added — update test `before_each` to call `grid.create_battle_grid()` once that method exists (Task 2, Step 7).

- [ ] **Step 5: Commit**

```bash
git add scripts/data/hex_grid.gd tests/test_hex_grid.gd
git commit -m "feat: hex grid data layer with axial math and distance"
```

- [ ] **Step 6: Write failing tests for grid creation and pathfinding**

Add to `tests/test_hex_grid.gd`:

```gdscript
func test_create_battle_grid_has_tiles():
	grid.create_battle_grid()
	assert_gt(grid.tiles.size(), 0)

func test_ally_zone_exists():
	grid.create_battle_grid()
	var ally_zone = grid.get_ally_zone()
	assert_gt(ally_zone.size(), 0)

func test_enemy_zone_exists():
	grid.create_battle_grid()
	var enemy_zone = grid.get_enemy_zone()
	assert_gt(enemy_zone.size(), 0)

func test_pathfind_returns_path():
	grid.create_battle_grid()
	var all_tiles = grid.tiles.keys()
	var path = grid.find_path(all_tiles[0], all_tiles[all_tiles.size() - 1])
	assert_gt(path.size(), 0)

func test_pathfind_avoids_occupied():
	grid.create_battle_grid()
	var all_tiles = grid.tiles.keys()
	# Occupy middle tiles
	for tile in all_tiles.slice(2, 5):
		grid.tiles[tile].occupied = true
	var path = grid.find_path(all_tiles[0], all_tiles[all_tiles.size() - 1])
	for step in path:
		if step != all_tiles[0] and step != all_tiles[all_tiles.size() - 1]:
			assert_false(grid.tiles[step].occupied)

func test_hexes_in_range():
	grid.create_battle_grid()
	var center = Vector2i(0, 0)
	var in_range = grid.get_hexes_in_range(center, 1)
	for hex in in_range:
		assert_lte(grid.hex_distance(center, hex), 1)
```

- [ ] **Step 7: Implement grid creation, zones, pathfinding**

Add to `scripts/data/hex_grid.gd`:

```gdscript
enum Zone { ALLY, NEUTRAL, ENEMY }

var tile_zones: Dictionary = {}  # Vector2i -> Zone

func create_battle_grid() -> void:
	tiles.clear()
	tile_zones.clear()
	# Ally cluster: radius 2 centered at (-3, 0)
	_create_hex_cluster(Vector2i(-3, 0), 2, Zone.ALLY)
	# Enemy cluster: radius 2 centered at (3, 0)
	_create_hex_cluster(Vector2i(3, 0), 2, Zone.ENEMY)
	# Neutral zone: columns at x=-1, 0, 1
	for r in range(-2, 3):
		for q in [-1, 0, 1]:
			var hex = Vector2i(q, r)
			if not tiles.has(hex):
				tiles[hex] = {occupied = false, occupant = null}
				tile_zones[hex] = Zone.NEUTRAL

func _create_hex_cluster(center: Vector2i, radius: int, zone: Zone) -> void:
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var s = -q - r
			if abs(q) <= radius and abs(r) <= radius and abs(s) <= radius:
				var hex = center + Vector2i(q, r)
				tiles[hex] = {occupied = false, occupant = null}
				tile_zones[hex] = zone

func get_ally_zone() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tile_zones:
		if tile_zones[hex] == Zone.ALLY:
			result.append(hex)
	return result

func get_enemy_zone() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tile_zones:
		if tile_zones[hex] == Zone.ENEMY:
			result.append(hex)
	return result

func get_hexes_in_range(center: Vector2i, hex_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tiles:
		if hex_distance(center, hex) <= hex_range:
			result.append(hex)
	return result

func is_occupied(hex: Vector2i) -> bool:
	return tiles.has(hex) and tiles[hex].occupied

func place_combatant(hex: Vector2i, combatant) -> void:
	tiles[hex].occupied = true
	tiles[hex].occupant = combatant

func remove_combatant(hex: Vector2i) -> void:
	if tiles.has(hex):
		tiles[hex].occupied = false
		tiles[hex].occupant = null

func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not tiles.has(start) or not tiles.has(end):
		return []
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: hex_distance(start, end)}

	while open_set.size() > 0:
		var current = _lowest_f(open_set, f_score)
		if current == end:
			return _reconstruct_path(came_from, current)
		open_set.erase(current)
		for neighbor in get_neighbors(current):
			if neighbor != end and tiles[neighbor].occupied:
				continue
			var tentative_g = g_score[current] + 1
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + hex_distance(neighbor, end)
				if neighbor not in open_set:
					open_set.append(neighbor)
	return []

func _lowest_f(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best = open_set[0]
	for hex in open_set:
		if f_score.get(hex, INF) < f_score.get(best, INF):
			best = hex
	return best

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
```

- [ ] **Step 8: Run tests — verify they pass**

Run `test_hex_grid.gd` via GUT. Expected: all tests PASS.

- [ ] **Step 9: Commit**

```bash
git add scripts/data/hex_grid.gd tests/test_hex_grid.gd
git commit -m "feat: hex grid creation, zones, pathfinding"
```

---

## Task 3: Combatant and Ability Data

**Files:**
- Create: `scripts/data/ability_data.gd`
- Create: `scripts/data/combatant_data.gd`
- Create: `scripts/data/encounter_data.gd`

These define the data structures for abilities, combatants, and encounters. Pure data dictionaries.

- [ ] **Step 1: Create ability data**

Create `scripts/data/ability_data.gd`:

```gdscript
class_name AbilityData
extends RefCounted

var name: String
var type: String  # "physical", "magic", "heal", "buff", "debuff"
var power_mult: float
var mp_cost: int
var ability_range: int
var target: String  # "enemy", "ally", "self", "all_enemies", "all_allies", "adjacent_allies", "adjacent_hexes"
var cooldown: int
var status_effect: Dictionary  # {stat, amount, duration} or empty
var push: int
var bonus_move: int

func _init(data: Dictionary = {}) -> void:
	name = data.get("name", "")
	type = data.get("type", "physical")
	power_mult = data.get("power_mult", 1.0)
	mp_cost = data.get("mp_cost", 0)
	ability_range = data.get("range", 1)
	target = data.get("target", "enemy")
	cooldown = data.get("cooldown", 0)
	status_effect = data.get("status_effect", {})
	push = data.get("push", 0)
	bonus_move = data.get("bonus_move", 0)

static func basic_attack() -> AbilityData:
	return AbilityData.new({
		"name": "Basic Attack",
		"type": "physical",
		"power_mult": 1.0,
		"mp_cost": 0,
		"range": 1,
		"target": "enemy",
		"cooldown": 0,
	})
```

- [ ] **Step 2: Create combatant data**

Create `scripts/data/combatant_data.gd`:

```gdscript
class_name CombatantData
extends RefCounted

var combatant_name: String
var team: String  # "ally" or "enemy"
var stats: Dictionary  # {hp, mp, attack, defense, magic, resistance, speed, accuracy, evasion, luck}
var current_hp: int
var current_mp: int
var position: Vector2i
var targeting_priority: String  # "nearest", "weakest", "strongest", "protect"
var abilities: Array[AbilityData]
var movement_allowance: int = 3
var cooldowns: Dictionary = {}  # ability_name -> turns remaining
var status_effects: Array = []  # [{stat, amount, remaining_turns}]

func _init(data: Dictionary = {}) -> void:
	combatant_name = data.get("name", "Unknown")
	team = data.get("team", "enemy")
	stats = data.get("stats", {})
	current_hp = stats.get("hp", 1)
	current_mp = stats.get("mp", 0)
	position = data.get("position", Vector2i.ZERO)
	targeting_priority = data.get("targeting_priority", "nearest")
	movement_allowance = data.get("movement_allowance", 3)
	abilities = []
	for ability_dict in data.get("abilities", []):
		abilities.append(AbilityData.new(ability_dict))

func is_alive() -> bool:
	return current_hp > 0

func get_effective_stat(stat_name: String) -> int:
	var base = stats.get(stat_name, 0)
	for effect in status_effects:
		if effect.stat == stat_name:
			base += effect.amount
	return max(0, base)

func tick_status_effects() -> void:
	var remaining: Array = []
	for effect in status_effects:
		effect.remaining_turns -= 1
		if effect.remaining_turns > 0:
			remaining.append(effect)
	status_effects = remaining

func tick_cooldowns() -> void:
	for ability_name in cooldowns.keys():
		cooldowns[ability_name] -= 1
		if cooldowns[ability_name] <= 0:
			cooldowns.erase(ability_name)

func can_use_ability(ability: AbilityData) -> bool:
	if ability.mp_cost > current_mp:
		return false
	if cooldowns.has(ability.name):
		return false
	return true
```

- [ ] **Step 3: Create encounter data with MVP test encounter**

Create `scripts/data/encounter_data.gd`:

```gdscript
class_name EncounterData
extends RefCounted

var enemies: Array[Dictionary] = []

static func test_encounter() -> EncounterData:
	var encounter = EncounterData.new()
	encounter.enemies = [
		{
			"name": "Goblin",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"targeting_priority": "nearest",
			"stats": {"hp": 40, "mp": 0, "attack": 10, "defense": 5, "magic": 2, "resistance": 3, "speed": 11, "accuracy": 75, "evasion": 12, "luck": 3},
			"abilities": [{"name": "Slash", "type": "physical", "power_mult": 1.0, "mp_cost": 0, "range": 1, "target": "enemy", "cooldown": 0}]
		},
		{
			"name": "Goblin Archer",
			"team": "enemy",
			"position": Vector2i(3, -1),
			"targeting_priority": "weakest",
			"stats": {"hp": 30, "mp": 0, "attack": 8, "defense": 4, "magic": 2, "resistance": 3, "speed": 13, "accuracy": 80, "evasion": 8, "luck": 3},
			"abilities": [{"name": "Arrow", "type": "physical", "power_mult": 1.0, "mp_cost": 0, "range": 2, "target": "enemy", "cooldown": 0}]
		},
		{
			"name": "Goblin Shaman",
			"team": "enemy",
			"position": Vector2i(4, 0),
			"targeting_priority": "strongest",
			"stats": {"hp": 35, "mp": 40, "attack": 3, "defense": 4, "magic": 12, "resistance": 8, "speed": 9, "accuracy": 85, "evasion": 5, "luck": 5},
			"abilities": [
				{"name": "Dark Bolt", "type": "magic", "power_mult": 1.5, "mp_cost": 8, "range": 3, "target": "enemy", "cooldown": 0},
				{"name": "Hex", "type": "debuff", "power_mult": 0.0, "mp_cost": 10, "range": 2, "target": "enemy", "cooldown": 3, "status_effect": {"stat": "defense", "amount": -5, "duration": 3}}
			]
		},
		{
			"name": "Goblin Chief",
			"team": "enemy",
			"position": Vector2i(3, 1),
			"targeting_priority": "nearest",
			"stats": {"hp": 100, "mp": 20, "attack": 14, "defense": 12, "magic": 6, "resistance": 8, "speed": 7, "accuracy": 80, "evasion": 3, "luck": 5},
			"abilities": [
				{"name": "Cleave", "type": "physical", "power_mult": 1.3, "mp_cost": 5, "range": 1, "target": "adjacent_hexes", "cooldown": 2},
				{"name": "War Cry", "type": "buff", "power_mult": 0.0, "mp_cost": 10, "range": 0, "target": "all_allies", "cooldown": 4, "status_effect": {"stat": "attack", "amount": 4, "duration": 3}}
			]
		}
	]
	return encounter

static func ally_roster() -> Array[Dictionary]:
	return [
		{
			"name": "Leader",
			"team": "ally",
			"targeting_priority": "nearest",
			"stats": {"hp": 120, "mp": 40, "attack": 12, "defense": 15, "magic": 8, "resistance": 10, "speed": 8, "accuracy": 85, "evasion": 5, "luck": 5},
			"abilities": [
				{"name": "Rally", "type": "buff", "power_mult": 0.0, "mp_cost": 10, "range": 1, "target": "adjacent_allies", "cooldown": 3, "status_effect": {"stat": "attack", "amount": 5, "duration": 3}},
				{"name": "Shield Bash", "type": "physical", "power_mult": 1.2, "mp_cost": 8, "range": 1, "target": "enemy", "cooldown": 2, "push": 1}
			]
		},
		{
			"name": "Ranger",
			"team": "ally",
			"targeting_priority": "weakest",
			"stats": {"hp": 80, "mp": 30, "attack": 15, "defense": 8, "magic": 5, "resistance": 6, "speed": 12, "accuracy": 90, "evasion": 15, "luck": 8},
			"abilities": [
				{"name": "Power Shot", "type": "physical", "power_mult": 1.8, "mp_cost": 10, "range": 3, "target": "enemy", "cooldown": 2},
				{"name": "Quick Step", "type": "buff", "power_mult": 0.0, "mp_cost": 5, "range": 0, "target": "self", "cooldown": 3, "bonus_move": 2}
			]
		},
		{
			"name": "Healer",
			"team": "ally",
			"targeting_priority": "protect",
			"stats": {"hp": 70, "mp": 60, "attack": 5, "defense": 6, "magic": 15, "resistance": 12, "speed": 10, "accuracy": 95, "evasion": 10, "luck": 10},
			"abilities": [
				{"name": "Heal", "type": "heal", "power_mult": 1.5, "mp_cost": 12, "range": 2, "target": "ally", "cooldown": 0},
				{"name": "Barrier", "type": "buff", "power_mult": 0.0, "mp_cost": 10, "range": 1, "target": "ally", "cooldown": 3, "status_effect": {"stat": "defense", "amount": 8, "duration": 2}}
			]
		}
	]
```

- [ ] **Step 4: Commit**

```bash
git add scripts/data/ability_data.gd scripts/data/combatant_data.gd scripts/data/encounter_data.gd
git commit -m "feat: ability, combatant, and encounter data structures"
```

---

## Task 4: Combat Resolver

**Files:**
- Create: `scripts/data/combat_resolver.gd`
- Create: `tests/test_combat_resolver.gd`

All damage, healing, hit/miss, crit, and status effect formulas.

- [ ] **Step 1: Write failing tests**

Create `tests/test_combat_resolver.gd`:

```gdscript
extends GutTest

var resolver: RefCounted

func before_each():
	resolver = load("res://scripts/data/combat_resolver.gd").new()

func _make_combatant(overrides: Dictionary = {}) -> RefCounted:
	var defaults = {
		"name": "Test", "team": "ally",
		"stats": {"hp": 100, "mp": 50, "attack": 10, "defense": 5, "magic": 10, "resistance": 5, "speed": 10, "accuracy": 90, "evasion": 5, "luck": 5},
	}
	defaults.merge(overrides, true)
	return load("res://scripts/data/combatant_data.gd").new(defaults)

func _make_ability(overrides: Dictionary = {}) -> RefCounted:
	var defaults = {"name": "Test", "type": "physical", "power_mult": 1.0, "range": 1, "target": "enemy"}
	defaults.merge(overrides, true)
	return load("res://scripts/data/ability_data.gd").new(defaults)

func test_physical_damage_positive():
	var attacker = _make_combatant({"stats": {"attack": 15, "accuracy": 100, "luck": 0}})
	var defender = _make_combatant({"stats": {"hp": 100, "defense": 5, "evasion": 0}})
	var ability = _make_ability({"power_mult": 1.0})
	var result = resolver.resolve_attack(attacker, defender, ability)
	if result.hit:
		assert_eq(result.damage, 10)  # 15 * 1.0 - 5 = 10

func test_minimum_damage_is_1():
	var attacker = _make_combatant({"stats": {"attack": 1, "accuracy": 100, "luck": 0}})
	var defender = _make_combatant({"stats": {"hp": 100, "defense": 50, "evasion": 0}})
	var ability = _make_ability({"power_mult": 1.0})
	var result = resolver.resolve_attack(attacker, defender, ability)
	if result.hit:
		assert_eq(result.damage, 1)

func test_magic_damage_uses_magic_stat():
	var attacker = _make_combatant({"stats": {"magic": 12, "accuracy": 100, "luck": 0}})
	var defender = _make_combatant({"stats": {"hp": 100, "resistance": 4, "evasion": 0}})
	var ability = _make_ability({"type": "magic", "power_mult": 1.5})
	var result = resolver.resolve_attack(attacker, defender, ability)
	if result.hit:
		assert_eq(result.damage, 14)  # max(1, 12 * 1.5 - 4) = 14

func test_heal_restores_hp():
	var caster = _make_combatant({"stats": {"magic": 15}})
	var target = _make_combatant({"stats": {"hp": 100}})
	target.current_hp = 50
	var ability = _make_ability({"type": "heal", "power_mult": 1.5})
	var result = resolver.resolve_heal(caster, target, ability)
	assert_eq(result.healed, 22)  # 15 * 1.5 = 22.5 -> 22
	assert_eq(target.current_hp, 72)

func test_heal_does_not_exceed_max():
	var caster = _make_combatant({"stats": {"magic": 15}})
	var target = _make_combatant({"stats": {"hp": 100}})
	target.current_hp = 95
	var ability = _make_ability({"type": "heal", "power_mult": 1.5})
	var result = resolver.resolve_heal(caster, target, ability)
	assert_eq(target.current_hp, 100)
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL — `combat_resolver.gd` does not exist.

- [ ] **Step 3: Implement CombatResolver**

Create `scripts/data/combat_resolver.gd`:

```gdscript
class_name CombatResolver
extends RefCounted

func resolve_attack(attacker: CombatantData, defender: CombatantData, ability: AbilityData) -> Dictionary:
	var result = {hit = false, damage = 0, crit = false, kill = false, status_applied = false}

	var hit_chance = clampi(attacker.get_effective_stat("accuracy") - defender.get_effective_stat("evasion"), 5, 99)
	if randi() % 100 >= hit_chance:
		return result

	result.hit = true

	var damage: int
	if ability.type == "magic":
		damage = maxi(1, int(attacker.get_effective_stat("magic") * ability.power_mult) - defender.get_effective_stat("resistance"))
	else:
		damage = maxi(1, int(attacker.get_effective_stat("attack") * ability.power_mult) - defender.get_effective_stat("defense"))

	var crit_chance = clampi(attacker.get_effective_stat("luck") * 2, 1, 30)
	if randi() % 100 < crit_chance:
		damage = int(damage * 1.5)
		result.crit = true

	result.damage = damage
	defender.current_hp = maxi(0, defender.current_hp - damage)

	if not defender.is_alive():
		result.kill = true

	if ability.status_effect.size() > 0 and defender.is_alive():
		defender.status_effects.append({
			stat = ability.status_effect.stat,
			amount = ability.status_effect.amount,
			remaining_turns = ability.status_effect.duration
		})
		result.status_applied = true

	return result

func resolve_heal(caster: CombatantData, target: CombatantData, ability: AbilityData) -> Dictionary:
	var heal_amount = int(caster.get_effective_stat("magic") * ability.power_mult)
	var max_hp = target.stats.get("hp", 1)
	var actual_heal = mini(heal_amount, max_hp - target.current_hp)
	target.current_hp = mini(max_hp, target.current_hp + heal_amount)
	return {healed = actual_heal}

func resolve_buff(caster: CombatantData, target: CombatantData, ability: AbilityData) -> Dictionary:
	if ability.status_effect.size() > 0:
		target.status_effects.append({
			stat = ability.status_effect.stat,
			amount = ability.status_effect.amount,
			remaining_turns = ability.status_effect.duration
		})
		return {buffed = true, stat = ability.status_effect.stat, amount = ability.status_effect.amount}
	return {buffed = false}

func resolve_ability(attacker: CombatantData, targets: Array, ability: AbilityData, grid: HexGrid) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	attacker.current_mp -= ability.mp_cost
	if ability.cooldown > 0:
		attacker.cooldowns[ability.name] = ability.cooldown

	for target in targets:
		match ability.type:
			"physical", "magic":
				var result = resolve_attack(attacker, target, ability)
				result["target"] = target
				if result.hit and ability.push > 0:
					result["push"] = _resolve_push(target, attacker, ability.push, grid)
				results.append(result)
			"heal":
				var result = resolve_heal(attacker, target, ability)
				result["target"] = target
				results.append(result)
			"buff":
				var result = resolve_buff(attacker, target, ability)
				result["target"] = target
				results.append(result)
			"debuff":
				if ability.status_effect.size() > 0:
					target.status_effects.append({
						stat = ability.status_effect.stat,
						amount = ability.status_effect.amount,
						remaining_turns = ability.status_effect.duration
					})
					results.append({target = target, debuffed = true})
	return results

func _resolve_push(target: CombatantData, attacker: CombatantData, push_distance: int, grid: HexGrid) -> Dictionary:
	var dir = target.position - attacker.position
	# Normalize to one of the 6 hex directions
	var best_dir = HexGrid.DIRECTIONS[0]
	var best_dot = -INF
	for d in HexGrid.DIRECTIONS:
		var dot = dir.x * d.x + dir.y * d.y
		if dot > best_dot:
			best_dot = dot
			best_dir = d

	var new_pos = target.position + best_dir * push_distance
	if grid.tiles.has(new_pos) and not grid.is_occupied(new_pos):
		grid.remove_combatant(target.position)
		target.position = new_pos
		grid.place_combatant(new_pos, target)
		return {pushed = true, new_position = new_pos}
	return {pushed = false}
```

- [ ] **Step 4: Run tests — verify they pass**

Run `test_combat_resolver.gd` via GUT. Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/data/combat_resolver.gd tests/test_combat_resolver.gd
git commit -m "feat: combat resolver with damage, healing, crit, status effects"
```

---

## Task 5: Battle State

**Files:**
- Create: `scripts/data/battle_state.gd`
- Create: `tests/test_battle_state.gd`

Turn queue management, win/lose checking, round management.

- [ ] **Step 1: Write failing tests**

Create `tests/test_battle_state.gd`:

```gdscript
extends GutTest

var state: RefCounted

func _make_combatant(name: String, team: String, speed: int) -> RefCounted:
	return load("res://scripts/data/combatant_data.gd").new({
		"name": name, "team": team,
		"stats": {"hp": 100, "mp": 50, "attack": 10, "defense": 5, "magic": 10, "resistance": 5, "speed": speed, "accuracy": 90, "evasion": 5, "luck": 5},
	})

func before_each():
	state = load("res://scripts/data/battle_state.gd").new()

func test_build_turn_queue_sorted_by_speed():
	var fast = _make_combatant("Fast", "ally", 15)
	var slow = _make_combatant("Slow", "enemy", 5)
	state.add_combatant(fast)
	state.add_combatant(slow)
	state.build_turn_queue()
	assert_eq(state.get_next_combatant().combatant_name, "Fast")

func test_win_when_all_enemies_dead():
	var ally = _make_combatant("Ally", "ally", 10)
	var enemy = _make_combatant("Enemy", "enemy", 10)
	enemy.current_hp = 0
	state.add_combatant(ally)
	state.add_combatant(enemy)
	assert_true(state.check_win())

func test_lose_when_all_allies_dead():
	var ally = _make_combatant("Ally", "ally", 10)
	var enemy = _make_combatant("Enemy", "enemy", 10)
	ally.current_hp = 0
	state.add_combatant(ally)
	state.add_combatant(enemy)
	assert_true(state.check_lose())

func test_dead_removed_from_queue():
	var alive = _make_combatant("Alive", "ally", 10)
	var dead = _make_combatant("Dead", "enemy", 15)
	state.add_combatant(alive)
	state.add_combatant(dead)
	state.build_turn_queue()
	dead.current_hp = 0
	state.remove_dead_from_queue()
	assert_eq(state.get_next_combatant().combatant_name, "Alive")
```

- [ ] **Step 2: Run tests — verify they fail**

- [ ] **Step 3: Implement BattleState**

Create `scripts/data/battle_state.gd`:

```gdscript
class_name BattleState
extends RefCounted

var combatants: Array[CombatantData] = []
var turn_queue: Array[CombatantData] = []
var commander_actions_remaining: int = 1

func add_combatant(combatant: CombatantData) -> void:
	combatants.append(combatant)

func build_turn_queue() -> void:
	turn_queue.clear()
	for c in combatants:
		if c.is_alive():
			c.tick_status_effects()
			c.tick_cooldowns()
			turn_queue.append(c)
	turn_queue.sort_custom(func(a, b): return a.get_effective_stat("speed") > b.get_effective_stat("speed"))

func get_next_combatant() -> CombatantData:
	if turn_queue.size() == 0:
		return null
	return turn_queue[0]

func advance_turn() -> CombatantData:
	if turn_queue.size() == 0:
		return null
	return turn_queue.pop_front()

func is_round_over() -> bool:
	return turn_queue.size() == 0

func remove_dead_from_queue() -> void:
	turn_queue = turn_queue.filter(func(c): return c.is_alive())

func get_allies() -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for c in combatants:
		if c.team == "ally" and c.is_alive():
			result.append(c)
	return result

func get_enemies() -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for c in combatants:
		if c.team == "enemy" and c.is_alive():
			result.append(c)
	return result

func check_win() -> bool:
	for c in combatants:
		if c.team == "enemy" and c.is_alive():
			return false
	return true

func check_lose() -> bool:
	for c in combatants:
		if c.team == "ally" and c.is_alive():
			return false
	return true

func use_commander_action() -> bool:
	if commander_actions_remaining > 0:
		commander_actions_remaining -= 1
		return true
	return false
```

- [ ] **Step 4: Run tests — verify they pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/data/battle_state.gd tests/test_battle_state.gd
git commit -m "feat: battle state with turn queue, win/lose, round management"
```

---

## Task 6: Combat AI

**Files:**
- Create: `scripts/data/combat_ai.gd`
- Create: `tests/test_combat_ai.gd`

Targeting, movement decisions, ability selection.

- [ ] **Step 1: Write failing tests**

Create `tests/test_combat_ai.gd`:

```gdscript
extends GutTest

var ai: RefCounted
var grid: HexGrid

func before_each():
	ai = load("res://scripts/data/combat_ai.gd").new()
	grid = HexGrid.new()
	grid.create_battle_grid()

func _make_combatant(name: String, team: String, pos: Vector2i, priority: String = "nearest") -> CombatantData:
	var c = CombatantData.new({
		"name": name, "team": team, "targeting_priority": priority,
		"stats": {"hp": 100, "mp": 50, "attack": 10, "defense": 5, "magic": 10, "resistance": 5, "speed": 10, "accuracy": 90, "evasion": 5, "luck": 5},
		"abilities": [{"name": "Slash", "type": "physical", "power_mult": 1.0, "range": 1, "target": "enemy"}]
	})
	c.position = pos
	grid.place_combatant(pos, c)
	return c

func test_select_target_nearest():
	var ally = _make_combatant("Ally", "ally", Vector2i(-3, 0), "nearest")
	var near_enemy = _make_combatant("Near", "enemy", Vector2i(-1, 0))
	var far_enemy = _make_combatant("Far", "enemy", Vector2i(3, 0))
	var enemies = [near_enemy, far_enemy]
	var target = ai.select_target(ally, enemies, grid)
	assert_eq(target.combatant_name, "Near")

func test_select_target_weakest():
	var ally = _make_combatant("Ally", "ally", Vector2i(-3, 0), "weakest")
	var strong = _make_combatant("Strong", "enemy", Vector2i(0, 0))
	var weak = _make_combatant("Weak", "enemy", Vector2i(1, 0))
	weak.current_hp = 10
	var target = ai.select_target(ally, [strong, weak], grid)
	assert_eq(target.combatant_name, "Weak")

func test_decide_action_move_when_out_of_range():
	var ally = _make_combatant("Ally", "ally", Vector2i(-3, 0))
	var enemy = _make_combatant("Enemy", "enemy", Vector2i(3, 0))
	var action = ai.decide_action(ally, [enemy], [], grid)
	assert_eq(action.type, "move")
```

- [ ] **Step 2: Run tests — verify they fail**

- [ ] **Step 3: Implement CombatAI**

Create `scripts/data/combat_ai.gd`:

```gdscript
class_name CombatAI
extends RefCounted

func decide_action(combatant: CombatantData, enemies: Array, allies: Array, grid: HexGrid) -> Dictionary:
	var target = select_target(combatant, enemies, grid)
	if target == null:
		return {type = "wait"}

	var best_ability = select_ability(combatant, target, grid)
	var distance = grid.hex_distance(combatant.position, target.position)

	if best_ability != null and distance <= best_ability.ability_range:
		return {type = "ability", ability = best_ability, target = target, targets = get_ability_targets(combatant, best_ability, target, allies, enemies, grid)}

	var basic = AbilityData.basic_attack()
	if distance <= basic.ability_range:
		return {type = "ability", ability = basic, target = target, targets = [target]}

	var move_result = move_toward(combatant, target.position, grid)

	distance = grid.hex_distance(combatant.position, target.position)
	if best_ability != null and distance <= best_ability.ability_range:
		return {type = "move_and_ability", path = move_result.path, ability = best_ability, target = target, targets = get_ability_targets(combatant, best_ability, target, allies, enemies, grid)}
	if distance <= basic.ability_range:
		return {type = "move_and_ability", path = move_result.path, ability = basic, target = target, targets = [target]}

	return {type = "move", path = move_result.path}

func select_target(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	if enemies.size() == 0:
		return null

	match combatant.targeting_priority:
		"nearest":
			return _closest_enemy(combatant, enemies, grid)
		"weakest":
			var weakest = enemies[0]
			for e in enemies:
				if e.current_hp < weakest.current_hp:
					weakest = e
			return weakest
		"strongest":
			var strongest = enemies[0]
			for e in enemies:
				if e.get_effective_stat("attack") > strongest.get_effective_stat("attack"):
					strongest = e
			return strongest
		"protect":
			return _protect_target(combatant, enemies, grid)
		_:
			return _closest_enemy(combatant, enemies, grid)

func _closest_enemy(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	var closest = enemies[0]
	var closest_dist = grid.hex_distance(combatant.position, closest.position)
	for e in enemies:
		var dist = grid.hex_distance(combatant.position, e.position)
		if dist < closest_dist:
			closest = e
			closest_dist = dist
	return closest

func _protect_target(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	# Find lowest HP ally, then target the enemy closest to that ally
	var allies = []
	for c_pos in grid.tiles:
		var occupant = grid.tiles[c_pos].occupant
		if occupant != null and occupant.team == combatant.team and occupant != combatant and occupant.is_alive():
			allies.append(occupant)

	if allies.size() == 0:
		return _closest_enemy(combatant, enemies, grid)

	var weakest_ally = allies[0]
	for a in allies:
		if a.current_hp < weakest_ally.current_hp:
			weakest_ally = a

	return _closest_enemy(weakest_ally, enemies, grid)

func select_ability(combatant: CombatantData, target: CombatantData, grid: HexGrid) -> AbilityData:
	var distance = grid.hex_distance(combatant.position, target.position)
	var best: AbilityData = null

	for ability in combatant.abilities:
		if not combatant.can_use_ability(ability):
			continue
		if ability.ability_range >= distance or ability.target in ["self", "all_allies", "all_enemies", "adjacent_allies", "adjacent_hexes"]:
			if best == null or ability.power_mult > best.power_mult:
				best = ability
	return best

func get_ability_targets(combatant: CombatantData, ability: AbilityData, primary_target: CombatantData, allies: Array, enemies: Array, grid: HexGrid) -> Array:
	match ability.target:
		"enemy":
			return [primary_target]
		"ally":
			# For heals/buffs, find best ally target
			if ability.type == "heal":
				var most_hurt = allies[0] if allies.size() > 0 else combatant
				for a in allies:
					if a.current_hp < most_hurt.current_hp:
						most_hurt = a
				return [most_hurt]
			return [primary_target]
		"self":
			return [combatant]
		"all_allies":
			return allies + [combatant]
		"all_enemies":
			return enemies
		"adjacent_allies":
			var targets = []
			for a in allies:
				if grid.hex_distance(combatant.position, a.position) <= 1:
					targets.append(a)
			return targets
		"adjacent_hexes":
			var targets = []
			var adj = grid.get_neighbors(combatant.position)
			for hex in adj:
				if grid.tiles[hex].occupant != null and grid.tiles[hex].occupant.team != combatant.team:
					targets.append(grid.tiles[hex].occupant)
			return targets
	return [primary_target]

func move_toward(combatant: CombatantData, target_pos: Vector2i, grid: HexGrid) -> Dictionary:
	var path = grid.find_path(combatant.position, target_pos)
	if path.size() <= 1:
		return {path = [], moved = false}

	var move_allowance = combatant.movement_allowance
	# Check for bonus_move from Quick Step or similar
	var steps = mini(move_allowance, path.size() - 1)
	var actual_path = path.slice(0, steps + 1)
	var new_pos = actual_path[actual_path.size() - 1]

	if new_pos != combatant.position and not grid.is_occupied(new_pos):
		grid.remove_combatant(combatant.position)
		combatant.position = new_pos
		grid.place_combatant(new_pos, combatant)
		return {path = actual_path, moved = true}

	return {path = [], moved = false}
```

- [ ] **Step 4: Run tests — verify they pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/data/combat_ai.gd tests/test_combat_ai.gd
git commit -m "feat: combat AI with targeting, movement, ability selection"
```

---

## Task 7: Commander Actions

**Files:**
- Create: `scripts/data/commander_actions.gd`

- [ ] **Step 1: Implement CommanderActions**

Create `scripts/data/commander_actions.gd`:

```gdscript
class_name CommanderActions
extends RefCounted

func use_item_heal(target: CombatantData) -> Dictionary:
	var heal_amount = 30
	var max_hp = target.stats.get("hp", 1)
	var actual = mini(heal_amount, max_hp - target.current_hp)
	target.current_hp = mini(max_hp, target.current_hp + heal_amount)
	return {type = "heal", target = target, healed = actual}

func call_retreat() -> Dictionary:
	return {type = "retreat"}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/data/commander_actions.gd
git commit -m "feat: commander actions — heal item and retreat"
```

---

## Task 8: Hex Tile Scene

**Files:**
- Create: `scenes/battle/hex_tile.tscn`
- Create: `scripts/battle/hex_tile.gd`

Visual hex tiles with state-based coloring and click input.

- [ ] **Step 1: Create hex tile script**

Create `scripts/battle/hex_tile.gd`:

```gdscript
extends Node2D

signal hex_clicked(hex_pos: Vector2i)
signal hex_hovered(hex_pos: Vector2i)

var hex_pos: Vector2i
var hex_state: String = "empty"  # "empty", "ally", "enemy", "ally_zone", "enemy_zone", "highlighted", "selected"

@onready var polygon: Polygon2D = $Polygon2D
@onready var area: Area2D = $Area2D

const COLORS = {
	"empty": Color(0.2, 0.2, 0.25),
	"ally": Color(0.2, 0.5, 0.2),
	"enemy": Color(0.5, 0.2, 0.2),
	"ally_zone": Color(0.15, 0.3, 0.15),
	"enemy_zone": Color(0.3, 0.15, 0.15),
	"highlighted": Color(0.4, 0.4, 0.2),
	"selected": Color(0.3, 0.3, 0.6),
}

func setup(pos: Vector2i, pixel_pos: Vector2) -> void:
	hex_pos = pos
	position = pixel_pos

func set_state(new_state: String) -> void:
	hex_state = new_state
	if polygon:
		polygon.color = COLORS.get(new_state, COLORS["empty"])

func _create_hex_polygon() -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cos(angle), sin(angle)) * 28.0)
	return points

func _ready() -> void:
	if not polygon:
		polygon = Polygon2D.new()
		add_child(polygon)
	polygon.polygon = _create_hex_polygon()
	polygon.color = COLORS["empty"]

	if not area:
		area = Area2D.new()
		var collision = CollisionPolygon2D.new()
		collision.polygon = polygon.polygon
		area.add_child(collision)
		add_child(area)
		area.input_event.connect(_on_input_event)
		area.mouse_entered.connect(_on_mouse_entered)

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hex_clicked.emit(hex_pos)

func _on_mouse_entered() -> void:
	hex_hovered.emit(hex_pos)
```

- [ ] **Step 2: Create hex tile scene**

Create `scenes/battle/hex_tile.tscn` via script or in editor — a Node2D root with the `hex_tile.gd` script attached. The script creates its own Polygon2D and Area2D children in `_ready()`.

Minimal `.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/battle/hex_tile.gd" id="1"]
[node name="HexTile" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Commit**

```bash
git add scripts/battle/hex_tile.gd scenes/battle/hex_tile.tscn
git commit -m "feat: hex tile scene with state coloring and click input"
```

---

## Task 9: Character Sprite Scene

**Files:**
- Create: `scenes/battle/character_sprite.tscn`
- Create: `scripts/battle/character_sprite.gd`

Placeholder character visuals with HP bar and animations.

- [ ] **Step 1: Create character sprite script**

Create `scripts/battle/character_sprite.gd`:

```gdscript
extends Node2D

var combatant: CombatantData

@onready var body: Polygon2D = $Body
@onready var hp_bar_bg: ColorRect = $HPBarBG
@onready var hp_bar: ColorRect = $HPBar
@onready var name_label: Label = $NameLabel

func setup(data: CombatantData, pixel_pos: Vector2) -> void:
	combatant = data
	position = pixel_pos
	_update_visuals()

func _ready() -> void:
	_create_visuals()

func _create_visuals() -> void:
	if not body:
		body = Polygon2D.new()
		body.name = "Body"
		var points: PackedVector2Array = []
		for i in range(12):
			var angle = deg_to_rad(30.0 * i)
			points.append(Vector2(cos(angle), sin(angle)) * 14.0)
		body.polygon = points
		add_child(body)

	if not hp_bar_bg:
		hp_bar_bg = ColorRect.new()
		hp_bar_bg.name = "HPBarBG"
		hp_bar_bg.size = Vector2(30, 4)
		hp_bar_bg.position = Vector2(-15, -22)
		hp_bar_bg.color = Color(0.3, 0.1, 0.1)
		add_child(hp_bar_bg)

	if not hp_bar:
		hp_bar = ColorRect.new()
		hp_bar.name = "HPBar"
		hp_bar.size = Vector2(30, 4)
		hp_bar.position = Vector2(-15, -22)
		hp_bar.color = Color(0.2, 0.8, 0.2)
		add_child(hp_bar)

	if not name_label:
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-20, -36)
		name_label.size = Vector2(40, 14)
		name_label.add_theme_font_size_override("font_size", 10)
		add_child(name_label)

func _update_visuals() -> void:
	if combatant == null:
		return
	body.color = Color(0.3, 0.7, 0.3) if combatant.team == "ally" else Color(0.7, 0.3, 0.3)
	name_label.text = combatant.combatant_name
	_update_hp_bar()

func _update_hp_bar() -> void:
	if combatant == null:
		return
	var ratio = float(combatant.current_hp) / float(combatant.stats.get("hp", 1))
	hp_bar.size.x = 30.0 * ratio
	if ratio > 0.5:
		hp_bar.color = Color(0.2, 0.8, 0.2)
	elif ratio > 0.25:
		hp_bar.color = Color(0.8, 0.8, 0.2)
	else:
		hp_bar.color = Color(0.8, 0.2, 0.2)

func animate_move(path: Array[Vector2], duration: float = 0.3) -> void:
	var tween = create_tween()
	for pixel_pos in path:
		tween.tween_property(self, "position", pixel_pos, duration / path.size())
	await tween.finished

func animate_attack() -> void:
	var tween = create_tween()
	var orig = position
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	await tween.finished

func animate_damage() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween.finished
	_update_hp_bar()

func animate_heal() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 1, 0.3), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween.finished
	_update_hp_bar()

func animate_death() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

func refresh() -> void:
	_update_visuals()
```

- [ ] **Step 2: Create character sprite scene**

Minimal `scenes/battle/character_sprite.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/battle/character_sprite.gd" id="1"]
[node name="CharacterSprite" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 3: Commit**

```bash
git add scripts/battle/character_sprite.gd scenes/battle/character_sprite.tscn
git commit -m "feat: character sprite with HP bar and combat animations"
```

---

## Task 10: Battle Manager + Battle Scene

**Files:**
- Create: `scripts/battle/battle_manager.gd`
- Create: `scenes/battle/battle.tscn`

The orchestrator. Ties data layer to scene layer, runs the turn loop.

- [ ] **Step 1: Create BattleManager**

Create `scripts/battle/battle_manager.gd`:

```gdscript
extends Node

signal turn_started(combatant: CombatantData)
signal action_resolved(results: Array)
signal round_ended
signal battle_won
signal battle_lost
signal phase_changed(phase: String)

enum Phase { PRE_FIGHT, COMBAT, POST_COMBAT }

var phase: Phase = Phase.PRE_FIGHT
var grid: HexGrid
var state: BattleState
var ai: CombatAI
var resolver: CombatResolver
var commander: CommanderActions
var speed_scale: float = 1.0
var paused: bool = false
var waiting_for_commander: bool = false

var hex_tile_scene = preload("res://scenes/battle/hex_tile.tscn")
var character_sprite_scene = preload("res://scenes/battle/character_sprite.tscn")
var hex_tiles: Dictionary = {}  # Vector2i -> HexTile node
var character_sprites: Dictionary = {}  # CombatantData -> CharacterSprite node

@onready var grid_container: Node2D = $GridContainer
@onready var sprite_container: Node2D = $SpriteContainer

func _ready() -> void:
	grid = HexGrid.new()
	state = BattleState.new()
	ai = CombatAI.new()
	resolver = CombatResolver.new()
	commander = CommanderActions.new()
	grid.create_battle_grid()
	_render_grid()

func _render_grid() -> void:
	for hex_pos in grid.tiles:
		var tile_node = hex_tile_scene.instantiate()
		var pixel_pos = grid.axial_to_pixel(hex_pos)
		grid_container.add_child(tile_node)
		tile_node.setup(hex_pos, pixel_pos)
		tile_node.hex_clicked.connect(_on_hex_clicked)
		hex_tiles[hex_pos] = tile_node
		# Color zones
		match grid.tile_zones.get(hex_pos, HexGrid.Zone.NEUTRAL):
			HexGrid.Zone.ALLY:
				tile_node.set_state("ally_zone")
			HexGrid.Zone.ENEMY:
				tile_node.set_state("enemy_zone")

func start_combat(allies: Array[CombatantData], encounter: EncounterData) -> void:
	# Place enemies from encounter data
	for enemy_dict in encounter.enemies:
		var enemy = CombatantData.new(enemy_dict)
		state.add_combatant(enemy)
		grid.place_combatant(enemy.position, enemy)
		_spawn_sprite(enemy)

	# Add allies (already placed during pre-fight)
	for ally in allies:
		state.add_combatant(ally)
		grid.place_combatant(ally.position, ally)
		_spawn_sprite(ally)

	phase = Phase.COMBAT
	phase_changed.emit("combat")
	_run_combat()

func _spawn_sprite(combatant: CombatantData) -> void:
	var sprite = character_sprite_scene.instantiate()
	sprite_container.add_child(sprite)
	sprite.setup(combatant, grid.axial_to_pixel(combatant.position))
	character_sprites[combatant] = sprite

func _run_combat() -> void:
	while phase == Phase.COMBAT:
		state.build_turn_queue()
		round_ended.emit()

		while not state.is_round_over() and phase == Phase.COMBAT:
			if paused or waiting_for_commander:
				await get_tree().create_timer(0.1).timeout
				continue

			var combatant = state.advance_turn()
			if combatant == null or not combatant.is_alive():
				continue

			turn_started.emit(combatant)
			await _execute_turn(combatant)

			state.remove_dead_from_queue()
			if state.check_win():
				phase = Phase.POST_COMBAT
				battle_won.emit()
				return
			if state.check_lose():
				phase = Phase.POST_COMBAT
				battle_lost.emit()
				return

			await get_tree().create_timer(0.2 / speed_scale).timeout

func _execute_turn(combatant: CombatantData) -> void:
	var enemies = state.get_enemies() if combatant.team == "ally" else state.get_allies()
	var allies_list = state.get_allies() if combatant.team == "ally" else state.get_enemies()
	var action = ai.decide_action(combatant, enemies, allies_list, grid)

	match action.type:
		"move":
			await _animate_move(combatant, action.path)
		"ability":
			var results = resolver.resolve_ability(combatant, action.targets, action.ability, grid)
			await _animate_ability(combatant, results, action.ability)
			action_resolved.emit(results)
		"move_and_ability":
			await _animate_move(combatant, action.path)
			var results = resolver.resolve_ability(combatant, action.targets, action.ability, grid)
			await _animate_ability(combatant, results, action.ability)
			action_resolved.emit(results)

func _animate_move(combatant: CombatantData, path: Array) -> void:
	var sprite = character_sprites.get(combatant)
	if sprite == null or path.size() <= 1:
		return
	var pixel_path: Array[Vector2] = []
	for hex in path:
		pixel_path.append(grid.axial_to_pixel(hex))
	await sprite.animate_move(pixel_path, 0.4 / speed_scale)
	# Update tile states
	_refresh_tile_states()

func _animate_ability(combatant: CombatantData, results: Array, ability: AbilityData) -> void:
	var attacker_sprite = character_sprites.get(combatant)
	if attacker_sprite:
		await attacker_sprite.animate_attack()

	for result in results:
		var target = result.get("target")
		var target_sprite = character_sprites.get(target)
		if target_sprite == null:
			continue

		if result.has("damage") and result.damage > 0:
			await target_sprite.animate_damage()
		elif result.has("healed") and result.healed > 0:
			await target_sprite.animate_heal()
		elif result.has("buffed") or result.has("debuffed"):
			await target_sprite.animate_heal()  # reuse green flash for buffs

		if result.get("kill", false):
			_remove_dead_sprite(target)

	_refresh_all_sprites()

func _remove_dead_sprite(combatant: CombatantData) -> void:
	var sprite = character_sprites.get(combatant)
	if sprite:
		await sprite.animate_death()
		character_sprites.erase(combatant)
		grid.remove_combatant(combatant.position)

func _refresh_tile_states() -> void:
	for hex_pos in hex_tiles:
		var tile = hex_tiles[hex_pos]
		if grid.tiles[hex_pos].occupied:
			var occupant = grid.tiles[hex_pos].occupant
			tile.set_state("ally" if occupant.team == "ally" else "enemy")
		else:
			match grid.tile_zones.get(hex_pos, HexGrid.Zone.NEUTRAL):
				HexGrid.Zone.ALLY:
					tile.set_state("ally_zone")
				HexGrid.Zone.ENEMY:
					tile.set_state("enemy_zone")
				_:
					tile.set_state("empty")

func _refresh_all_sprites() -> void:
	for combatant in character_sprites:
		character_sprites[combatant].refresh()

func _on_hex_clicked(hex_pos: Vector2i) -> void:
	# Handled by PreFightUI during PRE_FIGHT phase
	pass

func commander_heal(target: CombatantData) -> void:
	if state.use_commander_action():
		var result = commander.use_item_heal(target)
		var sprite = character_sprites.get(target)
		if sprite:
			await sprite.animate_heal()
		_refresh_all_sprites()
		waiting_for_commander = false

func commander_retreat() -> void:
	if state.use_commander_action():
		phase = Phase.PRE_FIGHT
		phase_changed.emit("pre_fight")
		waiting_for_commander = false

func set_speed(scale: float) -> void:
	speed_scale = scale

func toggle_pause() -> void:
	paused = not paused
```

- [ ] **Step 2: Create battle scene**

Create `scenes/battle/battle.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/battle/battle_manager.gd" id="1"]
[node name="Battle" type="Node"]
script = ExtResource("1")
[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(0, 0)
[node name="GridContainer" type="Node2D" parent="."]
[node name="SpriteContainer" type="Node2D" parent="."]
[node name="UI" type="CanvasLayer" parent="."]
```

- [ ] **Step 3: Commit**

```bash
git add scripts/battle/battle_manager.gd scenes/battle/battle.tscn
git commit -m "feat: battle manager orchestrating data and scene layers"
```

---

## Task 11: Pre-Fight UI

**Files:**
- Create: `scripts/battle/pre_fight_ui.gd`
- Create: `scenes/battle/ui/pre_fight_ui.tscn`

Placement screen: drag characters onto hex grid, set targeting priority and ability loadouts.

- [ ] **Step 1: Create PreFightUI script**

Create `scripts/battle/pre_fight_ui.gd`:

```gdscript
extends Control

signal setup_complete(allies: Array)

var ally_roster: Array[CombatantData] = []
var placed_allies: Dictionary = {}  # Vector2i -> CombatantData
var selected_ally: CombatantData = null
var battle_manager: Node

@onready var roster_list: VBoxContainer = $RosterPanel/VBoxContainer
@onready var start_button: Button = $StartButton
@onready var info_panel: VBoxContainer = $InfoPanel/VBoxContainer

func setup(roster: Array[Dictionary], manager: Node) -> void:
	battle_manager = manager
	for data in roster:
		var combatant = CombatantData.new(data)
		ally_roster.append(combatant)
	_build_roster_ui()
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)

func _build_roster_ui() -> void:
	for child in roster_list.get_children():
		child.queue_free()

	for ally in ally_roster:
		var btn = Button.new()
		btn.text = ally.combatant_name
		btn.pressed.connect(_on_ally_selected.bind(ally))
		var is_placed = ally in placed_allies.values()
		if is_placed:
			btn.modulate = Color(0.5, 0.5, 0.5)
		roster_list.add_child(btn)

func _on_ally_selected(ally: CombatantData) -> void:
	selected_ally = ally
	_show_ally_info(ally)

func _show_ally_info(ally: CombatantData) -> void:
	for child in info_panel.get_children():
		child.queue_free()

	var name_label = Label.new()
	name_label.text = ally.combatant_name
	info_panel.add_child(name_label)

	var stats_label = Label.new()
	stats_label.text = "HP:%d ATK:%d DEF:%d SPD:%d" % [
		ally.stats.get("hp", 0), ally.stats.get("attack", 0),
		ally.stats.get("defense", 0), ally.stats.get("speed", 0)]
	info_panel.add_child(stats_label)

	# Targeting priority dropdown
	var priority_label = Label.new()
	priority_label.text = "Targeting:"
	info_panel.add_child(priority_label)

	var priority_dropdown = OptionButton.new()
	priority_dropdown.add_item("Nearest")
	priority_dropdown.add_item("Weakest")
	priority_dropdown.add_item("Strongest")
	priority_dropdown.add_item("Protect")
	var priorities = ["nearest", "weakest", "strongest", "protect"]
	var idx = priorities.find(ally.targeting_priority)
	if idx >= 0:
		priority_dropdown.selected = idx
	priority_dropdown.item_selected.connect(func(i): ally.targeting_priority = priorities[i])
	info_panel.add_child(priority_dropdown)

	# Ability list
	var abilities_label = Label.new()
	abilities_label.text = "Abilities:"
	info_panel.add_child(abilities_label)
	for ability in ally.abilities:
		var ab_label = Label.new()
		ab_label.text = "  %s (range:%d, MP:%d)" % [ability.name, ability.ability_range, ability.mp_cost]
		info_panel.add_child(ab_label)

func on_hex_clicked(hex_pos: Vector2i) -> void:
	if selected_ally == null:
		return
	var grid = battle_manager.grid
	if grid.tile_zones.get(hex_pos) != HexGrid.Zone.ALLY:
		return
	if grid.is_occupied(hex_pos):
		return

	# Remove from previous position if already placed
	for pos in placed_allies:
		if placed_allies[pos] == selected_ally:
			placed_allies.erase(pos)
			break

	placed_allies[hex_pos] = selected_ally
	selected_ally.position = hex_pos
	selected_ally = null
	_build_roster_ui()

	start_button.disabled = placed_allies.size() < ally_roster.size()

func _on_start_pressed() -> void:
	var allies: Array[CombatantData] = []
	for pos in placed_allies:
		allies.append(placed_allies[pos])
	setup_complete.emit(allies)
```

- [ ] **Step 2: Create pre-fight UI scene**

Create `scenes/battle/ui/pre_fight_ui.tscn` — a Control node with:
- `RosterPanel` (PanelContainer on the left with VBoxContainer)
- `InfoPanel` (PanelContainer on the right with VBoxContainer)
- `StartButton` (Button at the bottom, text "Start Battle")

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/battle/pre_fight_ui.gd" id="1"]
[node name="PreFightUI" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
[node name="RosterPanel" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 10.0
offset_top = 10.0
offset_right = 200.0
offset_bottom = 400.0
[node name="VBoxContainer" type="VBoxContainer" parent="RosterPanel"]
layout_mode = 2
[node name="InfoPanel" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 1060.0
offset_top = 10.0
offset_right = 1270.0
offset_bottom = 400.0
[node name="VBoxContainer" type="VBoxContainer" parent="InfoPanel"]
layout_mode = 2
[node name="StartButton" type="Button" parent="."]
layout_mode = 0
offset_left = 540.0
offset_top = 650.0
offset_right = 740.0
offset_bottom = 690.0
text = "Start Battle"
```

- [ ] **Step 3: Commit**

```bash
git add scripts/battle/pre_fight_ui.gd scenes/battle/ui/pre_fight_ui.tscn
git commit -m "feat: pre-fight UI with placement, targeting, and ability info"
```

---

## Task 12: Battle UI (In-Combat)

**Files:**
- Create: `scripts/battle/battle_ui.gd`
- Create: `scenes/battle/ui/battle_ui.tscn`

Turn order display, commander actions, speed controls, win/lose popup.

- [ ] **Step 1: Create BattleUI script**

Create `scripts/battle/battle_ui.gd`:

```gdscript
extends Control

signal commander_heal_requested(target: CombatantData)
signal commander_retreat_requested
signal speed_changed(scale: float)
signal pause_toggled

var battle_manager: Node
var selecting_heal_target: bool = false

@onready var turn_order: HBoxContainer = $TurnOrder
@onready var commander_btn: Button = $CommanderButton
@onready var speed_btn: Button = $SpeedButton
@onready var pause_btn: Button = $PauseButton
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Label
@onready var retry_btn: Button = $ResultPanel/RetryButton

var current_speed_idx: int = 0
var speed_options: Array[float] = [1.0, 2.0, 4.0]

func setup(manager: Node) -> void:
	battle_manager = manager
	commander_btn.pressed.connect(_on_commander_pressed)
	speed_btn.pressed.connect(_on_speed_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	result_panel.visible = false
	_update_commander_button()

func update_turn_order(queue: Array) -> void:
	for child in turn_order.get_children():
		child.queue_free()
	for combatant in queue:
		var label = Label.new()
		label.text = combatant.combatant_name
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if combatant.team == "ally" else Color(0.8, 0.3, 0.3))
		turn_order.add_child(label)

func show_win() -> void:
	result_panel.visible = true
	result_label.text = "VICTORY!"
	retry_btn.text = "Continue"

func show_lose() -> void:
	result_panel.visible = true
	result_label.text = "DEFEATED"
	retry_btn.text = "Retry"

func _on_commander_pressed() -> void:
	if battle_manager.state.commander_actions_remaining <= 0:
		return
	# Show a simple choice: Heal or Retreat
	var dialog = AcceptDialog.new()
	dialog.title = "Commander Action"
	dialog.dialog_text = "Choose action:"

	var heal_btn = Button.new()
	heal_btn.text = "Heal Ally (30 HP)"
	heal_btn.pressed.connect(func():
		selecting_heal_target = true
		battle_manager.waiting_for_commander = true
		dialog.queue_free()
	)

	var retreat_btn = Button.new()
	retreat_btn.text = "Retreat"
	retreat_btn.pressed.connect(func():
		commander_retreat_requested.emit()
		dialog.queue_free()
	)

	dialog.add_child(heal_btn)
	dialog.add_child(retreat_btn)
	add_child(dialog)
	dialog.popup_centered()

func on_character_clicked(combatant: CombatantData) -> void:
	if selecting_heal_target and combatant.team == "ally":
		selecting_heal_target = false
		commander_heal_requested.emit(combatant)

func _update_commander_button() -> void:
	if battle_manager and battle_manager.state:
		commander_btn.disabled = battle_manager.state.commander_actions_remaining <= 0
		commander_btn.text = "Commander (%d)" % battle_manager.state.commander_actions_remaining

func _on_speed_pressed() -> void:
	current_speed_idx = (current_speed_idx + 1) % speed_options.size()
	var new_speed = speed_options[current_speed_idx]
	speed_btn.text = "%dx" % int(new_speed)
	speed_changed.emit(new_speed)

func _on_pause_pressed() -> void:
	pause_toggled.emit()
	pause_btn.text = "Resume" if battle_manager.paused else "Pause"

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 2: Create battle UI scene**

Create `scenes/battle/ui/battle_ui.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/battle/battle_ui.gd" id="1"]
[node name="BattleUI" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
[node name="TurnOrder" type="HBoxContainer" parent="."]
layout_mode = 0
offset_left = 10.0
offset_top = 10.0
offset_right = 800.0
offset_bottom = 30.0
[node name="CommanderButton" type="Button" parent="."]
layout_mode = 0
offset_left = 10.0
offset_top = 650.0
offset_right = 160.0
offset_bottom = 690.0
text = "Commander (1)"
[node name="SpeedButton" type="Button" parent="."]
layout_mode = 0
offset_left = 1160.0
offset_top = 650.0
offset_right = 1210.0
offset_bottom = 690.0
text = "1x"
[node name="PauseButton" type="Button" parent="."]
layout_mode = 0
offset_left = 1220.0
offset_top = 650.0
offset_right = 1270.0
offset_bottom = 690.0
text = "Pause"
[node name="ResultPanel" type="PanelContainer" parent="."]
layout_mode = 0
offset_left = 440.0
offset_top = 250.0
offset_right = 840.0
offset_bottom = 450.0
[node name="Label" type="Label" parent="ResultPanel"]
layout_mode = 2
horizontal_alignment = 1
text = "VICTORY!"
[node name="RetryButton" type="Button" parent="ResultPanel"]
layout_mode = 2
text = "Continue"
```

- [ ] **Step 3: Commit**

```bash
git add scripts/battle/battle_ui.gd scenes/battle/ui/battle_ui.tscn
git commit -m "feat: battle UI with turn order, commander actions, speed controls"
```

---

## Task 13: Integration — Wire Everything Together

**Files:**
- Modify: `scripts/battle/battle_manager.gd`
- Modify: `scenes/battle/battle.tscn`

Connect PreFightUI and BattleUI to BattleManager. Wire up the full flow: pre-fight → combat → post-combat.

- [ ] **Step 1: Update battle scene to include UI scenes**

Update `scenes/battle/battle.tscn` to instance PreFightUI and BattleUI under the UI CanvasLayer.

- [ ] **Step 2: Add initialization flow to BattleManager**

Add to `battle_manager.gd` `_ready()`:

```gdscript
func _ready() -> void:
	grid = HexGrid.new()
	state = BattleState.new()
	ai = CombatAI.new()
	resolver = CombatResolver.new()
	commander = CommanderActions.new()
	grid.create_battle_grid()
	_render_grid()

	# Setup Pre-Fight UI
	var pre_fight_ui = $UI/PreFightUI
	pre_fight_ui.setup(EncounterData.ally_roster(), self)
	pre_fight_ui.setup_complete.connect(_on_setup_complete)

	# Connect hex clicks to pre-fight during placement
	for hex_pos in hex_tiles:
		hex_tiles[hex_pos].hex_clicked.connect(pre_fight_ui.on_hex_clicked)

	# Setup Battle UI (hidden until combat)
	var battle_ui = $UI/BattleUI
	battle_ui.setup(self)
	battle_ui.visible = false
	battle_ui.commander_heal_requested.connect(commander_heal)
	battle_ui.commander_retreat_requested.connect(commander_retreat)
	battle_ui.speed_changed.connect(set_speed)
	battle_ui.pause_toggled.connect(toggle_pause)
	turn_started.connect(func(c): battle_ui.update_turn_order(state.turn_queue))
	battle_won.connect(battle_ui.show_win)
	battle_lost.connect(battle_ui.show_lose)

func _on_setup_complete(allies: Array) -> void:
	$UI/PreFightUI.visible = false
	$UI/BattleUI.visible = true
	var encounter = EncounterData.test_encounter()
	var typed_allies: Array[CombatantData] = []
	for a in allies:
		typed_allies.append(a)
	start_combat(typed_allies, encounter)
```

- [ ] **Step 3: Test the full flow manually**

Run the project in Godot:
1. Pre-fight screen appears with hex grid and roster
2. Click an ally name, then click an ally-zone hex to place them
3. Set targeting priorities
4. Place all 3 allies, click "Start Battle"
5. Combat runs automatically — characters move, attack, take damage
6. Commander action button works
7. Speed/pause controls work
8. Win or lose screen appears

- [ ] **Step 4: Fix any issues found during manual testing**

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: full battle MVP — pre-fight to combat to win/lose"
```

- [ ] **Step 6: Push to GitHub**

```bash
git push
```

---

## Summary

| Task | What It Builds | Estimated Steps |
|------|----------------|-----------------|
| 1 | Project setup | 5 |
| 2 | Hex grid data layer | 9 |
| 3 | Combatant + ability + encounter data | 4 |
| 4 | Combat resolver | 5 |
| 5 | Battle state | 5 |
| 6 | Combat AI | 5 |
| 7 | Commander actions | 2 |
| 8 | Hex tile scene | 3 |
| 9 | Character sprite scene | 3 |
| 10 | Battle manager + battle scene | 3 |
| 11 | Pre-fight UI | 3 |
| 12 | Battle UI | 3 |
| 13 | Integration | 6 |
| **Total** | | **56 steps** |
