# Opening Experience MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable opening sequence — walk around a village, talk to NPCs, get a quest, fight a tutorial battle, return to find the village destroyed, rescue Claira.

**Architecture:** Grid-based top-down overworld with TileMap. Dialogue system with two modes (normal bottom box + cinematic overlay). Quest state machine drives NPC dialogue and scene events. Scene transitions via autoload SceneManager. Tutorial battle hooks into existing battle system.

**Tech Stack:** Godot 4.x, GDScript, TileMap for grid maps.

**Spec:** `docs/specs/2026-05-14-opening-mvp-spec.md`

---

## File Structure

```
scripts/
├── data/
│   ├── dialogue_data.gd          # All dialogue content for the opening
│   ├── quest_state.gd            # Quest state machine
│   └── encounter_data.gd         # (modify) Add tutorial_encounter()
├── ui/
│   ├── dialogue_box.gd           # Bottom text box
│   ├── cinematic_overlay.gd      # Full screen story overlay
│   └── dialogue_manager.gd       # Plays dialogue sequences, picks display mode
├── overworld/
│   ├── player.gd                 # Grid movement + interact
│   ├── npc.gd                    # NPC with dialogue + trigger mode
│   ├── follow_npc.gd             # Companion NPC that follows player
│   ├── scene_manager.gd          # Scene transitions (autoload)
│   ├── village_map.gd            # Village scene script — quest triggers, NPC setup
│   ├── road_map.gd               # Road scene script
│   ├── homestead_map.gd          # Homestead scene script
│   └── village_destroyed_map.gd  # Destroyed village scene script
└── battle/
    └── battle_manager.gd         # (modify) Accept encounter/ally params, tutorial mode

scenes/
├── overworld/
│   ├── village.tscn              # Village TileMap + NPCs
│   ├── road.tscn                 # Road TileMap + critter
│   ├── homestead.tscn            # Homestead TileMap + NPC
│   └── village_destroyed.tscn    # Destroyed village TileMap + Claira
└── ui/
    ├── dialogue_box.tscn         # Bottom dialogue UI
    └── cinematic_overlay.tscn    # Full screen overlay UI
```

---

## Task 1: Quest State Machine

**Files:**
- Create: `scripts/data/quest_state.gd`

The simplest piece — a state enum with signals. Everything else reads from this.

- [ ] **Step 1: Create QuestState**

Create `scripts/data/quest_state.gd`:

```gdscript
class_name QuestState
extends RefCounted

signal state_changed(new_state: int)

enum State {
	EXPLORE_VILLAGE,
	TALKED_TO_CLAIRA,
	WALKING_TO_ELDER,
	AT_ELDER,
	GOT_QUEST,
	ON_THE_ROAD,
	AT_HOMESTEAD,
	RETURNING,
	VILLAGE_DESTROYED,
	FOUND_CLAIRA,
	LEAVING
}

var current_state: int = State.EXPLORE_VILLAGE


func advance() -> void:
	if current_state < State.LEAVING:
		current_state += 1
		state_changed.emit(current_state)


func set_state(state: int) -> void:
	current_state = state
	state_changed.emit(current_state)


func is_at_least(state: int) -> bool:
	return current_state >= state
```

- [ ] **Step 2: Commit**

```bash
git add scripts/data/quest_state.gd
git commit -m "feat: quest state machine for opening sequence"
```

---

## Task 2: Dialogue System — Data

**Files:**
- Create: `scripts/data/dialogue_data.gd`

All dialogue content for the opening. Each conversation is a static method returning an array of line dictionaries.

- [ ] **Step 1: Create DialogueData**

Create `scripts/data/dialogue_data.gd`:

