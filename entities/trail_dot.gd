class_name TrailDot
extends Node2D

@export_group("Appearance")
@export var radius: float = 5.0

@export_group("Follow")
@export var follow_speed: float = 15.0
@export var target_distance: float = 20.0

@export_group("Deposit")
@export var deposit_speed: float = 400.0
@export var deposit_arrival_distance: float = 10.0

var dot_color: Color = Color.WHITE
var target: Node2D = null  # the node this dot follows (player or the dot ahead)

var flying_to_container: bool = false
var container_target: Node2D = null
var audio: AudioStreamPlayer2D = null


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, dot_color)


func _process(delta: float) -> void:
	if flying_to_container:
		_fly_toward_container(delta)
	else:
		_follow_target(delta)


# ---------------------------------------------------------------------------
# Appearance
# ---------------------------------------------------------------------------
func set_color(color: Color) -> void:
	dot_color = color
	queue_redraw()


# ---------------------------------------------------------------------------
# Following the trail
# ---------------------------------------------------------------------------
func _follow_target(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var direction := target.global_position - global_position
	var distance := direction.length()
	if distance > target_distance:
		var move_amount := minf(distance - target_distance, follow_speed * distance * delta)
		global_position += direction.normalized() * move_amount


# ---------------------------------------------------------------------------
# Flying into a region
# ---------------------------------------------------------------------------
func fly_to_container(container: Node2D, audio_player: AudioStreamPlayer2D) -> void:
	flying_to_container = true
	container_target = container
	audio = audio_player


func _fly_toward_container(delta: float) -> void:
	if not is_instance_valid(container_target):
		queue_free()  # target vanished with the old picture
		return

	var dest: Vector2 = container_target.global_position
	if container_target.has_method("get_deposit_position"):
		dest = container_target.get_deposit_position()

	var direction := dest - global_position
	if direction.length() < deposit_arrival_distance:
		_arrive()
		return

	global_position += direction.normalized() * deposit_speed * delta


func _arrive() -> void:
	container_target.deposit_dot(dot_color)
	if is_instance_valid(audio):
		audio.play()
	queue_free()
