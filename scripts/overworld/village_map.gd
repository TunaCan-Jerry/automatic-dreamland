extends Node2D

const TILE_SIZE := 16

var player: Node2D
var claira_follow: Node2D
var npcs: Array[Node2D] = []
var quest_state: QuestState
var dialogue_manager: CanvasLayer
var tilemap: TileMapLayer


func _ready() -> void:
	quest_state = SceneManager.quest_state
	dialogue_manager = SceneManager.get_dialogue_manager()

	tilemap = $TileMap
	_setup_npcs()
	_setup_player()
	_setup_claira()


	# Tilemap is now painted in the Godot editor — no programmatic generation


func _setup_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://scripts/overworld/player.gd"))
	add_child(player)

	var npc_positions: Array[Vector2i] = []
	for npc in npcs:
		npc_positions.append(npc.grid_pos)
	player.setup(Vector2i(7, 14), tilemap, npc_positions)
	player.interacted.connect(_on_player_interact)
	player.moved.connect(_on_player_moved)

	var camera := Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)


func _setup_claira() -> void:
	claira_follow = Node2D.new()
	claira_follow.set_script(load("res://scripts/overworld/follow_npc.gd"))
	add_child(claira_follow)
	claira_follow.setup(Vector2i(15, 15))
	claira_follow.visible = false


func _setup_npcs() -> void:
	# Tavern area — northeast
	_add_npc("Tavern Keeper", Vector2i(22, 8), "interact", Color(0.8, 0.6, 0.2), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.tavern_keeper_after_quest()
		return DialogueData.tavern_keeper()
	)
	_add_npc("Patron", Vector2i(24, 8), "interact", Color(0.6, 0.5, 0.4), func(_s: int) -> Array:
		return DialogueData.flavor_patron()
	)
	# Square area — center
	_add_npc("Old Man", Vector2i(20, 13), "interact", Color(0.7, 0.7, 0.7), func(_s: int) -> Array:
		return DialogueData.old_couple()
	)
	_add_npc("Kid", Vector2i(14, 15), "interact", Color(0.9, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_kid()
	)
	# Fields — southeast
	_add_npc("Dad", Vector2i(22, 20), "interact", Color(0.3, 0.6, 0.3), func(state: int) -> Array:
		if state >= QuestState.State.GOT_QUEST:
			return DialogueData.dad_after_quest()
		return DialogueData.dad_greeting()
	)
	_add_npc("Farmer", Vector2i(25, 20), "interact", Color(0.5, 0.7, 0.3), func(_s: int) -> Array:
		return DialogueData.flavor_farmer()
	)
	# Claira — near fountain in square
	_add_npc("Claira", Vector2i(15, 15), "auto", Color(0.9, 0.5, 0.3), func(_s: int) -> Array:
		return DialogueData.claira_first_meeting()
	, false)
	# Elder — at her house in the south
	_add_npc("Elder", Vector2i(12, 26), "auto", Color(0.7, 0.5, 0.7), func(_s: int) -> Array:
		return DialogueData.elder_conversation()
	, false)
	# Your house door — west
	_add_npc("Home", Vector2i(7, 13), "interact", Color(0.4, 0.25, 0.15), func(_s: int) -> Array:
		return DialogueData.house_photo()
	)

	# Update player blocked positions after NPCs are set up
	var npc_positions: Array[Vector2i] = []
	for npc in npcs:
		npc_positions.append(npc.grid_pos)
	if player:
		player.set_blocked_positions(npc_positions)


func _add_npc(npc_name: String, pos: Vector2i, trigger: String, color: Color, dialogue_cb: Callable, is_repeatable: bool = true) -> Node2D:
	var npc = Node2D.new()
	npc.set_script(load("res://scripts/overworld/npc.gd"))
	npc.npc_name = npc_name
	npc.trigger_mode = trigger
	npc.repeatable = is_repeatable
	npc.npc_color = color
	add_child(npc)
	npc.setup(pos)
	npc.set_dialogue(dialogue_cb)
	npcs.append(npc)
	return npc


func _on_player_moved(new_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return

	# Check auto-trigger NPCs
	for npc in npcs:
		if npc.visible and npc.check_auto_trigger(new_pos):
			_trigger_npc(npc)
			return

	# Update Claira follow
	if claira_follow.visible and claira_follow.following:
		claira_follow.update_follow(new_pos)

	# Check zone triggers
	_check_zone_triggers()


func _on_player_interact(facing_pos: Vector2i) -> void:
	if dialogue_manager.is_active():
		return
	for npc in npcs:
		if npc.visible and npc.grid_pos == facing_pos and npc.trigger_mode == "interact" and npc.can_trigger():
			_trigger_npc(npc)
			return


func _trigger_npc(npc: Node2D) -> void:
	var lines: Array = npc.get_dialogue(quest_state.current_state)
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
				claira_follow.start_following(player.grid_pos)
		"Elder":
			if quest_state.current_state >= QuestState.State.TALKED_TO_CLAIRA and quest_state.current_state <= QuestState.State.AT_ELDER:
				quest_state.set_state(QuestState.State.GOT_QUEST)
				claira_follow.stop_following()
				claira_follow.visible = false


func _check_zone_triggers() -> void:
	# Tree kiss trigger — near the tree at (10, 21)
	if quest_state.current_state == QuestState.State.TALKED_TO_CLAIRA:
		if player.grid_pos == Vector2i(9, 21) or player.grid_pos == Vector2i(11, 21) or player.grid_pos == Vector2i(10, 20) or player.grid_pos == Vector2i(10, 22):
			quest_state.set_state(QuestState.State.WALKING_TO_ELDER)
			player.disable_input()
			dialogue_manager.play(DialogueData.tree_kiss())
			await dialogue_manager.dialogue_finished
			quest_state.set_state(QuestState.State.AT_ELDER)
			player.enable_input()

	# Village exit — north
	if quest_state.current_state == QuestState.State.GOT_QUEST:
		if player.grid_pos.y <= 1:
			quest_state.set_state(QuestState.State.ON_THE_ROAD)
			SceneManager.transition_to("res://scenes/overworld/road.tscn")
