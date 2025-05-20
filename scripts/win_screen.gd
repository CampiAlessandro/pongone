extends Control

var is_paused = false

func _ready() -> void:
	set_visibility(is_paused)

func _exit_tree() -> void:
	get_tree().paused = false

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	set_visibility(is_paused)

func set_visibility(value:bool):
	self.visible = value
