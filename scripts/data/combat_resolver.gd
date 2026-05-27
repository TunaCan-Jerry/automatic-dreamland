class_name CombatResolver
extends RefCounted


func resolve_attack(attacker: CombatantData, defender: CombatantData, ability: AbilityData) -> Dictionary:
	# Hit check
	var hit_chance: int = clampi(
		attacker.get_effective_stat("accuracy") - defender.get_effective_stat("evasion"),
		5, 99
	)
	var roll: int = randi() % 100
	if roll >= hit_chance:
		return {hit = false, damage = 0, crit = false, kill = false, status_applied = false}

	# Damage calculation
	var damage: int
	if ability.type == "magic":
		damage = maxi(1,
			int(attacker.get_effective_stat("magic") * ability.power_mult)
			- defender.get_effective_stat("resistance")
		)
	else:
		damage = maxi(1,
			int(attacker.get_effective_stat("attack") * ability.power_mult)
			- defender.get_effective_stat("defense")
		)

	# Crit check
	var crit_chance: int = clampi(attacker.get_effective_stat("luck") * 2, 1, 30)
	var crit: bool = (randi() % 100) < crit_chance
	if crit:
		damage = int(damage * 1.5)

	# Apply damage
	defender.current_hp = maxi(0, defender.current_hp - damage)
	var killed: bool = not defender.is_alive()

	# Apply status effect if defender survived and ability has one
	var status_applied: bool = false
	if not killed and not ability.status_effect.is_empty():
		var effect := {
			stat = ability.status_effect.get("stat", ""),
			amount = ability.status_effect.get("amount", 0),
			remaining_turns = ability.status_effect.get("duration", 1),
		}
		defender.status_effects.append(effect)
		status_applied = true

	return {
		hit = true,
		damage = damage,
		crit = crit,
		kill = killed,
		status_applied = status_applied,
	}


func resolve_heal(caster: CombatantData, target: CombatantData, ability: AbilityData) -> Dictionary:
	var heal_amount: int = int(caster.get_effective_stat("magic") * ability.power_mult)
	var max_hp: int = target.stats.get("hp", 0)
	var actual: int = mini(heal_amount, max_hp - target.current_hp)
	target.current_hp += actual
	return {healed = actual}


func resolve_buff(caster: CombatantData, target: CombatantData, ability: AbilityData) -> Dictionary:
	if ability.status_effect.is_empty():
		return {buffed = false, stat = "", amount = 0}

	var effect := {
		stat = ability.status_effect.get("stat", ""),
		amount = ability.status_effect.get("amount", 0),
		remaining_turns = ability.status_effect.get("duration", 1),
	}
	target.status_effects.append(effect)
	return {buffed = true, stat = effect.stat, amount = effect.amount}


func resolve_ability(
	attacker: CombatantData,
	targets: Array,
	ability: AbilityData,
	grid: HexGrid
) -> Array[Dictionary]:
	# Deduct MP cost
	attacker.current_mp = maxi(0, attacker.current_mp - ability.mp_cost)

	# Set cooldown
	if ability.cooldown > 0:
		attacker.cooldowns[ability.name] = ability.cooldown

	var results: Array[Dictionary] = []

	for target in targets:
		var result: Dictionary = {}

		match ability.type:
			"physical", "magic":
				result = resolve_attack(attacker, target, ability)
				# Push if applicable and the attack connected
				if ability.push > 0 and result.get("hit", false):
					var push_result := _resolve_push(target, attacker, ability.push, grid)
					result.merge(push_result)
			"heal":
				result = resolve_heal(attacker, target, ability)
			"buff", "debuff":
				result = resolve_buff(attacker, target, ability)

		result["target"] = target
		results.append(result)

	return results


func _resolve_push(
	target: CombatantData,
	attacker: CombatantData,
	push_distance: int,
	grid: HexGrid
) -> Dictionary:
	var delta: Vector2i = target.position - attacker.position

	# Find the DIRECTIONS entry whose direction best matches the delta vector
	var best_direction := HexGrid.DIRECTIONS[0]
	var best_dot: float = -INF

	for dir in HexGrid.DIRECTIONS:
		# Dot product using float arithmetic to rank alignment
		var dot: float = float(delta.x) * float(dir.x) + float(delta.y) * float(dir.y)
		if dot > best_dot:
			best_dot = dot
			best_direction = dir

	var new_pos: Vector2i = target.position + best_direction * push_distance

	if grid.tiles.has(new_pos) and not grid.is_occupied(new_pos):
		grid.remove_combatant(target.position)
		grid.place_combatant(new_pos, target)
		target.position = new_pos
		return {pushed = true, new_position = new_pos}

	return {pushed = false, new_position = target.position}
