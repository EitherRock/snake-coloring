extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if Input.is_action_pressed('zoom_in'):
		#if Input.
		#print('pressed')
		#zoom += Vector2(zoom.x + 5, zoom.y + 5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			var new_zoom = zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_zoom += Vector2(0.1, 0.1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_zoom -= Vector2(0.1, 0.1)
			zoom = new_zoom.clamp(Vector2(0.05, 0.05), Vector2(5.0, 5.0))
			
