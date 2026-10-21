class_name VirtualJoystick_
extends Control

@export var radius: float = 120.0
@export var dead_zone: float = 0.15

var output := Vector2.ZERO  # direction, length 0-1
var is_active: bool:
	get: return _touch_index != -1

var _touch_index := -1
var _origin := Vector2.ZERO  # where the thumb first landed (screen position)
var _knob := Vector2.ZERO


func _ready() -> void:
	print("is_touch: ", Platform.is_touch, "  visible: ", visible, "  rect: ", get_global_rect())
	visible = Platform.is_touch
	set_process_input(Platform.is_touch)


func _input(event: InputEvent) -> void:
	var local_touch = get_global_transform_with_canvas().affine_inverse() * event.position
	
	if event is InputEventScreenTouch:
		print("touch at ", event.position, " pressed: ", event.pressed)
		#if event.pressed and _touch_index == -1 and get_rect().has_point(local_touch):
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_knob = _origin
			Platform.joystick_active = true
			queue_redraw()
			print('redrew')
		elif not event.pressed and event.index == _touch_index:
			_release()
			print('released')
		else: print('not working')
	elif event is InputEventScreenDrag and event.index == _touch_index:
		output = ((event.position - _origin) / radius).limit_length(1.0)
		_knob = _origin + output * radius
		if output.length() < dead_zone:
			output = Vector2.ZERO
		queue_redraw()


func _release() -> void:
	_touch_index = -1
	output = Vector2.ZERO
	Platform.joystick_active = false
	queue_redraw()


func _draw() -> void:
	if not is_active:
		return
	var base := _origin - global_position
	draw_circle(base, radius, Color(0, 0, 0, 0.15))
	draw_arc(base, radius, 0.0, TAU, 48, Color(0, 0, 0, 0.35), 3.0, true)
	draw_circle(_knob - global_position, radius * 0.4, Color(0, 0, 0, 0.45))
