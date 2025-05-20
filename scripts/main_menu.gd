extends Control



func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/game.tscn")


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/options_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