```gdscript
class_name DialogueData
extends RefCounted

# Each method returns Array of {speaker: String, text: String, mode: String}
# mode: "normal" (bottom text box) or "cinematic" (full screen overlay)

static func claira_first_meeting() -> Array:
	return [
		{speaker = "Claira", text = "There you are. I was starting to think you'd sleep through the whole morning.", mode = "normal"},
		{speaker = "Claira", text = "Grandma wanted to see you, by the way. Something about an errand.", mode = "normal"},
		{speaker = "Claira", text = "Come on, I'll walk with you.", mode = "normal"},
	]

static func tree_kiss() -> Array:
	return [
		{speaker = "", text = "Claira pulls you behind the old tree.", mode = "cinematic"},
		{speaker = "", text = "A stolen moment. The village sounds feel far away.", mode = "cinematic"},
		{speaker = "Claira", text = "...okay. Grandma's waiting. Try to look normal.", mode = "normal"},
	]

static func elder_conversation() -> Array:
	return [
		{speaker = "Elder", text = "Come in, come in. I just put the kettle on.", mode = "normal"},
		{speaker = "Elder", text = "Sit down. How are you? How's your father's back?", mode = "normal"},
		{speaker = "You", text = "He says it's fine. It's not fine.", mode = "normal"},
		{speaker = "Elder", text = "Ha. That sounds like him.", mode = "normal"},
		{speaker = "Elder", text = "Listen, I need a favor. Could you run a package to the Millers' homestead?", mode = "normal"},
		{speaker = "Elder", text = "And while you're there — ask them for a small box I left last visit. They'll know the one.", mode = "normal"},
		{speaker = "You", text = "Sure. I'll head out now.", mode = "normal"},
		{speaker = "Elder", text = "No rush. Well — before dark, maybe. Be careful on the road.", mode = "normal"},
		{speaker = "Claira", text = "I'll stay and help grandma with the garden. Don't take forever.", mode = "normal"},
	]

static func tavern_keeper() -> Array:
	return [
		{speaker = "Tavern Keeper", text = "Morning! You look just like your mother at that age, you know that?", mode = "normal"},
		{speaker = "Tavern Keeper", text = "Your dad was in here last night. Said the south field's coming in nicely this year.", mode = "normal"},
		{speaker = "Tavern Keeper", text = "Tell your folks I said hello!", mode = "normal"},
	]

static func tavern_keeper_after_quest() -> Array:
	return [
		{speaker = "Tavern Keeper", text = "Off on an errand? Don't let the road critters give you trouble!", mode = "normal"},
	]

static func old_couple() -> Array:
	return [
		{speaker = "Old Man", text = "Good morning, dear. Beautiful day, isn't it?", mode = "normal"},
		{speaker = "Old Woman", text = "You remind me of your father when he was young. Same walk.", mode = "normal"},
		{speaker = "Old Man", text = "The birds have been flying east for days now. All of them. Odd, that.", mode = "normal"},
		{speaker = "Old Woman", text = "Oh, don't worry the child with your bird nonsense.", mode = "normal"},
	]

static func dad_greeting() -> Array:
	return [
		{speaker = "Dad", text = "Hey, kiddo. Have a good day out there.", mode = "normal"},
	]

static func dad_after_quest() -> Array:
	return [
		{speaker = "Dad", text = "Be safe out there. And don't dawdle — your mother worries.", mode = "normal"},
	]

static func house_photo() -> Array:
	return [
		{speaker = "", text = "A family photo on the shelf. Mom, Dad, you. A normal morning.", mode = "normal"},
	]

static func flavor_kid() -> Array:
	return [
		{speaker = "Kid", text = "Tag! You're it! ...oh wait, you're a grown-up. Never mind.", mode = "normal"},
	]

static func flavor_farmer() -> Array:
	return [
		{speaker = "Farmer", text = "Morning! Crops are looking good this season.", mode = "normal"},
	]

static func flavor_patron() -> Array:
	return [
		{speaker = "Patron", text = "Little early for the tavern, isn't it? ...don't judge me.", mode = "normal"},
	]

static func homestead_npc() -> Array:
	return [
		{speaker = "Miller", text = "Oh, from the elder? Thank you kindly.", mode = "normal"},
		{speaker = "Miller", text = "And here's that box she left. Told her I'd keep it safe.", mode = "normal"},
		{speaker = "", text = "You received the elder's trinket.", mode = "normal"},
		{speaker = "Miller", text = "Safe travels back now.", mode = "normal"},
	]

static func smoke_on_horizon() -> Array:
	return [
		{speaker = "", text = "As you crest the hill, you see smoke rising from the direction of the village.", mode = "cinematic"},
		{speaker = "", text = "Too much smoke.", mode = "cinematic"},
	]

static func finding_claira() -> Array:
	return [
		{speaker = "", text = "The village is gone.", mode = "cinematic"},
		{speaker = "", text = "Everything is ash and ember. The fountain is shattered. The tavern is a skeleton.", mode = "cinematic"},
		{speaker = "", text = "Near the elder's house, a faint shimmer in the air. A barrier of light, cracking, fading.", mode = "cinematic"},
		{speaker = "", text = "Behind it — Claira. Alive. Barely.", mode = "cinematic"},
		{speaker = "", text = "The barrier shatters as you reach her. The elder's last magic, spent.", mode = "cinematic"},
		{speaker = "Claira", text = "She... grandma, she...", mode = "normal"},
		{speaker = "Claira", text = "...she told me to stay inside the light. No matter what.", mode = "normal"},
		{speaker = "Claira", text = "...I could hear everything.", mode = "normal"},
	]

static func leaving_village() -> Array:
	return [
		{speaker = "", text = "The trinket. Claira. And the road ahead.", mode = "cinematic"},
		{speaker = "", text = "There's nothing left here.", mode = "cinematic"},
	]
```

