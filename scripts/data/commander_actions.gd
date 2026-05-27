class_name CommanderActions
extends RefCounted


func use_item_heal(target: CombatantData) -> Dictionary:
	var heal_amount := 30
	var max_hp: int = target.stats.get("hp", 1)
	var actual := mini(heal_amount, max_hp - target.current_hp)
	target.current_hp = mini(max_hp, target.current_hp + heal_amount)
	return {type = "heal", target = target, healed = actual}


func call_retreat() -> Dictionary:
	return {type = "retreat"}
