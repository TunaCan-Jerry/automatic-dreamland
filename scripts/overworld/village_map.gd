extends Node2D

const TILE_SIZE := 16
const MAP_W := 20
const MAP_H := 30

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
	# Fill with grass
	for x in range(MAP_W):
		for y in range(MAP_H):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(0, 0))

	# Main path from entrance (top) to elder's house (bottom)
	for y in range(MAP_H):
		tilemap.set_cell(Vector2i(10, y), source_id, Vector2i(1, 0))

	# Horizontal paths
	for x in range(7, 14):
		tilemap.set_cell(Vector2i(x, 7), source_id, Vector2i(1, 0))   # tavern row
		tilemap.set_cell(Vector2i(x, 12), source_id, Vector2i(1, 0))  # square row
		tilemap.set_cell(Vector2i(x, 17), source_id, Vector2i(1, 0))  # house row

	# Village square + fountain
	for x in range(9, 12):
		for y in range(11, 14):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(1, 0))
	tilemap.set_cell(Vector2i(10, 12), source_id, Vector2i(2, 0))  # fountain

	# Tavern (building block)
	for x in range(7, 12):
		for y in range(5, 7):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(3, 0))
	tilemap.set_cell(Vector2i(9, 7), source_id, Vector2i(4, 0))  # tavern door

	# Your house
	for x in range(7, 10):
		for y in range(15, 17):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(3, 0))
	tilemap.set_cell(Vector2i(8, 17), source_id, Vector2i(4, 0))  # your door

	# Claira's house
	for x in range(11, 14):
		for y in range(15, 17):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(3, 0))
	tilemap.set_cell(Vector2i(12, 17), source_id, Vector2i(4, 0))  # her door

	# Fields
	for x in range(5, 15):
		for y in range(20, 23):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(5, 0))

	# Elder's house
	for x in range(9, 12):
		for y in range(25, 27):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(3, 0))
	tilemap.set_cell(Vector2i(10, 25), source_id, Vector2i(4, 0))  # elder's door

	# Trees along edges
	for y in range(MAP_H):
		tilemap.set_cell(Vector2i(0, y), source_id, Vector2i(6, 0))
		tilemap.set_cell(Vector2i(1, y), source_id, Vector2i(6, 0))
		tilemap.set_cell(Vector2i(MAP_W - 1, y), source_id, Vector2i(6, 0))
		tilemap.set_cell(Vector2i(MAP_W - 2, y), source_id, Vector2i(6, 0))

	# The tree (for the kiss scene)
	tilemap.set_cell(Vector2i(8, 19), source_id, Vector2i(6, 0))

	# Border trees top (except entrance)
	for x in range(MAP_W):
		if x < 9 or x > 11:
			tilemap.set_cell(Vector2i(x, 0), source_id, Vector2i(6, 0))


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)

	var npc_positions: Array[Vector2i] = []
	for npc in npcs:
		npc_positions.append(npc.grid_pos)
	player.setup(Vector2i(8, 18), tilemap, npc_positions)
	player.interacted.connect(_on_player_interact)
	player.moved.connect(_on_player_moved)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_claira() -> void:
	claira_follow = Node2D.new()
	claira_follow.set_script(load("res://scripts/overworld/follow_npc.gd"))
	add_child(claira_follow)
	claira_follow.setup(Vector2i(10, 13))
	claira_follow.visible = false


func _setup_npcs() -> void:
	_add_npc("Tavern Keeper", Vector2i(9, 8), "interact", Color(0.8, 0.6, 0.2), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.tavern_keeper_after_quest()
		return DialogueData.tavern_keeper()
	)
	_add_npc("Patron", Vector2i(11, 8), "interact", Color(0.6, 0.5, 0.4), func(_s: int) -> Array:
		return DialogueData.flavor_patron()
	)
	_add_npc("Old Man", Vector2i(8, 11), "interact", Color(0.7, 0.7, 0.7), func(_s: int) -> Array:
		return DialogueData.old_couple()
	)
	_add_npc("Kid", Vector2i(11, 13), "interact", Color(0.9, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_kid()
	)
	_add_npc("Dad", Vector2i(7, 21), "interact", Color(0.3, 0.6, 0.3), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.dad_after_quest()
		return DialogueData.dad_greeting()
	)
	_add_npc("Farmer", Vector2i(12, 21), "interact", Color(0.5, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_farmer()
	)
	_add_npc("Claira", Vector2i(10, 13), "auto", Color(0.9, 0.5, 0.3), func(_s: int) -> Array:
		return DialogueData.claira_first_meeting()
	, false)
	_add_npc("Elder", Vector2i(10, 24), "auto", Color(0.7, 0.5, 0.7), func(_s: int) -> Array:
		return DialogueData.elder_conversation()
	, false)
	_add_npc("Home", Vector2i(8, 17), "interact", Color(0.4, 0.25, 0.15), func(_s: int) -> Array:
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
	# Tree kiss trigger
	if quest_state.current_state == QuestState.State.TALKED_TO_CLAIRA:
		if player.grid_pos == Vector2i(8, 20) or player.grid_pos == Vector2i(9, 19):
			quest_state.set_state(QuestState.State.WALKING_TO_ELDER)
			player.disable_input()
			dialogue_manager.play(DialogueData.tree_kiss())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.AT_ELDER)
			player.enable_input()

	# Village exit
	if quest_state.current_state == QuestState.State.GOT_QUEST:
		if player.grid_pos.y <= 1:
			quest_state.set_state(QuestState.State.ON_THE_ROAD)
			SceneManager.transition_to("res://scenes/overworld/road.tscn")