- [ ] **Step 2: Commit**

```bash
git add scripts/data/dialogue_data.gd
git commit -m "feat: all opening dialogue content"
```

---

## Task 3: Dialogue System — UI

**Files:**
- Create: `scripts/ui/dialogue_box.gd`
- Create: `scenes/ui/dialogue_box.tscn`
- Create: `scripts/ui/cinematic_overlay.gd`
- Create: `scenes/ui/cinematic_overlay.tscn`
- Create: `scripts/ui/dialogue_manager.gd`

Three scripts: the bottom text box, the cinematic overlay, and the manager that coordinates them.

- [ ] **Step 1: Create DialogueBox**

Create `scripts/ui/dialogue_box.gd`:

```gdscript
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


func _finish() -> void:
	visible = false
	set_process_input(false)
	dialogue_finished.emit()
```

- [ ] **Step 2: Create DialogueBox scene**

Create `scenes/ui/dialogue_box.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/dialogue_box.gd" id="1"]

[node name="DialogueBox" type="PanelContainer"]
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = -160.0
offset_right = -40.0
grow_horizontal = 2
grow_vertical = 0
script = ExtResource("1")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 12
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 12

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="SpeakerLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Speaker"

[node name="TextLabel" type="RichTextLabel" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 80)
bbcode_enabled = true
fit_content = true
theme_override_font_sizes/normal_font_size = 14
```

- [ ] **Step 3: Create CinematicOverlay**

Create `scripts/ui/cinematic_overlay.gd`:

```gdscript
extends ColorRect

signal dialogue_finished

var lines: Array = []
var current_line: int = 0
var typing: bool = false
var full_text: String = ""

@onready var speaker_label: Label = $CenterContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $CenterContainer/VBoxContainer/TextLabel


func _ready() -> void:
	visible = false
	set_process_input(false)
	color = Color(0, 0, 0, 0.85)


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
		await get_tree().create_timer(0.03).timeout
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


func _finish() -> void:
	visible = false
	set_process_input(false)
	dialogue_finished.emit()
```

- [ ] **Step 4: Create CinematicOverlay scene**

Create `scenes/ui/cinematic_overlay.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/cinematic_overlay.gd" id="1"]

[node name="CinematicOverlay" type="ColorRect"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.85)
script = ExtResource("1")

[node name="CenterContainer" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="CenterContainer"]
layout_mode = 2
alignment = 1

[node name="SpeakerLabel" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 20
text = "Speaker"

[node name="TextLabel" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 24
autowrap_mode = 2
text = "Dialogue text here"
```

- [ ] **Step 5: Create DialogueManager**

Create `scripts/ui/dialogue_manager.gd`:

```gdscript
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
	# Group consecutive lines by mode into segments
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
```

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/dialogue_box.gd scenes/ui/dialogue_box.tscn scripts/ui/cinematic_overlay.gd scenes/ui/cinematic_overlay.tscn scripts/ui/dialogue_manager.gd
git commit -m "feat: dialogue system — text box, cinematic overlay, manager"
```

---

## Task 4: Scene Manager (Autoload)

**Files:**
- Create: `scripts/overworld/scene_manager.gd`
- Modify: `project.godot` — register as autoload

Handles scene transitions with fade to black. Carries quest state across scenes.

- [ ] **Step 1: Create SceneManager**

Create `scripts/overworld/scene_manager.gd`:

```gdscript
extends Node

var quest_state := QuestState.new()
var transition_overlay: ColorRect
var dialogue_manager_scene := preload("res://scripts/ui/dialogue_manager.gd")
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

	# Dialogue manager available globally
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
```

- [ ] **Step 2: Register as autoload**

Add to `project.godot` under a new `[autoload]` section:

```ini
[autoload]
SceneManager="*res://scripts/overworld/scene_manager.gd"
```

- [ ] **Step 3: Commit**

```bash
git add scripts/overworld/scene_manager.gd project.godot
git commit -m "feat: scene manager autoload with fade transitions and quest state"
```

---

## Task 5: Player Character (Grid Movement)

**Files:**
- Create: `scripts/overworld/player.gd`

Grid-based movement with interact button. Placeholder colored square.

- [ ] **Step 1: Create Player script**

Create `scripts/overworld/player.gd`:

```gdscript
extends Node2D

