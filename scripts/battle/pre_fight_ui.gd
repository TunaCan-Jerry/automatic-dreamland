extends Control

signal setup_complete(allies: Array)

var ally_roster: Array[CombatantData] = []
var placed_allies: Dictionary = {}
var selected_ally: CombatantData = null
var battle_manager: Node

@onready var roster_list: VBoxContainer = $RosterPanel/ScrollContainer/VBoxContainer
@onready var start_button: Button = $StartButton
@onready var info_panel: VBoxContainer = $InfoPanel/ScrollContainer/VBoxContainer
@onready var instructions: Label = $Instructions


func setup(roster: Array[Dictionary], manager: Node) -> void:
	battle_manager = manager
	for data in roster:
		var combatant := CombatantData.new(data)
		ally_roster.append(combatant)
	_build_roster_ui()
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	instructions.text = "Select a character, then click an ally hex to place them."


func _build_roster_ui() -> void:
	for child in roster_list.get_children():
		child.queue_free()

	for ally in ally_roster:
		var btn := Button.new()
		var is_placed := ally in placed_allies.values()
		btn.text = ally.combatant_name + (" ✓" if is_placed else "")
		btn.pressed.connect(_on_ally_selected.bind(ally))
		if is_placed and selected_ally != ally:
			btn.modulate = Color(0.6, 0.6, 0.6)
		roster_list.add_child(btn)


func _on_ally_selected(ally: CombatantData) -> void:
	selected_ally = ally
	_show_ally_info(ally)
	instructions.text = "Click an ally hex (green) to place " + ally.combatant_name


func _show_ally_info(ally: CombatantData) -> void:
	for child in info_panel.get_children():
		child.queue_free()

	var name_label := Label.new()
	name_label.text = ally.combatant_name
	name_label.add_theme_font_size_override("font_size", 18)
	info_panel.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = "HP: %d  MP: %d\nATK: %d  DEF: %d\nMAG: %d  RES: %d\nSPD: %d  ACC: %d\nEVA: %d  LCK: %d" % [
		ally.stats.get("hp", 0), ally.stats.get("mp", 0),
		ally.stats.get("attack", 0), ally.stats.get("defense", 0),
		ally.stats.get("magic", 0), ally.stats.get("resistance", 0),
		ally.stats.get("speed", 0), ally.stats.get("accuracy", 0),
		ally.stats.get("evasion", 0), ally.stats.get("luck", 0)]
	info_panel.add_child(stats_label)

	var sep1 := HSeparator.new()
	info_panel.add_child(sep1)

	var priority_label := Label.new()
	priority_label.text = "Targeting Priority:"
	info_panel.add_child(priority_label)

	var priority_dropdown := OptionButton.new()
	var priorities := ["nearest", "weakest", "strongest", "protect"]
	for p in priorities:
		priority_dropdown.add_item(p.capitalize())
	var idx := priorities.find(ally.targeting_priority)
	if idx >= 0:
		priority_dropdown.selected = idx
	priority_dropdown.item_selected.connect(func(i: int): ally.targeting_priority = priorities[i])
	info_panel.add_child(priority_dropdown)

	var sep2 := HSeparator.new()
	info_panel.add_child(sep2)

	var abilities_label := Label.new()
	abilities_label.text = "Abilities:"
	info_panel.add_child(abilities_label)

	for ability in ally.abilities:
		var ab_label := Label.new()
		ab_label.text = "  %s (%s, range:%d, MP:%d)" % [
			ability.name, ability.type, ability.ability_range, ability.mp_cost]
		info_panel.add_child(ab_label)


func on_hex_clicked(hex_pos: Vector2i) -> void:
	if selected_ally == null:
		return
	if battle_manager.grid.tile_zones.get(hex_pos) != HexGrid.Zone.ALLY:
		return
	if battle_manager.grid.is_occupied(hex_pos):
		return

	for pos in placed_allies.keys():
		if placed_allies[pos] == selected_ally:
			battle_manager.grid.remove_combatant(pos)
			placed_allies.erase(pos)
			break

	placed_allies[hex_pos] = selected_ally
	selected_ally.position = hex_pos
	battle_manager.grid.place_combatant(hex_pos, selected_ally)
	battle_manager._refresh_tile_states()

	selected_ally = null
	_build_roster_ui()
	instructions.text = "Select a character, then click an ally hex to place them."

	start_button.disabled = placed_allies.size() < ally_roster.size()
	if not start_button.disabled:
		instructions.text = "All placed! Click Start Battle or adjust positions."


func _on_start_pressed() -> void:
	var allies: Array = []
	for pos in placed_allies:
		allies.append(placed_allies[pos])
	setup_complete.emit(allies)
