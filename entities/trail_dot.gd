extends Node2D
class_name TrailDot

@export var follow_speed: float = 15.0
@export var target_distance: float = 20.0

var target: Node2D = null
var dot_color: Color = Color.WHITE
var flying_to_container: bool = false
var container_target: Node2D = null
var audio: AudioStreamPlayer2D

func _draw():
	draw_circle(Vector2(0,0), 5, dot_color)


func set_color(color: Color) -> void:
	dot_color = color
	queue_redraw()

func _process(delta: float) -> void:
	if flying_to_container:
		_fly_toward_container(delta, audio)
		return
	if target == null:
		return
	var direction = (target.global_position - global_position)
	var distance = direction.length()
	if distance > target_distance:
		var move_amount = min(distance - target_distance, follow_speed * distance * delta)
		global_position += direction.normalized() * move_amount

func fly_to_container(container: Node2D, audio_player: AudioStreamPlayer2D) -> void:
	flying_to_container = true
	container_target = container
	audio = audio_player

func _fly_toward_container(delta: float, audio_player) -> void:
	if not is_instance_valid(container_target):
		queue_free()  # target vanished with the old picture
		return
	
	var dest: Vector2 = container_target.global_position
	if container_target.has_method("get_deposit_position"):
		dest = container_target.get_deposit_position()

	var direction = dest - global_position
	var distance = direction.length()

	if distance < 10.0:
		container_target.deposit_dot(dot_color)
		queue_free()
		audio_player.play()
		return

	global_position += direction.normalized() * 400.0 * delta
