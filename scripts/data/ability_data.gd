class_name AbilityData
extends RefCounted

var name: String
var type: String  # "physical", "magic", "heal", "buff", "debuff"
var power_mult: float
var mp_cost: int
var ability_range: int  # "range" is a keyword
var target: String  # "enemy", "ally", "self", "all_enemies", "all_allies", "adjacent_allies", "adjacent_hexes"
var cooldown: int
var status_effect: Dictionary  # {stat: String, amount: int, duration: int} or {}
var push: int
var bonus_move: int


func _init(data: Dictionary) -> void:
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
		"name": "Attack",
		"type": "physical",
		"power_mult": 1.0,
		"range": 1,
		"mp_cost": 0,
		"target": "enemy",
	})
