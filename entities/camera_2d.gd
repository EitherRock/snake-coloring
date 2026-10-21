extends Camera2D

@export_group("Zoom")
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(zoom_step)
		MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-zoom_step)


func _change_zoom(amount: float) -> void:
	var new_zoom := clampf(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
