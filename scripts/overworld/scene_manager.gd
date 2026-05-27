extends Node

var quest_state := QuestState.new()
var transition_overlay: ColorRect
var _dialogue_manager: CanvasLayer


func _ready() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.anchors_preset = Control.PRESET_FULL_RECT
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(transition_overlay)
	add_child(canvas)

	_dialogue_manager = CanvasLayer.new()
	_dialogue_manager.set_script(load("res://scripts/ui/dialogue_manager.gd"))
	_dialogue_manager.layer = 90
	add_child(_dialogue_manager)


func get_dialogue_manager() -> CanvasLayer:
	return _dialogue_manager


func transition_to(scene_path: String) -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	var tween2 := create_tween()
	tween2.tween_property(transition_overlay, "color:a", 0.0, 0.3)
	await tween2.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
