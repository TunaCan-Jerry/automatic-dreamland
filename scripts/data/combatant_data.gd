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


func _init(data: Dictionary) -> void:
	combatant_name = data.get("name", "")
	team = data.get("team", "enemy")
	stats = data.get("stats", {})
	current_hp = stats.get("hp", 0)
	current_mp = stats.get("mp", 0)
	position = data.get("position", Vector2i.ZERO)
	targeting_priority = data.get("targeting_priority", "nearest")
	movement_allowance = data.get("movement_allowance", 3)
	cooldowns = {}
	status_effects = []

	abilities = []
	for ability_dict in data.get("abilities", []):
		abilities.append(AbilityData.new(ability_dict))


func is_alive() -> bool:
	return current_hp > 0


func get_effective_stat(stat_name: String) -> int:
	var base: int = stats.get(stat_name, 0)
	var total: int = base
	for effect in status_effects:
		if effect.get("stat", "") == stat_name:
			total += effect.get("amount", 0)
	return maxi(total, 0)


func tick_status_effects() -> void:
	var remaining: Array = []
	for effect in status_effects:
		var turns_left: int = effect.get("remaining_turns", 0) - 1
		if turns_left > 0:
			var updated := effect.duplicate()
			updated["remaining_turns"] = turns_left
			remaining.append(updated)
	status_effects = remaining


func tick_cooldowns() -> void:
	var keys_to_remove: Array = []
	for ability_name in cooldowns:
		cooldowns[ability_name] -= 1
		if cooldowns[ability_name] <= 0:
			keys_to_remove.append(ability_name)
	for key in keys_to_remove:
		cooldowns.erase(key)


func can_use_ability(ability: AbilityData) -> bool:
	if current_mp < ability.mp_cost:
		return false
	if cooldowns.has(ability.name) and cooldowns[ability.name] > 0:
		return false
	return true
