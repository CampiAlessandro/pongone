extends Node

# Game Configuration
@export var ball_scene: PackedScene
@export var points_to_win: int = 5
@export var min_points_difference_to_win :int = 2
@export var ball_speed: float = 10.0

# Node References
@onready var respawn_ball_timer: Timer = $Timers/RespawnBallTimer
@onready var left_point_label: Label = %LeftPointLabel
@onready var right_point_label: Label = %RightPointLabel
@onready var win_label: Label = $WinScreen/VBoxContainer/WinLabel
@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var pause_manager: Node = $PauseManager
@onready var win_screen: Control = $WinScreen
@onready var powerup_manager: Node = $PowerupManager

# Game State
var current_ball: Node2D
var last_scorer
var last_player_touched: Node2D
var game_state = GameState.WAITING

var score = {
	Player.LEFT: 0,
	Player.RIGHT: 0
}

var powerup_list = [
	{
		name = "speed_up",
		description = "Speed up the ball",
		icon = preload("res://asset/fast_ball.png"),
		size = 1,
		duration = 10,
		effect = func():
			const SPEED_UP_MULTIPLIER = 1.2
			current_ball.speed = current_ball.speed * SPEED_UP_MULTIPLIER
			return func():
				if !current_ball:
					return
				current_ball.speed = ball_speed
				return,
	},
	{
		name = "bigger_paddle",
		description = "Make the paddle of the player that collected the power up bigger",
		icon = preload("res://asset/expand.png"),
		size = 1,
		effect = func():
			const PADDLE_SCALE_FACTOR = 1.5
			if !last_player_touched:
				return
			var affected_player = last_player_touched
			affected_player.apply_scale(Vector2(1, PADDLE_SCALE_FACTOR))
			return func():
				affected_player.apply_scale(Vector2(1, 1/PADDLE_SCALE_FACTOR))
				return,
		duration = 10,
	}
]

# Enums
enum Player {
	LEFT,
	RIGHT
}

enum GameState {
	PLAYING,
	WAITING,
	END
}

func set_powerup_end_timer(duration:float, function:Callable):
	var end_timer = Timer.new()
	end_timer.wait_time = duration
	end_timer.one_shot = true
	add_child(end_timer)
	end_timer.start()
	end_timer.timeout.connect(func():
		function.call()
		end_timer.call_deferred("queue_free")
	)

# Lifecycle methods
func _ready() -> void:
	initialize_game()
	# powerup_manager.reset_powerup_spawn_timer()
	powerup_manager.set_powerup_list(powerup_list)

func _process(delta: float) -> void:
	if game_state==GameState.WAITING and Input.is_action_just_pressed("start_game"):
		game_state = GameState.PLAYING
		set_initial_ball_direction()
		powerup_manager.start_powerup_spawning()

# Signal handlers
func _on_left_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		handle_goal(Player.RIGHT)

func _on_right_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		handle_goal(Player.LEFT)

func _on_respawn_ball_timer_timeout() -> void:
	powerup_manager.reverse_all_active_powerups()
	spawn_ball()

func _on_ball_hit_player(player: Node2D) -> void:
	last_player_touched = player
	print("last_player_touched: ", last_player_touched)

# Ball Management
func spawn_ball():
	if !ball_scene:
			return
	
	var ball_instance:Node2D = ball_scene.instantiate()
	add_child(ball_instance)
	ball_instance.add_to_group("ball")
	ball_instance.global_position = get_viewport().size/2
	ball_instance.speed = ball_speed
	ball_instance.ball_hit_player.connect(_on_ball_hit_player)
	current_ball = ball_instance
	game_state = GameState.WAITING
	#ball_move_timer.start()

func set_initial_ball_direction():
	match last_scorer:
		Player.LEFT:
			current_ball.direction = Vector2.from_angle(0)
		Player.RIGHT:
			current_ball.direction = Vector2.from_angle(PI)
		_:  # Default case
			current_ball.direction = Vector2.from_angle(randi_range(0, 1) * PI)

func remove_current_ball():
	if(current_ball):
		current_ball.queue_free()

# Score Management
func update_score_labels():
	left_point_label.text = str(score[Player.LEFT])
	right_point_label.text = str(score[Player.RIGHT])

func handle_goal(scorer:Player):
	powerup_manager.stop_powerup_spawning()
	powerup_manager.remove_all_powerups()
	play_goal_audio()
	
	last_scorer=scorer
	score[scorer] += 1
	
	remove_current_ball()
	update_score_labels()
	
	if is_match_ended():
		handle_end_match("left" if get_winner()==Player.LEFT else "right")
	else:
		respawn_ball_timer.start()
		# powerup_manager.reset_powerup_spawn_timer()	

# Game State Checks
func is_match_ended() -> bool:
	var score_difference = abs(score[Player.LEFT]-score[Player.RIGHT])
	var reached_min_win_points = score[Player.LEFT] >= points_to_win or score[Player.RIGHT] >= points_to_win
	return score_difference >= min_points_difference_to_win and reached_min_win_points

func get_winner():
	assert(is_match_ended(), "No Winner")
	if score[Player.LEFT] >= points_to_win:
		return Player.LEFT
	elif score[Player.RIGHT] >= points_to_win:
		return Player.RIGHT

# Audio
func play_goal_audio():
	sfx_player.stream = preload("res://asset/goal.wav")
	sfx_player.play()
		
# Game Flow
func initialize_game():
	set_pausable(true)
	update_score_labels()
	spawn_ball()

func handle_end_match(winner:String):
	win_screen.call("toggle_pause")
	set_pausable(false)
	game_state = GameState.END
	set_win_label(winner)

func set_pausable(value:bool):
	pause_manager.pausable = value

func _on_exit_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_restart_button_button_down() -> void:
	get_tree().reload_current_scene()

func _on_continue_button_button_down() -> void:
	pause_manager.call("toggle_pause")

func set_win_label(winner:String):
	win_label.text = "%s wins"%winner
