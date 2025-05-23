extends MarginContainer

@onready var left_player_powerup_list: HBoxContainer = $LeftPlayer
@onready var right_player_powerup_list: HBoxContainer = $RightPlayer

var active_powerup_list: Array[Dictionary] = []

func add_powerup(powerup: Dictionary, player_side: String) -> void:
	var powerup_list_item = preload("res://scene/powerup_ui_list_item.tscn")
	var powerup_list_item_instance = powerup_list_item.instantiate()
	powerup_list_item_instance.icon = powerup.icon
	active_powerup_list.append({"id": powerup.id, "instance": powerup_list_item_instance, "end_timer": powerup.end_timer})
	if player_side == "left":
		left_player_powerup_list.add_child(powerup_list_item_instance)
	else:
		right_player_powerup_list.add_child(powerup_list_item_instance)

func remove_powerup(powerup_instance_id: String) -> void:
	for powerup in active_powerup_list:
		if powerup.id == powerup_instance_id:
			powerup.instance.queue_free()
			active_powerup_list.erase(powerup)
			break
			
func _process(_delta: float) -> void:
	for powerup in active_powerup_list:
		powerup.instance.percentage = (powerup.end_timer.time_left / powerup.end_timer.wait_time)*100
