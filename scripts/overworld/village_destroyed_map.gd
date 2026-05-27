extends Node2D

const TILE_SIZE := 16
const MAP_W := 20
const MAP_H := 30

var player: Node2D
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var found_claira: bool = false
var tilemap: TileMapLayer


func _ready() -> void:
	quest_state = SceneManager.quest_state
	quest_state.set_state(QuestState.State.VILLAGE_DESTROYED)
	dialogue_manager = SceneManager.get_dialogue_manager()
	_create_tilemap()
	_setup_claira()
	_setup_player()
	modulate = Color(0.5, 0.35, 0.3)


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

	# 0=ash, 1=scorched path, 2=rubble (not walkable), 3=ember
	for i in range(4):
		source.create_tile(Vector2i(i, 0))
		var tile_data := source.get_tile_data(Vector2i(i, 0), 0)
		tile_data.set_custom_data_by_layer_id(0, i != 2)

	var source_id := tileset.add_source(source)
	tilemap.tile_set = tileset

	# Fill with ash
	for x in range(MAP_W):
		for y in range(MAP_H):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(0, 0))

	# Scorched path (same layout as village)
	for y in range(MAP_H):
		tilemap.set_cell(Vector2i(10, y), source_id, Vector2i(1, 0))
	for x in range(7, 14):
		tilemap.set_cell(Vector2i(x, 7), source_id, Vector2i(1, 0))
		tilemap.set_cell(Vector2i(x, 12), source_id, Vector2i(1, 0))
		tilemap.set_cell(Vector2i(x, 17), source_id, Vector2i(1, 0))

	# Rubble where buildings were
	for x in range(7, 12):
		for y in range(5, 7):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(2, 0))
	for x in range(7, 10):
		for y in range(15, 17):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(2, 0))
	for x in range(11, 14):
		for y in range(15, 17):
			tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(2, 0))

	# Embers scattered
	for pos in [Vector2i(8, 8), Vector2i(12, 10), Vector2i(6, 14), Vector2i(13, 18), Vector2i(9, 22)]:
		tilemap.set_cell(pos, source_id, Vector2i(3, 0))

	# Border rubble
	for y in range(MAP_H):
		tilemap.set_cell(Vector2i(0, y), source_id, Vector2i(2, 0))
		tilemap.set_cell(Vector2i(1, y), source_id, Vector2i(2, 0))
		tilemap.set_cell(Vector2i(MAP_W - 1, y), source_id, Vector2i(2, 0))
		tilemap.set_cell(Vector2i(MAP_W - 2, y), source_id, Vector2i(2, 0))

	# Top border (exit open)
	for x in range(MAP_W):
		if x < 9 or x > 11:
			tilemap.set_cell(Vector2i(x, 0), source_id, Vector2i(2, 0))


func _create_tile_texture() -> ImageTexture:
	var img := Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGB8)
	var colors := [
		Color(0.25, 0.2, 0.18),  # ash
		Color(0.35, 0.28, 0.22), # scorched path
		Color(0.3, 0.22, 0.15),  # rubble
		Color(0.5, 0.25, 0.1),   # ember
	]
	for i in range(4):
		for x in range(TILE_SIZE):
			for y in range(TILE_SIZE):
				img.set_pixel(i * TILE_SIZE + x, y, colors[i])
	return ImageTexture.create_from_image(img)


func _setup_claira() -> void:
	var claira := Node2D.new()
	claira.name = "ClairaBarrier"
	claira.position = Vector2(10, 24) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	add_child(claira)

	var claira_body := ColorRect.new()
	claira_body.size = Vector2(14, 14)
	claira_body.position = Vector2(-7, -7)
	claira_body.color = Color(0.9, 0.5, 0.3)
	claira.add_child(claira_body)

	var barrier := ColorRect.new()
	barrier.name = "Barrier"
	barrier.size = Vector2(24, 24)
	barrier.position = Vector2(-12, -12)
	barrier.color = Color(0.8, 0.9, 1.0, 0.3)
	claira.add_child(barrier)

	var tween := create_tween().set_loops()
	tween.tween_property(barrier, "color:a", 0.1, 1.0)
	tween.tween_property(barrier, "color:a", 0.4, 1.0)

	var label := Label.new()
	label.text = "Claira"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-25, -26)
	label.size = Vector2(50, 14)
	label.add_theme_font_size_override("font_size", 8)
	claira.add_child(label)


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(10, 2), tilemap)
	player.moved.connect(_on_player_moved)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _on_player_moved(new_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return

	if not found_claira:
		var dist := absi(new_pos.x - 10) + absi(new_pos.y - 24)
		if dist <= 2:
			found_claira = true
			_finding_claira_scene()

	if found_claira and quest_state.current_state == QuestState.State.FOUND_CLAIRA:
		if new_pos.y <= 1:
			player.disable_input()
			dialogue_manager.play(DialogueData.leaving_village())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.LEAVING)
			# End of opening MVP
			dialogue_manager.play([
				{speaker = "", text = "End of Opening — Thank you for playing!", mode = "cinematic"},
			])
			await dialogue_manager.dialogue_finished
			get_tree().quit()


func _finding_claira_scene() -> void:
	player.disable_input()
	quest_state.set_state(QuestState.State.FOUND_CLAIRA)

	var claira_node := get_node("ClairaBarrier")
	if claira_node:
		var barrier := claira_node.get_node("Barrier")
		if barrier:
			var tween := create_tween()
			tween.tween_property(barrier, "color:a", 0.0, 1.5)
			await tween.finished
			barrier.queue_free()

	dialogue_manager.play(DialogueData.finding_claira())
	await dialogue_manager.dialogue_finished
	player.enable_input()