signal interacted(facing_pos: Vector2i)

const TILE_SIZE := 16
const MOVE_SPEED := 0.12

var grid_pos: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var moving: bool = false
var input_enabled: bool = true
var tilemap: TileMapLayer

var body: ColorRect


func _ready() -> void:
	body = ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = Color(0.2, 0.4, 0.9)
	add_child(body)


func setup(start_pos: Vector2i, map: TileMapLayer) -> void:
	grid_pos = start_pos
	tilemap = map
	position = Vector2(grid_pos) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)


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
	if tilemap == null:
		return false
	var tile_data := tilemap.get_cell_tile_data(target)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("walkable") if tile_data.has_custom_data("walkable") else false


func _move_to(target: Vector2i) -> void:
	moving = true
	grid_pos = target
	var target_pixel := Vector2(target) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	var tween := create_tween()
	tween.tween_property(self, "position", target_pixel, MOVE_SPEED)
	await tween.finished
	moving = false


func disable_input() -> void:
	input_enabled = false


func enable_input() -> void:
	input_enabled = true
```

- [ ] **Step 2: Commit**

```bash
git add scripts/overworld/player.gd
git commit -m "feat: grid-based player movement with interact button"
```

---

## Task 6: NPC System

**Files:**
- Create: `scripts/overworld/npc.gd`
- Create: `scripts/overworld/follow_npc.gd`

NPCs with dialogue, trigger modes, and a follow variant for Claira.

- [ ] **Step 1: Create NPC script**

Create `scripts/overworld/npc.gd`:

```gdscript
extends Node2D

signal npc_triggered(npc: Node2D)

@export var npc_name: String = "NPC"
@export var trigger_mode: String = "interact"  # "auto" or "interact"
@export var repeatable: bool = true
@export var npc_color: Color = Color(0.8, 0.6, 0.2)

var grid_pos: Vector2i
var has_triggered: bool = false
var dialogue_callback: Callable  # func(quest_state: int) -> Array

var body: ColorRect
var name_label: Label


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


func setup(pos: Vector2i, tile_size: int = 16) -> void:
	grid_pos = pos
	position = Vector2(pos) * tile_size + Vector2(tile_size / 2.0, tile_size / 2.0)


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
```

- [ ] **Step 2: Create FollowNPC script**

Create `scripts/overworld/follow_npc.gd`:

```gdscript
extends Node2D

const TILE_SIZE := 16

var grid_pos: Vector2i
var following: bool = false
var target_node: Node2D
var position_history: Array[Vector2i] = []
var npc_color: Color = Color(0.9, 0.5, 0.3)

var body: ColorRect
var name_label: Label


func _ready() -> void:
	body = ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = npc_color
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


func start_following(target: Node2D) -> void:
	following = true
	target_node = target
	position_history.clear()
	position_history.append(grid_pos)


func stop_following() -> void:
	following = false
	target_node = null


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
```

- [ ] **Step 3: Commit**

```bash
git add scripts/overworld/npc.gd scripts/overworld/follow_npc.gd
git commit -m "feat: NPC system with auto/interact triggers and follow companion"
```

---

## Task 7: Village Map Scene

**Files:**
- Create: `scripts/overworld/village_map.gd`
- Create: `scenes/overworld/village.tscn`

The main village scene. TileMap, player, NPCs, quest triggers. This is the biggest task.

- [ ] **Step 1: Create village_map.gd**

Create `scripts/overworld/village_map.gd`:

```gdscript
extends Node2D

const TILE_SIZE := 16

var player: Node2D
var claira_follow: Node2D
var npcs: Array[Node2D] = []
var quest_state: QuestState
var dialogue_manager: CanvasLayer

@onready var tilemap: TileMapLayer = $TileMap


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()

	_setup_player()
	_setup_npcs()
	_setup_claira()


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(10, 18), tilemap)
	player.interacted.connect(_on_player_interact)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_claira() -> void:
	claira_follow = Node2D.new()
	claira_follow.set_script(load("res://scripts/overworld/follow_npc.gd"))
	add_child(claira_follow)
	claira_follow.setup(Vector2i(10, 12))
	claira_follow.visible = false


