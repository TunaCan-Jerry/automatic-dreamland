extends Node2D

# Temporary script to preview tileset tiles with their coordinates
# Run this scene to see what tile is at each atlas position

const TILE_SIZE := 16
const PREVIEW_SCALE := 5
const COLS := 19
const ROWS := 10
const START_ROW := 20  # show rows 20-29 (houses)

func _ready() -> void:
	var texture := load("res://assets/serene_village_16x16.png")
	var scaled := TILE_SIZE * PREVIEW_SCALE
	var gap := 8

	var camera := Camera2D.new()
	camera.position = Vector2(640, 400)
	add_child(camera)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2)
	bg.size = Vector2(COLS * (scaled + gap) + 80, ROWS * (scaled + gap) + 80)
	bg.position = Vector2.ZERO
	bg.z_index = -1
	add_child(bg)

	for row_idx in range(ROWS):
		var row := row_idx + START_ROW
		for col in range(COLS):
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			sprite.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(
				col * (scaled + gap) + scaled / 2 + 40,
				row_idx * (scaled + gap) + scaled / 2 + 40
			)
			add_child(sprite)

			var label := Label.new()
			label.text = "%d,%d" % [col, row]
			label.position = Vector2(
				col * (scaled + gap) + 35,
				row_idx * (scaled + gap) + scaled + 42
			)
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color.YELLOW)
			add_child(label)

	# Instructions
	var info := Label.new()
	info.text = "Arrow keys to scroll. Find tiles for: grass, path, water, tree, building, field"
	info.position = Vector2(40, 10)
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color.WHITE)
	add_child(info)


func _process(delta: float) -> void:
	var cam := get_node("Camera2D") as Camera2D
	var speed := 400.0
	if Input.is_action_pressed("ui_up"):
		cam.position.y -= speed * delta
	if Input.is_action_pressed("ui_down"):
		cam.position.y += speed * delta
	if Input.is_action_pressed("ui_left"):
		cam.position.x -= speed * delta
	if Input.is_action_pressed("ui_right"):
		cam.position.x += speed * delta
