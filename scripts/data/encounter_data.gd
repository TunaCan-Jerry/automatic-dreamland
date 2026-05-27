class_name EncounterData
extends RefCounted

var enemies: Array[Dictionary]


static func test_encounter() -> EncounterData:
	var encounter := EncounterData.new()
	encounter.enemies = [
		{
			"name": "Goblin",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"targeting_priority": "nearest",
			"stats": {
				"hp": 40, "mp": 0, "attack": 10, "defense": 5,
				"magic": 2, "resistance": 3, "speed": 11,
				"accuracy": 75, "evasion": 12, "luck": 3
			},
			"abilities": [
				{"name": "Slash", "type": "physical", "power_mult": 1.0, "range": 1, "mp_cost": 0},
			],
		},
		{
			"name": "Goblin Archer",
			"team": "enemy",
			"position": Vector2i(3, -1),
			"targeting_priority": "weakest",
			"stats": {
				"hp": 30, "mp": 0, "attack": 8, "defense": 4,
				"magic": 2, "resistance": 3, "speed": 13,
				"accuracy": 80, "evasion": 8, "luck": 3
			},
			"abilities": [
				{"name": "Arrow", "type": "physical", "power_mult": 1.0, "range": 2, "mp_cost": 0},
			],
		},
		{
			"name": "Goblin Shaman",
			"team": "enemy",
			"position": Vector2i(4, 0),
			"targeting_priority": "strongest",
			"stats": {
				"hp": 35, "mp": 40, "attack": 3, "defense": 4,
				"magic": 12, "resistance": 8, "speed": 9,
				"accuracy": 85, "evasion": 5, "luck": 5
			},
			"abilities": [
				{"name": "Dark Bolt", "type": "magic", "power_mult": 1.5, "range": 3, "mp_cost": 8},
				{
					"name": "Hex", "type": "debuff", "range": 2, "mp_cost": 10, "cooldown": 3,
					"status_effect": {"stat": "defense", "amount": -5, "duration": 3},
				},
			],
		},
		{
			"name": "Goblin Chief",
			"team": "enemy",
			"position": Vector2i(3, 1),
			"targeting_priority": "nearest",
			"stats": {
				"hp": 100, "mp": 20, "attack": 14, "defense": 12,
				"magic": 6, "resistance": 8, "speed": 7,
				"accuracy": 80, "evasion": 3, "luck": 5
			},
			"abilities": [
				{
					"name": "Cleave", "type": "physical", "power_mult": 1.3, "range": 1,
					"mp_cost": 5, "cooldown": 2, "target": "adjacent_hexes",
				},
				{
					"name": "War Cry", "type": "buff", "range": 0, "mp_cost": 10,
					"cooldown": 4, "target": "all_allies",
					"status_effect": {"stat": "attack", "amount": 4, "duration": 3},
				},
			],
		},
	]
	return encounter


static func ally_roster() -> Array[Dictionary]:
	return [
		{
			"name": "Leader",
			"team": "ally",
			"targeting_priority": "nearest",
			"stats": {
				"hp": 120, "mp": 40, "attack": 12, "defense": 15,
				"magic": 8, "resistance": 10, "speed": 8,
				"accuracy": 85, "evasion": 5, "luck": 5
			},
			"abilities": [
				{
					"name": "Rally", "type": "buff", "range": 1, "mp_cost": 10,
					"cooldown": 3, "target": "adjacent_allies",
					"status_effect": {"stat": "attack", "amount": 5, "duration": 3},
				},
				{
					"name": "Shield Bash", "type": "physical", "power_mult": 1.2, "range": 1,
					"mp_cost": 8, "cooldown": 2, "push": 1,
				},
			],
		},
		{
			"name": "Ranger",
			"team": "ally",
			"targeting_priority": "weakest",
			"stats": {
				"hp": 80, "mp": 30, "attack": 15, "defense": 8,
				"magic": 5, "resistance": 6, "speed": 12,
				"accuracy": 90, "evasion": 15, "luck": 8
			},
			"abilities": [
				{
					"name": "Power Shot", "type": "physical", "power_mult": 1.8,
					"range": 3, "mp_cost": 10, "cooldown": 2,
				},
				{
					"name": "Quick Step", "type": "buff", "range": 0, "mp_cost": 5,
					"cooldown": 3, "target": "self", "bonus_move": 2,
				},
			],
		},
		{
			"name": "Healer",
			"team": "ally",
			"targeting_priority": "protect",
			"stats": {
				"hp": 70, "mp": 60, "attack": 5, "defense": 6,
				"magic": 15, "resistance": 12, "speed": 10,
				"accuracy": 95, "evasion": 10, "luck": 10
			},
			"abilities": [
				{
					"name": "Heal", "type": "heal", "power_mult": 1.5, "range": 2,
					"mp_cost": 12, "target": "ally",
				},
				{
					"name": "Barrier", "type": "buff", "range": 1, "mp_cost": 10,
					"cooldown": 3, "target": "ally",
					"status_effect": {"stat": "defense", "amount": 8, "duration": 2},
				},
			],
		},
	]
