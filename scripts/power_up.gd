extends Area2D

signal collected

@export var icon:Texture2D

@onready var sprite:Sprite2D = %Sprite2D

func _ready():
	sprite.texture = icon

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("ball"):
		collected.emit()
		call_deferred("queue_free")
