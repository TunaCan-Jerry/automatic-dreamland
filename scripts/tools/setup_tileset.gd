extends SceneTree

func _init() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "walkable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	var source := TileSetAtlasSource.new()
	var texture := load("res://assets/serene_village_16x16.png")
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)

	for col in range(19):
		for row in range(45):
			source.create_tile(Vector2i(col, row))

	var source_id := tileset.add_source(source)

	for col in range(19):
		for row in range(45):
			var tile_data := source.get_tile_data(Vector2i(col, row), 0)
			tile_data.set_custom_data_by_layer_id(0, true)

	var err := ResourceSaver.save(tileset, "res://assets/serene_village_tileset.tres")
	if err == OK:
		print("SUCCESS: TileSet saved to res://assets/serene_village_tileset.tres")
	else:
		print("ERROR saving TileSet: ", err)

	quit()
