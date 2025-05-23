extends VBoxContainer

@export var icon: Texture2D
@export var percentage: float = 100.0

@onready var powerup_icon_texture: TextureRect = %Icon
@onready var powerup_percentage_bar: ProgressBar = %ProgressBar

func _ready() -> void:
	powerup_icon_texture.texture = icon

func _process(delta):
	powerup_percentage_bar.set_value(percentage)