extends PanelContainer

signal dialogue_finished

var lines: Array = []
var current_line: int = 0
var typing: bool = false
var full_text: String = ""

@onready var speaker_label: Label = $MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $MarginContainer/VBoxContainer/TextLabel


func _ready() -> void:
	visible = false
	set_process_input(false)


func show_lines(dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_line = 0
	visible = true
	set_process_input(true)
	_display_current_line()


func _display_current_line() -> void:
	if current_line >= lines.size():
		_finish()
		return
	var line: Dictionary = lines[current_line]
	speaker_label.text = line.get("speaker", "")
	speaker_label.visible = speaker_label.text != ""
	full_text = line.get("text", "")
	text_label.text = ""
	typing = true
	_type_text()


func _type_text() -> void:
	for i in range(full_text.length()):
		if not typing:
			text_label.text = full_text
			return
		text_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(0.02).timeout
	typing = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if typing:
			typing = false
			text_label.text = full_text
		else:
			current_line += 1
			_display_current_line()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	visible = false
	set_process_input(false)
	dialogue_finished.emit()
