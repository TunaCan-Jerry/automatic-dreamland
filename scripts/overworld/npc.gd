extends Node2D

signal npc_triggered(npc: Node2D)

var npc_name: String = "NPC"
var trigger_mode: String = "interact"
var repeatable: bool = true
var npc_color: Color = Color(0.8, 0.6, 0.2)

var grid_pos: Vector2i
var has_triggered: bool = false
var dialogue_callback: Callable

var body: ColorRect
var name_label: Label

const TILE_SIZE := 16


func _ready() -> void:
	body = ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = npc_color
	add_child(body)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-25, -22)
	name_label.size = Vector2(50, 14)
	name_label.add_theme_font_size_override("font_size", 8)
	add_child(name_label)


func setup(pos: Vector2i) -> void:
	grid_pos = pos
	position = Vector2(pos) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)


func set_dialogue(callback: Callable) -> void:
	dialogue_callback = callback


func get_dialogue(quest_state: int) -> Array:
	if dialogue_callback.is_valid():
		return dialogue_callback.call(quest_state)
	return []


func can_trigger() -> bool:
	if not repeatable and has_triggered:
		return false
	return true


func mark_triggered() -> void:
	has_triggered = true


func check_auto_trigger(player_pos: Vector2i) -> bool:
	if trigger_mode != "auto":
		return false
	if not can_trigger():
		return false
	var dist := absi(player_pos.x - grid_pos.x) + absi(player_pos.y - grid_pos.y)
	return dist <= 1
