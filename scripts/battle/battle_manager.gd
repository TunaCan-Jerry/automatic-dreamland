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

var hex_tile_scene := preload("res://scenes/battle/hex_tile.tscn")
var character_sprite_scene := preload("res://scenes/battle/character_sprite.tscn")
var hex_tiles: Dictionary = {}
var character_sprites: Dictionary = {}

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
	_setup_ui()


func _render_grid() -> void:
	for hex_pos in grid.tiles:
		var tile_node = hex_tile_scene.instantiate()
		var pixel_pos := grid.axial_to_pixel(hex_pos)
		grid_container.add_child(tile_node)
		tile_node.setup(hex_pos, pixel_pos)
		hex_tiles[hex_pos] = tile_node
		match grid.tile_zones.get(hex_pos, HexGrid.Zone.NEUTRAL):
			HexGrid.Zone.ALLY:
				tile_node.set_state("ally_zone")
			HexGrid.Zone.ENEMY:
				tile_node.set_state("enemy_zone")


func _setup_ui() -> void:
	var pre_fight_ui = $UI/PreFightUI
	pre_fight_ui.setup(EncounterData.ally_roster(), self)
	pre_fight_ui.setup_complete.connect(_on_setup_complete)

	for hex_pos in hex_tiles:
		hex_tiles[hex_pos].hex_clicked.connect(pre_fight_ui.on_hex_clicked)

	var battle_ui = $UI/BattleUI
	battle_ui.setup(self)
	battle_ui.visible = false
	battle_ui.commander_heal_requested.connect(commander_heal)
	battle_ui.commander_retreat_requested.connect(commander_retreat)
	battle_ui.speed_changed.connect(set_speed)
	battle_ui.pause_toggled.connect(toggle_pause)
	turn_started.connect(func(_c): battle_ui.update_turn_order(state.turn_queue))
	battle_won.connect(battle_ui.show_win)
	battle_lost.connect(battle_ui.show_lose)


func _on_setup_complete(allies: Array) -> void:
	$UI/PreFightUI.visible = false
	$UI/BattleUI.visible = true
	var encounter := EncounterData.test_encounter()
	var typed_allies: Array[CombatantData] = []
	for a in allies:
		typed_allies.append(a)
	start_combat(typed_allies, encounter)


func start_combat(allies: Array[CombatantData], encounter: EncounterData) -> void:
	for enemy_dict in encounter.enemies:
		var enemy := CombatantData.new(enemy_dict)
		state.add_combatant(enemy)
		grid.place_combatant(enemy.position, enemy)
		_spawn_sprite(enemy)

	for ally in allies:
		state.add_combatant(ally)
		_spawn_sprite(ally)

	phase = Phase.COMBAT
	phase_changed.emit("combat")
	_run_combat()


func _spawn_sprite(combatant: CombatantData) -> void:
	var sprite = character_sprite_scene.instantiate()
	sprite_container.add_child(sprite)
	sprite.setup(combatant, grid.axial_to_pixel(combatant.position))
	sprite.sprite_clicked.connect(_on_sprite_clicked)
	character_sprites[combatant] = sprite


func _run_combat() -> void:
	while phase == Phase.COMBAT:
		state.build_turn_queue()
		round_ended.emit()

		while not state.is_round_over() and phase == Phase.COMBAT:
			if paused or waiting_for_commander:
				await get_tree().create_timer(0.1).timeout
				continue

			var combatant := state.advance_turn()
			if combatant == null or not combatant.is_alive():
				continue

			turn_started.emit(combatant)
			_highlight_active(combatant)
			await _execute_turn(combatant)
			_refresh_tile_states()

			state.remove_dead_from_queue()
			if state.check_win():
				phase = Phase.POST_COMBAT
				battle_won.emit()
				return
			if state.check_lose():
				phase = Phase.POST_COMBAT
				battle_lost.emit()
				return

			await get_tree().create_timer(0.3 / speed_scale).timeout


func _execute_turn(combatant: CombatantData) -> void:
	var enemies: Array
	var allies_list: Array
	if combatant.team == "ally":
		enemies = state.get_enemies()
		allies_list = state.get_allies()
	else:
		enemies = state.get_allies()
		allies_list = state.get_enemies()

	var action := ai.decide_action(combatant, enemies, allies_list, grid)

	match action.get("type", "wait"):
		"move":
			await _animate_move(combatant, action.get("path", []))
		"ability":
			var results := resolver.resolve_ability(combatant, action.targets, action.ability, grid)
			await _animate_ability(combatant, results)
			action_resolved.emit(results)
		"move_and_ability":
			await _animate_move(combatant, action.get("path", []))
			var results := resolver.resolve_ability(combatant, action.targets, action.ability, grid)
			await _animate_ability(combatant, results)
			action_resolved.emit(results)


func _animate_move(combatant: CombatantData, path: Array) -> void:
	var sprite = character_sprites.get(combatant)
	if sprite == null or path.size() <= 1:
		return
	var pixel_path: Array[Vector2] = []
	for hex in path:
		pixel_path.append(grid.axial_to_pixel(hex))
	await sprite.animate_move(pixel_path, 0.5 / speed_scale)


func _animate_ability(combatant: CombatantData, results: Array) -> void:
	var attacker_sprite = character_sprites.get(combatant)
	if attacker_sprite:
		await attacker_sprite.animate_attack()

	for result in results:
		var target = result.get("target")
		if target == null:
			continue
		var target_sprite = character_sprites.get(target)
		if target_sprite == null:
			continue

		if result.get("damage", 0) > 0:
			await target_sprite.animate_damage()
		elif result.get("healed", 0) > 0:
			await target_sprite.animate_heal()
		elif result.get("buffed", false) or result.get("debuffed", false):
			await target_sprite.animate_heal()

		if result.get("kill", false):
			await _remove_dead_sprite(target)

	_refresh_all_sprites()


func _remove_dead_sprite(combatant: CombatantData) -> void:
	var sprite = character_sprites.get(combatant)
	if sprite:
		await sprite.animate_death()
		character_sprites.erase(combatant)
		grid.remove_combatant(combatant.position)


func _highlight_active(combatant: CombatantData) -> void:
	for pos in hex_tiles:
		var tile = hex_tiles[pos]
		if pos == combatant.position:
			tile.set_state("selected")


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
	for c in character_sprites:
		character_sprites[c].refresh()


func _on_sprite_clicked(combatant: CombatantData) -> void:
	if waiting_for_commander:
		$UI/BattleUI.on_character_clicked(combatant)


func commander_heal(target: CombatantData) -> void:
	if state.use_commander_action():
		commander.use_item_heal(target)
		var sprite = character_sprites.get(target)
		if sprite:
			await sprite.animate_heal()
		_refresh_all_sprites()
		$UI/BattleUI.update_commander_button()
		waiting_for_commander = false


func commander_retreat() -> void:
	if state.use_commander_action():
		phase = Phase.PRE_FIGHT
		phase_changed.emit("pre_fight")
		waiting_for_commander = false
		get_tree().reload_current_scene()


func set_speed(scale: float) -> void:
	speed_scale = scale


func toggle_pause() -> void:
	paused = not paused
