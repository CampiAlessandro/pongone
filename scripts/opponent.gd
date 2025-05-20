extends CharacterBody2D


@export var speed = 1000.0
@export var acceleration = 0.05
@export var deceleration = 0.2
@export var position_uncertainty = 10
@export var reaction_delay = 0.2  # Seconds before AI responds

@onready var screen_size = get_viewport_rect().size

var last_decision_time = 0.0
var target_velocity = Vector2.ZERO
var direction = 0

func _physics_process(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	direction = get_direction()
	
	
	target_velocity.y = speed * direction
	
	if direction != 0:
		velocity.y = lerp(velocity.y, target_velocity.y, acceleration)
	else:
		velocity.y = lerp(velocity.y, 0.0, deceleration)
	
	move_and_slide()

func get_direction():
	var ball = get_ball_instance()
	
	if(!ball):
		return 0
	
	var predicted_intersection_y = get_predicted_intersection_y(ball)
	predicted_intersection_y += randf_range(-position_uncertainty, position_uncertainty)
	var difference_y = predicted_intersection_y - position.y
	if(abs(difference_y) < 10):
		return 0
	return(sign(difference_y))

func get_ball_instance():
	var ball_array = get_tree().get_nodes_in_group("ball")
	if(ball_array.size() < 1):
		return null
	return ball_array[0]

func get_predicted_intersection_y(ball:RigidBody2D):
	var ball_position = ball.position
	var ball_direction = ball.direction
	var paddle_x = position.x
	
	var m = ball_direction.y/ball_direction.x
	var b = ball_position.y -(m * ball_position.x)
	
	var intersection_y = m * paddle_x + b
	
	return intersection_y
