extends Node2D

signal sprite_clicked(combatant: CombatantData)

var combatant: CombatantData

var body: Polygon2D
var hp_bar_bg: ColorRect
var hp_bar: ColorRect
var name_label: Label


func setup(data: CombatantData, pixel_pos: Vector2) -> void:
	combatant = data
	position = pixel_pos
	_update_visuals()


func _ready() -> void:
	body = Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(12):
		var angle := deg_to_rad(30.0 * i)
		points.append(Vector2(cos(angle), sin(angle)) * 14.0)
	body.polygon = points
	add_child(body)

	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(30, 4)
	hp_bar_bg.position = Vector2(-15, -22)
	hp_bar_bg.color = Color(0.3, 0.1, 0.1)
	add_child(hp_bar_bg)

	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(30, 4)
	hp_bar.position = Vector2(-15, -22)
	hp_bar.color = Color(0.2, 0.8, 0.2)
	add_child(hp_bar)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-25, -38)
	name_label.size = Vector2(50, 14)
	name_label.add_theme_font_size_override("font_size", 10)
	add_child(name_label)

	var click_area := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	click_area.add_child(collision)
	click_area.input_event.connect(_on_click)
	add_child(click_area)


func _update_visuals() -> void:
	if combatant == null:
		return
	body.color = Color(0.3, 0.7, 0.3) if combatant.team == "ally" else Color(0.7, 0.3, 0.3)
	name_label.text = combatant.combatant_name
	_update_hp_bar()


func _update_hp_bar() -> void:
	if combatant == null:
		return
	var max_hp: int = combatant.stats.get("hp", 1)
	var ratio := float(combatant.current_hp) / float(max_hp)
	hp_bar.size.x = 30.0 * ratio
	if ratio > 0.5:
		hp_bar.color = Color(0.2, 0.8, 0.2)
	elif ratio > 0.25:
		hp_bar.color = Color(0.8, 0.8, 0.2)
	else:
		hp_bar.color = Color(0.8, 0.2, 0.2)


func animate_move(pixel_path: Array[Vector2], duration: float = 0.4) -> void:
	if pixel_path.size() <= 1:
		return
	var tween := create_tween()
	var step_time := duration / float(pixel_path.size() - 1)
	for i in range(1, pixel_path.size()):
		tween.tween_property(self, "position", pixel_path[i], step_time)
	await tween.finished


func animate_attack() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	await tween.finished


func animate_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween.finished
	_update_hp_bar()


func animate_heal() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 1, 0.3), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween.finished
	_update_hp_bar()


func animate_death() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()


func refresh() -> void:
	_update_visuals()


func _on_click(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if combatant:
			sprite_clicked.emit(combatant)