func _setup_npcs() -> void:
	_add_npc("Tavern Keeper", Vector2i(9, 7), "interact", Color(0.8, 0.6, 0.2), func(state):
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.tavern_keeper_after_quest()
		return DialogueData.tavern_keeper()
	)
	_add_npc("Patron", Vector2i(11, 7), "interact", Color(0.6, 0.5, 0.4), func(_s):
		return DialogueData.flavor_patron()
	)
	_add_npc("Old Man", Vector2i(8, 11), "interact", Color(0.7, 0.7, 0.7), func(_s):
		return DialogueData.old_couple()
	)
	_add_npc("Kid", Vector2i(11, 11), "interact", Color(0.9, 0.7, 0.3), func(_s):
		return DialogueData.flavor_kid()
	)
	_add_npc("Dad", Vector2i(7, 20), "interact", Color(0.3, 0.6, 0.3), func(state):
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.dad_after_quest()
		return DialogueData.dad_greeting()
	)
	_add_npc("Farmer", Vector2i(12, 21), "interact", Color(0.5, 0.7, 0.3), func(_s):
		return DialogueData.flavor_farmer()
	)

	# Claira as auto-trigger NPC in the square (replaced by follow NPC after talking)
	var claira_npc = _add_npc("Claira", Vector2i(10, 12), "auto", Color(0.9, 0.5, 0.3), func(_s):
		return DialogueData.claira_first_meeting()
	, false)

	# Elder as auto-trigger at her house
	_add_npc("Elder", Vector2i(10, 25), "auto", Color(0.7, 0.5, 0.7), func(_s):
		return DialogueData.elder_conversation()
	, false)

	# House door
	_add_npc("Home", Vector2i(9, 16), "interact", Color(0.5, 0.3, 0.2), func(_s):
		return DialogueData.house_photo()
	)


func _add_npc(npc_name: String, pos: Vector2i, trigger: String, color: Color, dialogue_cb: Callable, repeatable: bool = true) -> Node2D:
	var npc = Node2D.new()
	npc.set_script(load("res://scripts/overworld/npc.gd"))
	npc.npc_name = npc_name
	npc.trigger_mode = trigger
	npc.repeatable = repeatable
	npc.npc_color = color
	add_child(npc)
	npc.setup(pos)
	npc.set_dialogue(dialogue_cb)
	npcs.append(npc)
	return npc


func _process(_delta: float) -> void:
	if dialogue_manager.is_active():
		return

	# Check auto-trigger NPCs
	for npc in npcs:
		if npc.check_auto_trigger(player.grid_pos):
			_trigger_npc(npc)
			return

	# Update Claira follow
	if claira_follow.visible and claira_follow.following:
		claira_follow.update_follow(player.grid_pos)

	# Check zone triggers
	_check_zone_triggers()


func _on_player_interact(facing_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return
	for npc in npcs:
		if npc.grid_pos == facing_pos and npc.trigger_mode == "interact" and npc.can_trigger():
			_trigger_npc(npc)
			return


func _trigger_npc(npc: Node2D) -> void:
	var lines = npc.get_dialogue(quest_state.current_state)
	if lines.is_empty():
		return

	npc.mark_triggered()
	player.disable_input()
	dialogue_manager.play(lines)
	await dialogue_manager.dialogue_finished
	player.enable_input()

	_handle_post_dialogue(npc)


func _handle_post_dialogue(npc: Node2D) -> void:
	match npc.npc_name:
		"Claira":
			if quest_state.current_state == QuestState.State.EXPLORE_VILLAGE:
				quest_state.set_state(QuestState.State.TALKED_TO_CLAIRA)
				npc.visible = false
				claira_follow.visible = true
				claira_follow.setup(player.grid_pos + Vector2i(0, 1))
				claira_follow.start_following(player)
		"Elder":
			if quest_state.current_state == QuestState.State.WALKING_TO_ELDER or quest_state.current_state == QuestState.State.AT_ELDER:
				quest_state.set_state(QuestState.State.GOT_QUEST)
				claira_follow.stop_following()
				claira_follow.visible = false


func _check_zone_triggers() -> void:
	# Tree kiss trigger — near the tree between houses and elder's house
	if quest_state.current_state == QuestState.State.TALKED_TO_CLAIRA:
		if player.grid_pos == Vector2i(8, 22):  # The tree position
			quest_state.set_state(QuestState.State.WALKING_TO_ELDER)
			player.disable_input()
			dialogue_manager.play(DialogueData.tree_kiss())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.AT_ELDER)
			player.enable_input()

	# Village exit
	if quest_state.current_state == QuestState.State.GOT_QUEST:
		if player.grid_pos.y <= 1:
			quest_state.set_state(QuestState.State.ON_THE_ROAD)
			SceneManager.transition_to("res://scenes/overworld/road.tscn")
