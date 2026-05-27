extends Node2D

const TILE_SIZE := 16
const MAP_W := 32
const MAP_H := 32

var player: Node2D
var claira_follow: Node2D
var npcs: Array[Node2D] = []
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var tilemap: TileMapLayer


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()

	_create_tilemap()
	_setup_player()
	_setup_npcs()
	_setup_claira()


func _create_tilemap() -> void:
	tilemap = TileMapLayer.new()
	tilemap.name = "TileMap"
	add_child(tilemap)

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "walkable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	var source := TileSetAtlasSource.new()
	source.texture = _create_tile_texture()
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create tiles first
	for i in range(7):
		source.create_tile(Vector2i(i, 0))

	# Add source to tileset so custom data layers are accessible
	var source_id := tileset.add_source(source)
	tilemap.tile_set = tileset

	# Now set custom data (0=grass, 1=path, 2=water, 3=building, 4=door, 5=field, 6=tree)
	var walkable := [true, true, false, false, true, true, false]
	for i in range(7):
		var tile_data := source.get_tile_data(Vector2i(i, 0), 0)
		tile_data.set_custom_data_by_layer_id(0, walkable[i])

	_paint_village(source_id)


func _create_tile_texture() -> ImageTexture:
	var img := Image.create(TILE_SIZE * 7, TILE_SIZE, false, Image.FORMAT_RGB8)
	var colors := [
		Color(0.3, 0.6, 0.2),   # grass
		Color(0.7, 0.6, 0.4),   # path
		Color(0.2, 0.3, 0.7),   # water
		Color(0.5, 0.3, 0.2),   # building
		Color(0.4, 0.25, 0.15), # door
		Color(0.5, 0.7, 0.2),   # field
		Color(0.1, 0.4, 0.1),   # tree
	]
	for i in range(7):
		for x in range(TILE_SIZE):
			for y in range(TILE_SIZE):
				img.set_pixel(i * TILE_SIZE + x, y, colors[i])
	return ImageTexture.create_from_image(img)


