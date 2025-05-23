extends Node

# ===== Constants =====
@export var MIN_SPAWN_INTERVAL: float = 5.0
@export var MAX_SPAWN_INTERVAL: float = 15.0
@export var DEFAULT_SPAWN_INTERVAL: float = 10.0
@export var SPAWN_AREA_X_MIN: float = 0.25  # 1/4 of screen width
@export var SPAWN_AREA_X_MAX: float = 0.75  # 3/4 of screen width

# ===== Node References =====
var powerup_spawn_timer: Timer
@onready var powerup_scene: PackedScene = preload("res://scene/power_up.tscn")

# ===== State Variables =====
var powerup_list: Array = []
var active_powerup_list: Array = []
var spawned_powerup_list: Array = []


# ===== Lifecycle Methods =====
func _ready() -> void:
	setup_powerup_spawn_timer()

# ===== Timer Management =====
func setup_powerup_spawn_timer() -> void:
	powerup_spawn_timer = Timer.new()
	powerup_spawn_timer.wait_time = get_random_spawn_interval()
	powerup_spawn_timer.one_shot = false
	add_child(powerup_spawn_timer)
	powerup_spawn_timer.timeout.connect(_on_powerup_spawn_timer_timeout)
	powerup_spawn_timer.start()

func _on_powerup_spawn_timer_timeout() -> void:
	spawn_powerup()
	powerup_spawn_timer.wait_time = get_random_spawn_interval()

func get_random_spawn_interval() -> float:
	return randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)

func reset_powerup_spawn_timer() -> void:
	powerup_spawn_timer.wait_time = DEFAULT_SPAWN_INTERVAL

func start_powerup_spawning() -> void:
	powerup_spawn_timer.start()

func stop_powerup_spawning() -> void:
	powerup_spawn_timer.stop()

# ===== Powerup Management =====
func set_powerup_list(list: Array) -> void:
	powerup_list = list

func spawn_powerup() -> void:
	if powerup_list.is_empty():
		return
		
	var powerup_index = randi_range(0, powerup_list.size()-1)
	var powerup_instance: Node2D = powerup_scene.instantiate()
	configure_powerup_instance(powerup_instance, powerup_index)
	
	var powerup_id = generate_uuid()
	register_spawned_powerup(powerup_instance, powerup_id, powerup_index)

func configure_powerup_instance(instance: Node2D, powerup_index: int) -> void:
	instance.icon = powerup_list[powerup_index].icon
	instance.apply_scale(Vector2(powerup_list[powerup_index].size, powerup_list[powerup_index].size))
	add_child(instance)
	instance.global_position = get_random_spawn_position()

func register_spawned_powerup(instance: Node2D, powerup_id: String, powerup_index: int) -> void:
	var powerup_data = {
		"instance": instance,
		"id": powerup_id
	}
	spawned_powerup_list.append(powerup_data)
	
	instance.connect("collected", func():
		_on_powerup_collected(powerup_index, powerup_id)
	)

func _on_powerup_collected(powerup_index: int, powerup_id: String) -> void:
	var reverse_effect = powerup_list[powerup_index]["effect"].call()
	var active_powerup_data = {
		"name": powerup_list[powerup_index].name,
		"icon": powerup_list[powerup_index].icon,
		"reverse_function": reverse_effect,
		"id": powerup_id
	}
	active_powerup_list.append(active_powerup_data)
	remove_spawned_powerup(powerup_id)
	
	if powerup_list[powerup_index]["duration"] < INF:
		set_powerup_end_timer(powerup_list[powerup_index]["duration"], func():
			remove_powerup(powerup_id)
		)

# ===== Powerup Removal =====
func remove_spawned_powerup(powerup_id: String) -> void:
	for i in range(spawned_powerup_list.size()):
		if spawned_powerup_list[i].id == powerup_id:
			spawned_powerup_list[i].instance.queue_free()
			spawned_powerup_list.remove_at(i)
			break

func remove_powerup(powerup_id: String) -> void:
	for i in range(active_powerup_list.size()):
		if active_powerup_list[i].id == powerup_id:
			active_powerup_list[i].reverse_function.call()
			active_powerup_list.remove_at(i)
			break

func remove_all_powerups() -> void:
	for powerup_data in spawned_powerup_list:
		powerup_data.instance.queue_free()
	spawned_powerup_list.clear()

func reverse_all_active_powerups() -> void:
	for powerup_data in active_powerup_list:
		powerup_data.reverse_function.call()
	active_powerup_list.clear()

# ===== Utility Functions =====
func generate_uuid() -> String:
	const uuid_util = preload('res://addons/uuid/uuid.gd')
	return uuid_util.v4()

func get_random_spawn_position() -> Vector2:
	var spawn_area = get_viewport().size
	return Vector2(
		randi_range(spawn_area.x * SPAWN_AREA_X_MIN, spawn_area.x * SPAWN_AREA_X_MAX),
		randi_range(0, spawn_area.y)
	)

func set_powerup_end_timer(duration: float, function: Callable) -> void:
	var end_timer = Timer.new()
	end_timer.wait_time = duration
	end_timer.one_shot = true
	add_child(end_timer)
	end_timer.start()
	end_timer.timeout.connect(func():
		function.call()
		end_timer.call_deferred("queue_free")
	)

# ===== Getters =====
func get_active_powerups() -> Array:
	return active_powerup_list