```

- [ ] **Step 2: Create village TileMap scene**

Create `scenes/overworld/village.tscn` in the Godot editor or via script. The scene needs:
- Root: Node2D with `village_map.gd` script
- Child: TileMapLayer named "TileMap"
- TileSet with custom data layer "walkable" (bool)
- Tile types: grass (green, walkable=true), path (tan, walkable=true), water (blue, walkable=false), building (brown, walkable=false), door (dark brown, walkable=true), field (yellow-green, walkable=true), tree (dark green, walkable=false)
- Layout: ~20x30 grid matching the village design

Since creating a full TileMap programmatically is complex, the scene file should be built in the Godot editor using the TileMap tools. For the MVP, create a minimal scene that the implementer can paint in the editor:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/overworld/village_map.gd" id="1"]

[node name="Village" type="Node2D"]
script = ExtResource("1")

[node name="TileMap" type="TileMapLayer" parent="."]
```

The TileSet and tile painting must be done in the Godot editor — the implementer should:
1. Create a new TileSet on the TileMapLayer
2. Add a custom data layer "walkable" (type: bool)
3. Create tile sources for each type (can use atlas of colored squares or individual scenes)
4. Paint the village layout per the design doc

- [ ] **Step 3: Commit**

```bash
git add scripts/overworld/village_map.gd scenes/overworld/village.tscn
git commit -m "feat: village map with NPCs, quest triggers, and dialogue integration"
```

---

## Task 8: Road and Homestead Scenes

**Files:**
- Create: `scripts/overworld/road_map.gd`
- Create: `scenes/overworld/road.tscn`
- Create: `scripts/overworld/homestead_map.gd`
- Create: `scenes/overworld/homestead.tscn`
- Modify: `scripts/data/encounter_data.gd` — add tutorial_encounter()

- [ ] **Step 1: Add tutorial encounter**

Add to `scripts/data/encounter_data.gd`:

```gdscript
static func tutorial_encounter() -> EncounterData:
	var encounter = EncounterData.new()
	encounter.enemies = [
		{
			"name": "Slime",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"targeting_priority": "nearest",
			"stats": {"hp": 20, "mp": 0, "attack": 5, "defense": 2, "magic": 1, "resistance": 1, "speed": 6, "accuracy": 70, "evasion": 5, "luck": 2},
			"abilities": [{"name": "Bump", "type": "physical", "power_mult": 1.0, "mp_cost": 0, "range": 1, "target": "enemy", "cooldown": 0}]
		},
		{
			"name": "Slime",
			"team": "enemy",
			"position": Vector2i(3, -1),
			"targeting_priority": "nearest",
			"stats": {"hp": 20, "mp": 0, "attack": 5, "defense": 2, "magic": 1, "resistance": 1, "speed": 7, "accuracy": 70, "evasion": 5, "luck": 2},
			"abilities": [{"name": "Bump", "type": "physical", "power_mult": 1.0, "mp_cost": 0, "range": 1, "target": "enemy", "cooldown": 0}]
		}
	]
	return encounter

static func tutorial_ally() -> Array[Dictionary]:
	return [
		{
			"name": "You",
			"team": "ally",
			"targeting_priority": "nearest",
			"stats": {"hp": 100, "mp": 30, "attack": 10, "defense": 8, "magic": 5, "resistance": 5, "speed": 9, "accuracy": 85, "evasion": 8, "luck": 5},
			"abilities": [
				{"name": "Shield Bash", "type": "physical", "power_mult": 1.2, "mp_cost": 8, "range": 1, "target": "enemy", "cooldown": 2, "push": 1}
			]
		}
	]
```

- [ ] **Step 2: Create road_map.gd**

Create `scripts/overworld/road_map.gd`:

```gdscript
extends Node2D

const TILE_SIZE := 16

var player: Node2D
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var battle_triggered: bool = false

@onready var tilemap: TileMapLayer = $TileMap


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()
	_setup_player()


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(5, 28), tilemap)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _process(_delta: float) -> void:
	if dialogue_manager.is_active():
		return

	# Tutorial battle trigger at midpoint
	if not battle_triggered and player.grid_pos.y <= 15:
		battle_triggered = true
		_start_tutorial_battle()

	# Exit to homestead
	if battle_triggered and player.grid_pos.y <= 1:
		SceneManager.transition_to("res://scenes/overworld/homestead.tscn")


func _start_tutorial_battle() -> void:
	player.disable_input()
	# TODO: transition to battle scene with tutorial encounter
	# For now, skip the battle and just let them continue
	# When battle system supports passing encounter data:
	# SceneManager.pending_encounter = EncounterData.tutorial_encounter()
	# SceneManager.pending_allies = EncounterData.tutorial_ally()
	# SceneManager.return_scene = "res://scenes/overworld/road.tscn"
	# SceneManager.transition_to("res://scenes/battle/battle.tscn")
	player.enable_input()
```