func _paint_village(source_id: int) -> void:
	var G := Vector2i(0, 0)  # grass
	var P := Vector2i(1, 0)  # path
	var W := Vector2i(2, 0)  # water
	var B := Vector2i(3, 0)  # building
	var D := Vector2i(4, 0)  # door
	var F := Vector2i(5, 0)  # field
	var T := Vector2i(6, 0)  # tree

	# Fill with grass
	for x in range(MAP_W):
		for y in range(MAP_H):
			tilemap.set_cell(Vector2i(x, y), source_id, G)

	# Tree border (irregular, not a solid wall)
	for y in range(MAP_H):
		tilemap.set_cell(Vector2i(0, y), source_id, T)
		if y % 3 != 1:
			tilemap.set_cell(Vector2i(1, y), source_id, T)
		tilemap.set_cell(Vector2i(MAP_W - 1, y), source_id, T)
		if y % 3 != 2:
			tilemap.set_cell(Vector2i(MAP_W - 2, y), source_id, T)
	for x in range(MAP_W):
		if x < 14 or x > 17:
			tilemap.set_cell(Vector2i(x, 0), source_id, T)
		tilemap.set_cell(Vector2i(x, MAP_H - 1), source_id, T)

	# Scattered trees for organic feel
	for pos in [Vector2i(5, 5), Vector2i(7, 3), Vector2i(26, 7), Vector2i(28, 12),
				Vector2i(4, 18), Vector2i(27, 20), Vector2i(6, 28), Vector2i(25, 28),
				Vector2i(3, 12), Vector2i(28, 4), Vector2i(22, 25), Vector2i(8, 25),
				Vector2i(3, 22), Vector2i(29, 16), Vector2i(14, 27), Vector2i(20, 3)]:
		tilemap.set_cell(pos, source_id, T)

	# === ENTRANCE (north) — path comes in from top center ===
	for y in range(1, 6):
		tilemap.set_cell(Vector2i(15, y), source_id, P)
		tilemap.set_cell(Vector2i(16, y), source_id, P)

	# === TAVERN — northeast, near entrance ===
	# Building
	for x in range(20, 25):
		for y in range(4, 7):
			tilemap.set_cell(Vector2i(x, y), source_id, B)
	tilemap.set_cell(Vector2i(22, 7), source_id, D)  # tavern door
	# Path to tavern
	for x in range(16, 23):
		tilemap.set_cell(Vector2i(x, 7), source_id, P)

	# === VILLAGE SQUARE — center of map ===
	# Wide open area with fountain
	for x in range(13, 19):
		for y in range(12, 16):
			tilemap.set_cell(Vector2i(x, y), source_id, P)
	# Fountain in center
	tilemap.set_cell(Vector2i(15, 13), source_id, W)
	tilemap.set_cell(Vector2i(16, 13), source_id, W)
	tilemap.set_cell(Vector2i(15, 14), source_id, W)
	tilemap.set_cell(Vector2i(16, 14), source_id, W)

	# Path from entrance to square (winding)
	for y in range(6, 12):
		tilemap.set_cell(Vector2i(15, y), source_id, P)
		tilemap.set_cell(Vector2i(16, y), source_id, P)
	# Slight curve
	tilemap.set_cell(Vector2i(14, 9), source_id, P)
	tilemap.set_cell(Vector2i(14, 10), source_id, P)

	# === YOUR HOUSE — west of square ===
	for x in range(5, 9):
		for y in range(11, 13):
			tilemap.set_cell(Vector2i(x, y), source_id, B)
	tilemap.set_cell(Vector2i(7, 13), source_id, D)
	# Path from square to your house
	for x in range(7, 13):
		tilemap.set_cell(Vector2i(x, 13), source_id, P)

	# === CLAIRA'S HOUSE — southwest, near yours ===
	for x in range(5, 9):
		for y in range(16, 18):
			tilemap.set_cell(Vector2i(x, y), source_id, B)
	tilemap.set_cell(Vector2i(7, 18), source_id, D)
	# Path connecting houses
	for y in range(13, 19):
		tilemap.set_cell(Vector2i(7, y), source_id, P)

	# === BENCH AREA — east side of square ===
	# Just path tiles with the old couple nearby
	for x in range(19, 22):
		tilemap.set_cell(Vector2i(x, 13), source_id, P)

	# === FIELDS — southeast ===
	for x in range(20, 28):
		for y in range(18, 23):
			tilemap.set_cell(Vector2i(x, y), source_id, F)
	# Path to fields
	for y in range(15, 19):
		tilemap.set_cell(Vector2i(19, y), source_id, P)
	for x in range(16, 20):
		tilemap.set_cell(Vector2i(x, 15), source_id, P)
	for x in range(19, 21):
		tilemap.set_cell(Vector2i(x, 18), source_id, P)

	# === THE TREE — between houses and elder's, off the path ===
	tilemap.set_cell(Vector2i(10, 21), source_id, T)
	# Small clearing around it
	tilemap.set_cell(Vector2i(9, 21), source_id, G)
	tilemap.set_cell(Vector2i(11, 21), source_id, G)
	tilemap.set_cell(Vector2i(10, 20), source_id, G)
	tilemap.set_cell(Vector2i(10, 22), source_id, G)

	# === ELDER'S HOUSE — far south, slightly west, tucked away ===
	for x in range(10, 14):
		for y in range(27, 29):
			tilemap.set_cell(Vector2i(x, y), source_id, B)
	tilemap.set_cell(Vector2i(12, 27), source_id, D)
	# Garden near elder's house
	for x in range(14, 17):
		for y in range(27, 30):
			tilemap.set_cell(Vector2i(x, y), source_id, F)
	# Winding path from houses area to elder's
	for y in range(19, 27):
		tilemap.set_cell(Vector2i(10, y), source_id, P)
	tilemap.set_cell(Vector2i(11, 26), source_id, P)
	tilemap.set_cell(Vector2i(12, 26), source_id, P)
	# Connect to main path network
	for x in range(7, 11):
		tilemap.set_cell(Vector2i(x, 19), source_id, P)


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)

	var npc_positions: Array[Vector2i] = []
	for npc in npcs:
		npc_positions.append(npc.grid_pos)
	player.setup(Vector2i(7, 14), tilemap, npc_positions)
	player.interacted.connect(_on_player_interact)
	player.moved.connect(_on_player_moved)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_claira() -> void:
	claira_follow = Node2D.new()
	claira_follow.set_script(load("res://scripts/overworld/follow_npc.gd"))
	add_child(claira_follow)
	claira_follow.setup(Vector2i(15, 15))
	claira_follow.visible = false


