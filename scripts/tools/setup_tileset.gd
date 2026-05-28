@tool
extends EditorScript

# Run this once from the Godot editor: Script > Run (Ctrl+Shift+X)
# Creates a TileSet resource from the Serene Village tileset

func _run() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "walkable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	var source := TileSetAtlasSource.new()
	var texture := load("res://assets/serene_village_16x16.png")
	source.texture = texture
	source.texture_region_size = Vector2i(16, 16)

	# Create all tiles in the atlas (19 columns x 45 rows)
	for col in range(19):
		for row in range(45):
			var coord := Vector2i(col, row)
			source.create_tile(coord)

	var source_id := tileset.add_source(source)

	# Set all tiles walkable by default, then mark unwalkable ones
	for col in range(19):
		for row in range(45):
			var tile_data := source.get_tile_data(Vector2i(col, row), 0)
			tile_data.set_custom_data_by_layer_id(0, true)

	# Save the resource
	var err := ResourceSaver.save(tileset, "res://assets/serene_village_tileset.tres")
	if err == OK:
		print("TileSet saved to res://assets/serene_village_tileset.tres")
	else:
		print("ERROR saving TileSet: ", err)
