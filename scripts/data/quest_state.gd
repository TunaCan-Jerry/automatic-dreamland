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