func _setup_npcs() -> void:
	# Tavern area — northeast
	_add_npc("Tavern Keeper", Vector2i(22, 8), "interact", Color(0.8, 0.6, 0.2), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.tavern_keeper_after_quest()
		return DialogueData.tavern_keeper()
	)
	_add_npc("Patron", Vector2i(24, 8), "interact", Color(0.6, 0.5, 0.4), func(_s: int) -> Array:
		return DialogueData.flavor_patron()
	)
	# Square area — center
	_add_npc("Old Man", Vector2i(20, 13), "interact", Color(0.7, 0.7, 0.7), func(_s: int) -> Array:
		return DialogueData.old_couple()
	)
	_add_npc("Kid", Vector2i(14, 15), "interact", Color(0.9, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_kid()
	)
	# Fields — southeast
	_add_npc("Dad", Vector2i(22, 20), "interact", Color(0.3, 0.6, 0.3), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.dad_after_quest()
		return DialogueData.dad_greeting()
	)
	_add_npc("Farmer", Vector2i(25, 20), "interact", Color(0.5, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_farmer()
	)
	# Claira — near fountain in square
	_add_npc("Claira", Vector2i(15, 15), "auto", Color(0.9, 0.5, 0.3), func(_s: int) -> Array:
		return DialogueData.claira_first_meeting()
	, false)
	# Elder — at her house in the south
	_add_npc("Elder", Vector2i(12, 26), "auto", Color(0.7, 0.5, 0.7), func(_s: int) -> Array:
		return DialogueData.elder_conversation()
	, false)
	# Your house door — west
	_add_npc("Home", Vector2i(7, 13), "interact", Color(0.4, 0.25, 0.15), func(_s: int) -> Array:
		return DialogueData.house_photo()
	)

	# Update player blocked positions after NPCs are set up
	var npc_positions: Array[Vector2i] = []
	for npc in npcs:
		npc_positions.append(npc.grid_pos)
	if player:
		player.set_blocked_positions(npc_positions)


func _add_npc(npc_name: String, pos: Vector2i, trigger: String, color: Color, dialogue_cb: Callable, is_repeatable: bool = true) -> Node2D:
	var npc = Node2D.new()
	npc.set_script(load("res://scripts/overworld/npc.gd"))
	npc.npc_name = npc_name
	npc.trigger_mode = trigger
	npc.repeatable = is_repeatable
	npc.npc_color = color
	add_child(npc)
	npc.setup(pos)
	npc.set_dialogue(dialogue_cb)
	npcs.append(npc)
	return npc


func _on_player_moved(new_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return

	# Check auto-trigger NPCs
	for npc in npcs:
		if npc.visible and npc.check_auto_trigger(new_pos):
			_trigger_npc(npc)
			return

	# Update Claira follow
	if claira_follow.visible and claira_follow.following:
		claira_follow.update_follow(new_pos)

	# Check zone triggers
	_check_zone_triggers()


func _on_player_interact(facing_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return
	for npc in npcs:
		if npc.visible and npc.grid_pos == facing_pos and npc.trigger_mode == "interact" and npc.can_trigger():
			_trigger_npc(npc)
			return


func _trigger_npc(npc: Node2D) -> void:
	var lines: Array = npc.get_dialogue(quest_state.current_state)
	if lines.is_empty():
		return

	npc.mark_triggered()
	player.disable_input()
	dialogue_manager.play(lines)
	await dialogue_manager.dialogue_finished
	player.enable_input()

	_handle_post_dialogue(npc)


func _handle_post_dialogue(npc: Node2D) -> void:
	match npc.npc_name:
		"Claira":
			if quest_state.current_state == QuestState.State.EXPLORE_VILLAGE:
				quest_state.set_state(QuestState.State.TALKED_TO_CLAIRA)
				npc.visible = false
				claira_follow.visible = true
				claira_follow.setup(player.grid_pos + Vector2i(0, 1))
				claira_follow.start_following(player.grid_pos)
		"Elder":
			if quest_state.current_state >= QuestState.State.TALKED_TO_CLAIRA and quest_state.current_state <= QuestState.State.AT_ELDER:
				quest_state.set_state(QuestState.State.GOT_QUEST)
				claira_follow.stop_following()
				claira_follow.visible = false


func _check_zone_triggers() -> void:
	# Tree kiss trigger — near the tree at (10, 21)
	if quest_state.current_state == QuestState.State.TALKED_TO_CLAIRA:
		if player.grid_pos == Vector2i(9, 21) or player.grid_pos == Vector2i(11, 21) or player.grid_pos == Vector2i(10, 20) or player.grid_pos == Vector2i(10, 22):
			quest_state.set_state(QuestState.State.WALKING_TO_ELDER)
			player.disable_input()
			dialogue_manager.play(DialogueData.tree_kiss())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.AT_ELDER)
			player.enable_input()

	# Village exit — north
	if quest_state.current_state == QuestState.State.GOT_QUEST:
		if player.grid_pos.y <= 1:
			quest_state.set_state(QuestState.State.ON_THE_ROAD)
			SceneManager.transition_to("res://scenes/overworld/road.tscn")
