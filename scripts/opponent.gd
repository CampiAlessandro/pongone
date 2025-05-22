extends CharacterBody2D

enum Difficulty { EASY, MEDIUM, HARD }

const DIFFICULTY_REACTION_TIMES = {
	Difficulty.EASY: 0.4,
	Difficulty.MEDIUM: 0.2,
	Difficulty.HARD: 0.1
}

@export var speed = 1000.0
@export var acceleration = 0.05
@export var deceleration = 0.2
@export var position_uncertainty = 10
@export var difficulty: Difficulty = Difficulty.MEDIUM

@onready var screen_size = get_viewport_rect().size
@onready var reaction_timer: Timer = $ReactionTimer

var last_decision_time = 0.0
var target_velocity = Vector2.ZERO
var direction = 0
var last_ball_direction = Vector2.ZERO
var predicted_intersection_y : float

func _ready() -> void:
	predicted_intersection_y = screen_size.y / 2
	reaction_timer.timeout.connect(update_predicted_intersection_y)
	reaction_timer.wait_time = DIFFICULTY_REACTION_TIMES[difficulty]

func _physics_process(delta: float) -> void:
	# var current_time = Time.get_ticks_msec() / 1000.0
	update_movement()
	move_and_slide()

func update_predicted_intersection_y() -> void:
	var ball = get_ball_instance()
	if !ball:
		return

	predicted_intersection_y = get_predicted_intersection_y(ball, position_uncertainty)

func update_movement() -> void:
	var ball = get_ball_instance()
	if(!ball):
		return

	if ball.position == Vector2(screen_size.x / 2, screen_size.y / 2) and ball.direction == Vector2.ZERO:
		update_predicted_intersection_y()
	elif ball.direction.x > 0 and ball.direction != last_ball_direction:
		last_ball_direction = ball.direction	
		reaction_timer.start(DIFFICULTY_REACTION_TIMES[difficulty])
		
		
	direction = calculate_direction(predicted_intersection_y)
	update_velocity()

func update_velocity() -> void:
	target_velocity.y = speed * direction
	
	if direction != 0:
		velocity.y = lerp(velocity.y, target_velocity.y, acceleration)
	else:
		velocity.y = lerp(velocity.y, 0.0, deceleration)

func calculate_direction(predicted_intersection_y: float) -> int:
	var ball = get_ball_instance()
	if !ball:
		return 0
	
	var difference_y = predicted_intersection_y - position.y
	if abs(difference_y) < 50:
		return 0
	return sign(difference_y)

func get_ball_instance() -> RigidBody2D:
	var ball_array = get_tree().get_nodes_in_group("ball")
	if ball_array.size() < 1:
		return null
	return ball_array[0]

func get_predicted_intersection_y(ball: RigidBody2D, uncertainty: float) -> float:
	var ball_position = ball.position
	var ball_direction = ball.direction
	var paddle_x = position.x

	if(ball_position == Vector2(screen_size.x / 2, screen_size.y / 2) and ball_direction == Vector2.ZERO):
		return screen_size.y / 2
	
	var m = ball_direction.y / ball_direction.x
	var b = ball_position.y - (m * ball_position.x)
	
	return (m * paddle_x + b) + randf_range(-uncertainty, uncertainty)
