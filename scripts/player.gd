extends CharacterBody2D


@export var speed = 1000.0
@export var acceleration = 0.05
@export var deceleration = 0.2

var target_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("move_up", "move_down")
	
	target_velocity.y = speed * direction
	
	if direction != 0:
		velocity.y = lerp(velocity.y, target_velocity.y, acceleration)
	else:
		velocity.y = lerp(velocity.y, 0.0, deceleration)
	
	move_and_slide()
	
