extends Camera2D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			var new_zoom = zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_zoom += Vector2(0.1, 0.1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_zoom -= Vector2(0.1, 0.1)
			zoom = new_zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))
			
