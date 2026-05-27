extends Node2D

const TILE_SIZE := 16

var grid_pos: Vector2i
var following: bool = false
var position_history: Array[Vector2i] = []

var body: ColorRect
var name_label: Label


func _ready() -> void:
	body = ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = Color(0.9, 0.5, 0.3)
	add_child(body)

	name_label = Label.new()
	name_label.text = "Claira"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-25, -22)
	name_label.size = Vector2(50, 14)
	name_label.add_theme_font_size_override("font_size", 8)
	add_child(name_label)


func setup(pos: Vector2i) -> void:
	grid_pos = pos
	position = Vector2(pos) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)


func start_following(start_pos: Vector2i) -> void:
	following = true
	position_history.clear()
	position_history.append(start_pos)


func stop_following() -> void:
	following = false


func update_follow(player_grid_pos: Vector2i) -> void:
	if not following:
		return

	position_history.append(player_grid_pos)

	if position_history.size() > 2:
		var next_pos: Vector2i = position_history[0]
		position_history.remove_at(0)

		if next_pos != grid_pos:
			grid_pos = next_pos
			var target_pixel := Vector2(grid_pos) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
			var tween := create_tween()
			tween.tween_property(self, "position", target_pixel, 0.12)
