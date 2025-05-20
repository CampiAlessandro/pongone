extends Node

@onready var pause_menu: Control = $PauseMenu

var is_paused = false
var pausable_scene_path_list = ["res://scene/game.tscn"]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") :
		toggle_pause()

func toggle_pause():
	if(!can_pause()):
		return
	
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func can_pause():
	var current_scene_path = get_current_scene_path()
	var is_pausable_scene = \
		pausable_scene_path_list.find(current_scene_path) != -1
	var is_in_pausable_state = get_tree().current_scene and get_tree().current_scene.can_pause
	
	return is_pausable_scene and is_in_pausable_state

func get_current_scene_path():
	var current_scene = get_tree().current_scene
	
	if(!current_scene):
		return null
	
	return current_scene.scene_file_path
