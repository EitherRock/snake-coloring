class_name PlacementController
extends Node

signal placement_ended

const SCALE_STEP := 1.15
const MIN_SCALE := 0.2
const MAX_SCALE := 1.5
const BAR_MARGIN := 16.0
const HOTBAR_RESERVE := 160.0

@export var confirm_bar: Control
@export var scale_bar: Control
@export var confirm_button: Button
@export var cancel_button: Button
@export var bigger_button: Button
@export var smaller_button: Button

var pending: PictureManager = null
var _dragging := false
var _grab_offset := Vector2.ZERO


func _ready() -> void:
	_show_bars(false)
	confirm_button.pressed.connect(confirm)
	cancel_button.pressed.connect(cancel)
	bigger_button.pressed.connect(_scale_by.bind(SCALE_STEP))
	smaller_button.pressed.connect(_scale_by.bind(1.0 / SCALE_STEP))


func is_placing() -> bool:
	return pending != null


func begin(pic: PictureManager) -> void:
	pending = pic
	_show_bars(true)
	_position_bars()


func confirm() -> void:
	if pending == null:
		return
	pending.confirm()
	_end()


func cancel() -> void:
	if pending == null:
		return
	pending.queue_free()
	_end()


func _end() -> void:
	pending = null
	_dragging = false
	_show_bars(false)
	placement_ended.emit()


func _show_bars(on: bool) -> void:
	confirm_bar.visible = on
	scale_bar.visible = on
	set_process(on)
	

func _process(_delta: float) -> void:
	_position_bars()  # follows the picture while it's dragged, scaled, or the camera moves


func _position_bars() -> void:
	if not is_instance_valid(pending):
		return

	# The picture's rectangle in screen space
	var xf := pending.get_global_transform_with_canvas()
	var top_left := xf * Vector2.ZERO
	var bottom_right := xf * pending.data.size
	var rect := Rect2(top_left, bottom_right - top_left)
	var usable := _usable_rect()

	# Confirm and cancel: centered below the picture, or above if there's no room
	var cs := confirm_bar.get_combined_minimum_size()
	var cx := rect.get_center().x - cs.x / 2.0
	var cy := rect.end.y + BAR_MARGIN
	if cy + cs.y > usable.end.y:
		cy = rect.position.y - BAR_MARGIN - cs.y
	confirm_bar.position = Vector2(
		clampf(cx, usable.position.x, usable.end.x - cs.x),
		clampf(cy, usable.position.y, usable.end.y - cs.y))

	# Scale buttons: centered on the right side, or on the left if there's no room
	var ss := scale_bar.get_combined_minimum_size()
	var sx := rect.end.x + BAR_MARGIN
	if sx + ss.x > usable.end.x:
		sx = rect.position.x - BAR_MARGIN - ss.x
	var sy := rect.get_center().y - ss.y / 2.0
	scale_bar.position = Vector2(
		clampf(sx, usable.position.x, usable.end.x - ss.x),
		clampf(sy, usable.position.y, usable.end.y - ss.y))


# The part of the screen the bars may use, leaving space for the hotbar
func _usable_rect() -> Rect2:
	var screen := get_viewport().get_visible_rect().size
	var r := Rect2(Vector2.ZERO, screen).grow(-BAR_MARGIN)
	if Platform.is_touch:
		r.size.x -= HOTBAR_RESERVE  # hotbar is on the right
	else:
		r.size.y -= HOTBAR_RESERVE  # hotbar is along the bottom
	return r


# Press starts a drag only if nothing else (buttons, joystick) used the event
func _unhandled_input(event: InputEvent) -> void:
	if pending == null or Platform.joystick_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world := _mouse_world()
		if Rect2(Vector2.ZERO, pending.data.size).has_point(pending.to_local(world)):
			_dragging = true
			_grab_offset = pending.global_position - world
			get_viewport().set_input_as_handled()


# Motion and release use _input so a drag still works over UI and always ends
func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		pending.global_position = _mouse_world() + _grab_offset
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = false


func _scale_by(factor: float) -> void:
	if pending == null:
		return
	var new_scale := clampf(pending.scale.x * factor, MIN_SCALE, MAX_SCALE)
	var center_before := pending.to_global(pending.data.size / 2.0)
	pending.scale = Vector2.ONE * new_scale
	# Scaling is around the top-left corner, so shift it to keep the center fixed
	pending.global_position += center_before - pending.to_global(pending.data.size / 2.0)


func _mouse_world() -> Vector2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