- [ ] **Step 3: Create homestead_map.gd**

Create `scripts/overworld/homestead_map.gd`:

```gdscript
extends Node2D

const TILE_SIZE := 16

var player: Node2D
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var trinket_received: bool = false

@onready var tilemap: TileMapLayer = $TileMap


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()
	quest_state.set_state(QuestState.State.AT_HOMESTEAD)
	_setup_player()
	_setup_npc()


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(5, 8), tilemap)
	player.interacted.connect(_on_interact)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_npc() -> void:
	var npc = Node2D.new()
	npc.set_script(load("res://scripts/overworld/npc.gd"))
	npc.npc_name = "Miller"
	npc.trigger_mode = "interact"
	npc.npc_color = Color(0.7, 0.6, 0.4)
	add_child(npc)
	npc.setup(Vector2i(5, 4))
	npc.set_dialogue(func(_s): return DialogueData.homestead_npc())


func _on_interact(facing_pos: Vector2i) -> void:
	if facing_pos == Vector2i(5, 4) and not trinket_received:
		trinket_received = true
		player.disable_input()
		dialogue_manager.play(DialogueData.homestead_npc())
		await dialogue_manager.dialogue_finished
		player.enable_input()


func _process(_delta: float) -> void:
	if dialogue_manager.is_active():
		return

	# Exit triggers return journey
	if trinket_received and player.grid_pos.y >= 9:
		quest_state.set_state(QuestState.State.RETURNING)
		player.disable_input()
		dialogue_manager.play(DialogueData.smoke_on_horizon())
		await dialogue_manager.dialogue_finished
		SceneManager.transition_to("res://scenes/overworld/village_destroyed.tscn")
```

- [ ] **Step 4: Create minimal road and homestead scenes**

`scenes/overworld/road.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/overworld/road_map.gd" id="1"]
[node name="Road" type="Node2D"]
script = ExtResource("1")
[node name="TileMap" type="TileMapLayer" parent="."]
```

`scenes/overworld/homestead.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/overworld/homestead_map.gd" id="1"]
[node name="Homestead" type="Node2D"]
script = ExtResource("1")
[node name="TileMap" type="TileMapLayer" parent="."]
```

Both need TileMap painting in the editor.

- [ ] **Step 5: Commit**

```bash
git add scripts/data/encounter_data.gd scripts/overworld/road_map.gd scenes/overworld/road.tscn scripts/overworld/homestead_map.gd scenes/overworld/homestead.tscn
git commit -m "feat: road and homestead scenes with tutorial battle hook"
```

---

## Task 9: Village Destroyed Scene

**Files:**
- Create: `scripts/overworld/village_destroyed_map.gd`
- Create: `scenes/overworld/village_destroyed.tscn`

Same layout as village but dark, ruined. Find Claira, leave.

- [ ] **Step 1: Create village_destroyed_map.gd**

Create `scripts/overworld/village_destroyed_map.gd`:

