class_name BattleState
extends RefCounted

var combatants: Array[CombatantData] = []
var turn_queue: Array[CombatantData] = []
var commander_actions_remaining: int = 1


func add_combatant(combatant: CombatantData) -> void:
	combatants.append(combatant)


func build_turn_queue() -> void:
	turn_queue.clear()
	for combatant in combatants:
		if combatant.is_alive():
			combatant.tick_status_effects()
			combatant.tick_cooldowns()
			turn_queue.append(combatant)
	turn_queue.sort_custom(func(a: CombatantData, b: CombatantData) -> bool:
		return a.get_effective_stat("speed") > b.get_effective_stat("speed")
	)


func get_next_combatant() -> CombatantData:
	if turn_queue.is_empty():
		return null
	return turn_queue[0]


func advance_turn() -> CombatantData:
	if turn_queue.is_empty():
		return null
	return turn_queue.pop_front()


func is_round_over() -> bool:
	return turn_queue.is_empty()


func remove_dead_from_queue() -> void:
	turn_queue = turn_queue.filter(func(c: CombatantData) -> bool:
		return c.is_alive()
	)


func get_allies() -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for combatant in combatants:
		if combatant.team == "ally" and combatant.is_alive():
			result.append(combatant)
	return result


func get_enemies() -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for combatant in combatants:
		if combatant.team == "enemy" and combatant.is_alive():
			result.append(combatant)
	return result


func check_win() -> bool:
	return get_enemies().is_empty()


func check_lose() -> bool:
	return get_allies().is_empty()


func use_commander_action() -> bool:
	if commander_actions_remaining > 0:
		commander_actions_remaining -= 1
		return true
	return false
