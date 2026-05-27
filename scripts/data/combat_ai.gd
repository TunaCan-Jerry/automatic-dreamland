class_name CombatAI
extends RefCounted


## Decide what action a combatant should take on their turn.
## Returns a Dictionary describing the chosen action.
func decide_action(combatant: CombatantData, enemies: Array, allies: Array, grid: HexGrid) -> Dictionary:
	var target: CombatantData = select_target(combatant, enemies, grid)

	if target == null:
		return {type = "wait"}

	var ability: AbilityData = select_ability(combatant, target, grid)
	var dist: int = grid.hex_distance(combatant.position, target.position)

	# Check if a selected ability is in range.
	if ability != null and dist <= ability.ability_range:
		var targets: Array = get_ability_targets(combatant, ability, target, allies, enemies, grid)
		return {type = "ability", ability = ability, target = target, targets = targets}

	# Check if in range for a basic attack (range 1).
	if dist <= 1:
		var basic: AbilityData = AbilityData.basic_attack()
		return {type = "ability", ability = basic, target = target, targets = [target]}

	# Move toward target, then re-check range.
	var move_result: Dictionary = move_combatant_toward(combatant, target.position, grid)
	var new_dist: int = grid.hex_distance(combatant.position, target.position)

	# Re-select ability after moving (position changed).
	var ability_after: AbilityData = select_ability(combatant, target, grid)

	if ability_after != null and new_dist <= ability_after.ability_range:
		var targets: Array = get_ability_targets(combatant, ability_after, target, allies, enemies, grid)
		return {
			type = "move_and_ability",
			path = move_result.path,
			ability = ability_after,
			target = target,
			targets = targets,
		}

	if new_dist <= 1:
		var basic: AbilityData = AbilityData.basic_attack()
		return {
			type = "move_and_ability",
			path = move_result.path,
			ability = basic,
			target = target,
			targets = [target],
		}

	return {type = "move", path = move_result.path}


# ---------------------------------------------------------------------------
# Targeting
# ---------------------------------------------------------------------------

