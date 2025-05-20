extends Node

# Constants
const MIN_ANGLE = PI
const MAX_ANGLE = PI

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

# Game State
var current_ball: Node2D
var last_scorer
var game_state = GameState.WAITING

var score = {
	Player.LEFT: 0,
	Player.RIGHT: 0
}

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

# Lifecycle methods
func _ready() -> void:
	initialize_game()

func _process(delta: float) -> void:
	if game_state==GameState.WAITING and Input.is_action_just_pressed("start_game"):
		game_state = GameState.PLAYING
		set_initial_ball_direction()

# Signal handlers
func _on_left_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		handle_goal(Player.RIGHT)

func _on_right_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		handle_goal(Player.LEFT)

func _on_respawn_ball_timer_timeout() -> void:
	spawn_ball()

# Ball Management
func spawn_ball():
	if !ball_scene:
			return
	
	var ball_instance:Node2D = ball_scene.instantiate()
	add_child(ball_instance)
	ball_instance.add_to_group("ball")
	ball_instance.global_position = get_viewport().size/2
	ball_instance.speed = ball_speed
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
	play_goal_audio()
	
	last_scorer=scorer
	score[scorer] += 1
	
	remove_current_ball()
	update_score_labels()
	
	if is_match_ended():
		handle_end_match("left" if get_winner()==Player.LEFT else "right")
	else:
		respawn_ball_timer.start()
	

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
