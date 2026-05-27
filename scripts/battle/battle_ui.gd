extends Control

signal commander_heal_requested(target: CombatantData)
signal commander_retreat_requested
signal speed_changed(scale: float)
signal pause_toggled

var battle_manager: Node
var selecting_heal_target: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


@onready var turn_order: HBoxContainer = $TopBar/TurnOrder
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var commander_btn: Button = $BottomBar/CommanderButton
@onready var heal_btn: Button = $BottomBar/HealButton
@onready var retreat_btn: Button = $BottomBar/RetreatButton
@onready var speed_btn: Button = $BottomBar/SpeedButton
@onready var pause_btn: Button = $BottomBar/PauseButton
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/VBox/ResultLabel
@onready var retry_btn: Button = $ResultPanel/VBox/RetryButton
@onready var heal_prompt: Label = $HealPrompt

var current_speed_idx: int = 0
var speed_options: Array[float] = [1.0, 2.0, 4.0]


func setup(manager: Node) -> void:
	battle_manager = manager
	commander_btn.pressed.connect(_on_commander_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	retreat_btn.pressed.connect(_on_retreat_pressed)
	speed_btn.pressed.connect(_on_speed_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	result_panel.visible = false
	heal_btn.visible = false
	retreat_btn.visible = false
	heal_prompt.visible = false
	update_commander_button()


func update_turn_order(queue: Array) -> void:
	for child in turn_order.get_children():
		child.queue_free()
	for combatant in queue:
		var label := Label.new()
		label.text = combatant.combatant_name
		label.add_theme_color_override("font_color",
			Color(0.3, 0.9, 0.3) if combatant.team == "ally" else Color(0.9, 0.3, 0.3))
		label.add_theme_font_size_override("font_size", 12)
		turn_order.add_child(label)

		var sep := Label.new()
		sep.text = " → "
		sep.add_theme_font_size_override("font_size", 10)
		sep.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		turn_order.add_child(sep)


func update_commander_button() -> void:
	if battle_manager and battle_manager.state:
		var remaining: int = battle_manager.state.commander_actions_remaining
		commander_btn.disabled = remaining <= 0
		commander_btn.text = "Commander (%d)" % remaining


func show_win() -> void:
	result_panel.visible = true
	result_label.text = "VICTORY!"
	retry_btn.text = "Play Again"


func show_lose() -> void:
	result_panel.visible = true
	result_label.text = "DEFEATED"
	retry_btn.text = "Retry"


func on_character_clicked(combatant: CombatantData) -> void:
	if selecting_heal_target and combatant.team == "ally":
		selecting_heal_target = false
		heal_prompt.visible = false
		heal_btn.visible = false
		retreat_btn.visible = false
		commander_heal_requested.emit(combatant)


func _on_commander_pressed() -> void:
	heal_btn.visible = not heal_btn.visible
	retreat_btn.visible = not retreat_btn.visible


func _on_heal_pressed() -> void:
	selecting_heal_target = true
	heal_prompt.visible = true
	heal_prompt.text = "Click an ally to heal (30 HP)"
	battle_manager.waiting_for_commander = true
	heal_btn.visible = false
	retreat_btn.visible = false


func _on_retreat_pressed() -> void:
	heal_btn.visible = false
	retreat_btn.visible = false
	commander_retreat_requested.emit()


func _on_speed_pressed() -> void:
	current_speed_idx = (current_speed_idx + 1) % speed_options.size()
	var new_speed := speed_options[current_speed_idx]
	speed_btn.text = "%dx" % int(new_speed)
	speed_changed.emit(new_speed)


func _on_pause_pressed() -> void:
	pause_toggled.emit()
	pause_btn.text = "▶ Resume" if battle_manager.paused else "⏸ Pause"


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
