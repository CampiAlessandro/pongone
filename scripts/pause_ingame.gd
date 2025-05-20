extends Node


@export var pausable = true

var children:Array[Node]
var is_paused = false

func _ready() -> void:
	children = self.get_children()
	set_children_visibility(is_paused)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") :
		toggle_pause()

func _exit_tree() -> void:
	get_tree().paused = false

func toggle_pause():
	if(!can_pause()):
		return
	
	is_paused = !is_paused
	get_tree().paused = is_paused
	set_children_visibility(is_paused)

func can_pause():
	return pausable

func set_children_visibility(value:bool):
	for child in children:
		if(!("visible" in child)):
			continue
		child.visible = value
