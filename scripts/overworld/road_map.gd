extends Node2D

const TILE_SIZE := 16
const MAP_W := 10
const MAP_H := 30

var player: Node2D
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var battle_triggered: bool = false
var tilemap: TileMapLayer


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()
	_create_tilemap()
	_setup_player()


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

	for i in range(3):
		source.create_tile(Vector2i(i, 0))
		var tile_data := source.get_tile_data(Vector2i(i, 0), 0)
		tile_data.set_custom_data_by_layer_id(0, i != 2)

	var source_id := tileset.add_source(source)
	tilemap.tile_set = tileset

	# Paint road
	for x in range(MAP_W):
		for y in range(MAP_H):
			if x <= 1 or x >= MAP_W - 2:
				tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(2, 0))  # tree
			elif x == 5:
				tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(1, 0))  # path
			else:
				tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(0, 0))  # grass


func _create_tile_texture() -> ImageTexture:
	var img := Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGB8)
	var colors := [Color(0.3, 0.6, 0.2), Color(0.7, 0.6, 0.4), Color(0.1, 0.4, 0.1)]
	for i in range(3):
		for x in range(TILE_SIZE):
			for y in range(TILE_SIZE):
				img.set_pixel(i * TILE_SIZE + x, y, colors[i])
	return ImageTexture.create_from_image(img)


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(5, 28), tilemap)
	player.moved.connect(_on_player_moved)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _on_player_moved(new_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return

	# Tutorial battle trigger at midpoint (currently skipped — just a message)
	if not battle_triggered and new_pos.y <= 15:
		battle_triggered = true
		player.disable_input()
		dialogue_manager.play([
			{speaker = "", text = "Some critters block the path! (Tutorial battle — coming soon)", mode = "normal"},
			{speaker = "", text = "You fight them off.", mode = "normal"},
		])
		await dialogue_manager.dialogue_finished
		player.enable_input()

	# Exit to homestead
	if battle_triggered and new_pos.y <= 1:
		SceneManager.transition_to("res://scenes/overworld/homestead.tscn")
