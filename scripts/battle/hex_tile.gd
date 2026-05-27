extends Node2D

signal hex_clicked(hex_pos: Vector2i)
signal hex_hovered(hex_pos: Vector2i)

var hex_pos: Vector2i
var hex_state: String = "empty"

var polygon: Polygon2D
var area: Area2D

const COLORS := {
	"empty": Color(0.2, 0.2, 0.25),
	"ally": Color(0.2, 0.5, 0.2),
	"enemy": Color(0.5, 0.2, 0.2),
	"ally_zone": Color(0.15, 0.3, 0.15),
	"enemy_zone": Color(0.3, 0.15, 0.15),
	"highlighted": Color(0.4, 0.4, 0.2),
	"selected": Color(0.3, 0.3, 0.6),
}


func setup(pos: Vector2i, pixel_pos: Vector2) -> void:
	hex_pos = pos
	position = pixel_pos


func set_state(new_state: String) -> void:
	hex_state = new_state
	if polygon:
		polygon.color = COLORS.get(new_state, COLORS["empty"])


func _ready() -> void:
	polygon = Polygon2D.new()
	polygon.polygon = _create_hex_polygon()
	polygon.color = COLORS["empty"]
	add_child(polygon)

	area = Area2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon.polygon
	area.add_child(collision)
	add_child(area)
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)


func _create_hex_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := deg_to_rad(60.0 * i - 30.0)
		points.append(Vector2(cos(angle), sin(angle)) * 28.0)
	return points


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hex_clicked.emit(hex_pos)


func _on_mouse_entered() -> void:
	hex_hovered.emit(hex_pos)
	if hex_state == "empty" or hex_state == "ally_zone" or hex_state == "enemy_zone":
		polygon.color = COLORS["highlighted"]


func _on_mouse_exited() -> void:
	polygon.color = COLORS.get(hex_state, COLORS["empty"])
