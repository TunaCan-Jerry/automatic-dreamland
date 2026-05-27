extends CanvasLayer

signal dialogue_finished

var dialogue_box_scene := preload("res://scenes/ui/dialogue_box.tscn")
var cinematic_scene := preload("res://scenes/ui/cinematic_overlay.tscn")

var dialogue_box: PanelContainer
var cinematic_overlay: ColorRect
var active: bool = false
var current_sequence: Array = []
var current_index: int = 0


func _ready() -> void:
	dialogue_box = dialogue_box_scene.instantiate()
	add_child(dialogue_box)
	dialogue_box.dialogue_finished.connect(_on_segment_finished)

	cinematic_overlay = cinematic_scene.instantiate()
	add_child(cinematic_overlay)
	cinematic_overlay.dialogue_finished.connect(_on_segment_finished)


func play(lines: Array) -> void:
	if lines.is_empty():
		dialogue_finished.emit()
		return
	active = true
	current_sequence = _split_by_mode(lines)
	current_index = 0
	_play_current_segment()


func is_active() -> bool:
	return active


func _split_by_mode(lines: Array) -> Array:
	var segments: Array = []
	var current_mode: String = ""
	var current_lines: Array = []

	for line in lines:
		var mode: String = line.get("mode", "normal")
		if mode != current_mode:
			if current_lines.size() > 0:
				segments.append({mode = current_mode, lines = current_lines})
			current_mode = mode
			current_lines = [line]
		else:
			current_lines.append(line)

	if current_lines.size() > 0:
		segments.append({mode = current_mode, lines = current_lines})

	return segments


func _play_current_segment() -> void:
	if current_index >= current_sequence.size():
		active = false
		dialogue_finished.emit()
		return

	var segment: Dictionary = current_sequence[current_index]
	if segment.mode == "cinematic":
		cinematic_overlay.show_lines(segment.lines)
	else:
		dialogue_box.show_lines(segment.lines)


func _on_segment_finished() -> void:
	current_index += 1
	_play_current_segment()
