extends Button

func _on_mouse_entered() -> void:
	self.scale = Vector2(1.1,1.1)


func _on_mouse_exited() -> void:
	self.scale = Vector2(1,1)
