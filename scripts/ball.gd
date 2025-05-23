extends RigidBody2D

signal ball_hit_player(player: Node2D)

@export var speed: float = 10.0
const FAKE_CURVE_FACTOR: float = 0.005
@onready var hit_sound: AudioStreamPlayer2D = $HitSoundPLayer

var direction: Vector2
var last_touch_player

# Lifecycle
func _physics_process(delta: float) -> void:
	var object_hit = move_and_collide(speed * direction)
	handle_collision(object_hit)

func handle_collision(object_hit: KinematicCollision2D):
	if !object_hit:
		return
	
	calculate_bounce(object_hit)
	play_hit_sound()
	if(has_collided_with_player(object_hit)):
		ball_hit_player.emit(object_hit.get_collider())
	
func play_hit_sound():
	hit_sound.play()

func has_collided_with_player(object_hit: KinematicCollision2D):
	var object_hit_collider = object_hit.get_collider() as Node2D
	return object_hit_collider.is_in_group("players")

func get_distance_from_collider_center(object_hit: KinematicCollision2D) -> float:
	var object_hit_collider = object_hit.get_collider() as Node2D
	return position.y - object_hit_collider.position.y

func calculate_bounce(object_hit: KinematicCollision2D):
	direction = direction.bounce(object_hit.get_normal())
	
	if (has_collided_with_player(object_hit)):
		var distance_from_collider_center = get_distance_from_collider_center(object_hit)
		direction += Vector2(0, distance_from_collider_center * FAKE_CURVE_FACTOR)
	
	direction = direction.normalized()
