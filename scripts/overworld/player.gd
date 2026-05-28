extends Node2D

signal interacted(facing_pos: Vector2i)
signal moved(new_pos: Vector2i)

const TILE_SIZE := 16
const MOVE_SPEED := 0.12

var grid_pos: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var moving: bool = false
var input_enabled: bool = true
var tilemap: TileMapLayer
var blocked_positions: Array[Vector2i] = []

var body: ColorRect


func _ready() -> void:
	body = ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = Color(0.2, 0.4, 0.9)
	add_child(body)


func setup(start_pos: Vector2i, map: TileMapLayer, blockers: Array[Vector2i] = []) -> void:
	grid_pos = start_pos
	tilemap = map
	blocked_positions = blockers
	position = _grid_to_pixel(grid_pos)


func set_blocked_positions(blockers: Array[Vector2i]) -> void:
	blocked_positions = blockers


func _process(_delta: float) -> void:
	if not input_enabled or moving:
		return

	var direction := Vector2i.ZERO

	if Input.is_action_pressed("ui_up"):
		direction = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2i(1, 0)

	if direction != Vector2i.ZERO:
		facing = direction
		var target := grid_pos + direction
		if _can_move_to(target):
			_move_to(target)

	if Input.is_action_just_pressed("ui_accept"):
		interacted.emit(grid_pos + facing)


func _can_move_to(target: Vector2i) -> bool:
	if target in blocked_positions:
		return false
	if tilemap == null:
		return true
	var tile_data := tilemap.get_cell_tile_data(target)
	if tile_data == null:
		# No tile painted here — allow movement for now (empty space)
		return true
	# Check walkable custom data if it exists, otherwise allow
	var walkable = tile_data.get_custom_data_by_layer_id(0)
	if walkable == null:
		return true
	return walkable


func _move_to(target: Vector2i) -> void:
	moving = true
	grid_pos = target
	var target_pixel := _grid_to_pixel(target)
	var tween := create_tween()
	tween.tween_property(self, "position", target_pixel, MOVE_SPEED)
	await tween.finished
	moving = false
	moved.emit(grid_pos)


func _grid_to_pixel(pos: Vector2i) -> Vector2:
	return Vector2(pos) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)


func disable_input() -> void:
	input_enabled = false


func enable_input() -> void:
	input_enabled = true