```gdscript
extends Node2D

const TILE_SIZE := 16

var player: Node2D
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var found_claira: bool = false

@onready var tilemap: TileMapLayer = $TileMap


func _ready() -> void:
	quest_state = SceneManager.quest_state
	quest_state.set_state(QuestState.State.VILLAGE_DESTROYED)
	dialogue_manager = SceneManager.get_dialogue_manager()
	_setup_player()
	_setup_claira()
	modulate = Color(0.6, 0.4, 0.4)


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)
	player.setup(Vector2i(10, 2), tilemap)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_claira() -> void:
	# Claira near the elder's house, behind barrier
	var claira = Node2D.new()
	claira.name = "ClairaBarrier"
	var body := ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -7)
	body.color = Color(0.9, 0.5, 0.3)
	claira.add_child(body)

	# Barrier glow
	var barrier := ColorRect.new()
	barrier.size = Vector2(24, 24)
	barrier.position = Vector2(-12, -12)
	barrier.color = Color(0.8, 0.9, 1.0, 0.3)
	claira.add_child(barrier)
	barrier.name = "Barrier"

	# Pulsing glow
	var tween := claira.create_tween().set_loops()
	tween.tween_property(barrier, "color:a", 0.1, 1.0)
	tween.tween_property(barrier, "color:a", 0.4, 1.0)

	claira.position = Vector2(10, 25) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	add_child(claira)

	var name_label := Label.new()
	name_label.text = "Claira"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-25, -26)
	name_label.size = Vector2(50, 14)
	name_label.add_theme_font_size_override("font_size", 8)
	claira.add_child(name_label)


func _process(_delta: float) -> void:
	if dialogue_manager.is_active():
		return

	# Finding Claira trigger
	if not found_claira:
		var dist := absi(player.grid_pos.x - 10) + absi(player.grid_pos.y - 25)
		if dist <= 2:
			found_claira = true
			_finding_claira_scene()

	# Village exit after finding Claira
	if found_claira and quest_state.current_state == QuestState.State.FOUND_CLAIRA:
		if player.grid_pos.y <= 1:
			player.disable_input()
			dialogue_manager.play(DialogueData.leaving_village())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.LEAVING)
			# End of opening MVP — could transition to a "to be continued" screen
			# or loop back to title. For now, just reload.
			SceneManager.transition_to("res://scenes/overworld/village.tscn")


func _finding_claira_scene() -> void:
	player.disable_input()
	quest_state.set_state(QuestState.State.FOUND_CLAIRA)

	# Remove barrier visual
	var claira_node = get_node("ClairaBarrier")
	if claira_node:
		var barrier = claira_node.get_node("Barrier")
		if barrier:
			var tween := create_tween()
			tween.tween_property(barrier, "color:a", 0.0, 1.0)
			await tween.finished
			barrier.queue_free()

	dialogue_manager.play(DialogueData.finding_claira())
	await dialogue_manager.dialogue_finished
	player.enable_input()
```

- [ ] **Step 2: Create destroyed village scene**

`scenes/overworld/village_destroyed.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/overworld/village_destroyed_map.gd" id="1"]
[node name="VillageDestroyed" type="Node2D"]
script = ExtResource("1")
[node name="TileMap" type="TileMapLayer" parent="."]
```

Use same TileSet as village but paint with darker/ruined tiles. Or reuse the same tilemap and let the script's `modulate = Color(0.6, 0.4, 0.4)` handle the mood shift.

- [ ] **Step 3: Commit**

```bash
git add scripts/overworld/village_destroyed_map.gd scenes/overworld/village_destroyed.tscn
git commit -m "feat: destroyed village scene with Claira rescue and barrier"
```

---

## Task 10: Update Main Scene and Integration

**Files:**
- Modify: `project.godot` — change main scene to village
- Verify all scene transitions work end to end

- [ ] **Step 1: Update project.godot main scene**

Change `run/main_scene` to:
```ini
run/main_scene="res://scenes/overworld/village.tscn"
```

- [ ] **Step 2: Manual integration test**

Run the project and verify the full flow:
1. Village loads, player spawns at their house
2. Walk around, talk to NPCs with interact button (Space/Enter)
3. Tavern keeper gives gossip + warmth
4. Old couple gives sweet lines + haunting hint
5. House door shows family photo dialogue
6. Walk to Claira at the square — auto-triggers dialogue
7. Claira follows you
8. Reach the tree area — cinematic kiss moment
9. Continue to elder's house — auto-triggers elder conversation
10. Claira stops following, stays at elder's house
11. Walk to village exit — transitions to road
12. Walk down road — (tutorial battle hook, currently skipped)
13. Continue to homestead — talk to Miller, receive trinket
14. Walk to exit — smoke on horizon cinematic
15. Transition to destroyed village — dark, moody
16. Walk to Claira near elder's house — cinematic: barrier fading, rescue
17. Walk to village exit — leaving cinematic
18. End of opening MVP

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete opening MVP — village to destruction to departure"
```

- [ ] **Step 5: Push**

```bash
git push
```

---

## Summary

| Task | What It Builds | Steps |
|------|----------------|-------|
| 1 | Quest state machine | 2 |
| 2 | Dialogue content | 2 |
| 3 | Dialogue UI (box + cinematic + manager) | 6 |
| 4 | Scene manager (autoload) | 3 |
| 5 | Player grid movement | 2 |
| 6 | NPC system + follow companion | 3 |
| 7 | Village map scene | 3 |
| 8 | Road + homestead scenes + tutorial encounter | 5 |
| 9 | Destroyed village scene | 3 |
| 10 | Integration + main scene update | 5 |
| **Total** | | **34 steps** |

**Note:** Tasks 7-9 require TileMap painting in the Godot editor. The scripts handle game logic but the actual tile layout must be created visually. The implementer should paint the maps matching the village layout from the design doc after the scripts are in place.
