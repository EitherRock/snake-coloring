extends Area2D

@export_group("Appearance")
@export var dot_color: Color = Color.WHITE
@export var radius: float = 5.0

@export_group("Pull")
@export var pull_speed: float = 400.0
@export var arrival_distance: float = 10.0

var being_pulled: bool = false
var target: Node2D = null


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, dot_color)


func _process(delta: float) -> void:
	if not being_pulled:
		return

	if not is_instance_valid(target):
		being_pulled = false  # target vanished, so stay put
		return

	var direction := target.global_position - global_position
	if direction.length() <= arrival_distance:
		target.add_trail_dot(dot_color)
		queue_free()
		return

	global_position += direction.normalized() * pull_speed * delta


# ---------------------------------------------------------------------------
# Pull
# ---------------------------------------------------------------------------
func start_pull(player: Node2D) -> void:
	if being_pulled:
		return  # already on its way
	being_pulled = true
	target = player


# ---------------------------------------------------------------------------
# Hop (used when the player pops a dot off the tail)
# ---------------------------------------------------------------------------
func hop_to(end: Vector2, height: float, duration: float) -> void:
	set_deferred("monitorable", false)  # can't be magnet-grabbed mid-hop
	var start := global_position

	var tween := create_tween()
	tween.tween_method(_hop_step.bind(start, end, height), 0.0, 1.0, duration)
	tween.tween_interval(0.5)  # short grace period after landing
	tween.tween_callback(func(): monitorable = true)


func _hop_step(t: float, start: Vector2, end: Vector2, height: float) -> void:
	var pos := start.lerp(end, t)
	pos.y -= sin(t * PI) * height  # arc up and back down
	global_position = pos