## Select the best target from enemies based on the combatant's targeting priority.
func select_target(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	var alive_enemies: Array = enemies.filter(func(e): return e.is_alive())
	if alive_enemies.is_empty():
		return null

	match combatant.targeting_priority:
		"nearest":
			return _target_nearest(combatant, alive_enemies, grid)
		"weakest":
			return _target_weakest(alive_enemies)
		"strongest":
			return _target_strongest(alive_enemies)
		"protect":
			return _target_protect(combatant, alive_enemies, grid)
		_:
			return _target_nearest(combatant, alive_enemies, grid)


func _target_nearest(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	var best: CombatantData = null
	var best_dist: int = 999999
	for e in enemies:
		var d: int = grid.hex_distance(combatant.position, e.position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


func _target_weakest(enemies: Array) -> CombatantData:
	var best: CombatantData = null
	var best_hp: int = 999999
	for e in enemies:
		if e.current_hp < best_hp:
			best_hp = e.current_hp
			best = e
	return best


func _target_strongest(enemies: Array) -> CombatantData:
	var best: CombatantData = null
	var best_atk: int = -1
	for e in enemies:
		var atk: int = e.get_effective_stat("attack")
		if atk > best_atk:
			best_atk = atk
			best = e
	return best


## "protect" strategy: find the lowest-HP ally on the grid, then target the
## enemy that is closest to that ally.
func _target_protect(combatant: CombatantData, enemies: Array, grid: HexGrid) -> CombatantData:
	# Scan grid occupants for allies on the same team.
	var lowest_ally: CombatantData = null
	var lowest_hp: int = 999999
	for hex in grid.tiles:
		var tile = grid.tiles[hex]
		if tile[&"occupied"] and tile[&"occupant"] != null:
			var occ = tile[&"occupant"]
			if occ is CombatantData and occ.team == combatant.team and occ.is_alive():
				if occ.current_hp < lowest_hp:
					lowest_hp = occ.current_hp
					lowest_ally = occ

	if lowest_ally == null:
		return _target_nearest(combatant, enemies, grid)

	# Target the enemy closest to that ally.
	var best: CombatantData = null
	var best_dist: int = 999999
	for e in enemies:
		var d: int = grid.hex_distance(lowest_ally.position, e.position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


# ---------------------------------------------------------------------------
# Ability Selection
# ---------------------------------------------------------------------------

## Select the highest power_mult ability the combatant can use against the target.
## Returns null if no ability is usable.
func select_ability(combatant: CombatantData, target: CombatantData, grid: HexGrid) -> AbilityData:
	var best: AbilityData = null
	var best_power: float = -1.0
	var dist: int = grid.hex_distance(combatant.position, target.position)

	for ability in combatant.abilities:
		if not combatant.can_use_ability(ability):
			continue

		# An ability is eligible if the target is in range or it targets self/aoe.
		var in_range: bool = dist <= ability.ability_range
		var self_or_aoe: bool = ability.target in ["self", "all_allies", "all_enemies",
				"adjacent_allies", "adjacent_hexes"]

		if not in_range and not self_or_aoe:
			continue

		if ability.power_mult > best_power:
			best_power = ability.power_mult
			best = ability

	return best


# ---------------------------------------------------------------------------
# Target Resolution
# ---------------------------------------------------------------------------

## Resolve the full list of targets for an ability given the primary target.
func get_ability_targets(
		combatant: CombatantData,
		ability: AbilityData,
		primary_target: CombatantData,
		allies: Array,
		enemies: Array,
		grid: HexGrid) -> Array:

	match ability.target:
		"enemy":
			return [primary_target]

		"ally":
			if ability.type == "heal":
				# Find the most injured ally (largest HP deficit).
				var best_ally: CombatantData = null
				var best_deficit: int = -1
				for a in allies:
					if not a.is_alive():
						continue
					var deficit: int = a.stats.get("hp", 0) - a.current_hp
					if deficit > best_deficit:
						best_deficit = deficit
						best_ally = a
				# Include self in healing consideration.
				var self_deficit: int = combatant.stats.get("hp", 0) - combatant.current_hp
				if self_deficit > best_deficit:
					best_ally = combatant
				return [best_ally] if best_ally != null else [combatant]
			return [primary_target]

		"self":
			return [combatant]

		"all_allies":
			var result: Array = allies.filter(func(a): return a.is_alive())
			result.append(combatant)
			return result

		"all_enemies":
			return enemies.filter(func(e): return e.is_alive())

		"adjacent_allies":
			var result: Array = []
			for a in allies:
				if a.is_alive() and grid.hex_distance(combatant.position, a.position) <= 1:
					result.append(a)
			return result

		"adjacent_hexes":
			# Grid neighbors occupied by enemies of the caster.
			var result: Array = []
			for neighbor in grid.get_neighbors(combatant.position):
				if grid.is_occupied(neighbor):
					var occ = grid.tiles[neighbor][&"occupant"]
					if occ is CombatantData and occ.team != combatant.team and occ.is_alive():
						result.append(occ)
			return result

		_:
			return [primary_target]


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Move combatant up to movement_allowance steps along the path toward target_pos.
## Updates grid occupancy and combatant.position.
## Returns {path: Array[Vector2i], moved: bool}
func move_combatant_toward(combatant: CombatantData, target_pos: Vector2i, grid: HexGrid) -> Dictionary:
	var full_path: Array[Vector2i] = grid.find_path(combatant.position, target_pos)

	if full_path.size() <= 1:
		# No movement possible (already adjacent or no path).
		return {path = [], moved = false}

	# full_path[0] is the current position; skip it.
	# We can take at most movement_allowance steps, but never land on the target's tile.
	var steps: int = mini(combatant.movement_allowance, full_path.size() - 1)

	# Don't walk onto the target's occupied tile (stop one step short if needed).
	var destination: Vector2i = full_path[steps]
	while steps > 1 and grid.is_occupied(destination) and destination != combatant.position:
		steps -= 1
		destination = full_path[steps]

	if destination == combatant.position:
		return {path = [], moved = false}

	var traveled_path: Array[Vector2i] = []
	for i in range(steps + 1):
		traveled_path.append(full_path[i])

	# Update grid and combatant position.
	grid.remove_combatant(combatant.position)
	combatant.position = destination
	grid.place_combatant(destination, combatant)

	return {path = traveled_path, moved = true}
