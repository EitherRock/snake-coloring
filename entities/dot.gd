extends Area2D

@export var pull_speed: float = 400.0
@export var arrival_distance: float = 10.0
@export var dot_color: Color = Color.WHITE

var being_pulled: bool = false
var target: Node2D = null

func _draw():
	draw_circle(Vector2(0,0), 5, dot_color)

func start_pull(player: Node2D) -> void:
	being_pulled = true
	target = player
	
func _process(delta: float) -> void:
	if not being_pulled or target == null:
		return
	
	var direction = (target.global_position - global_position)
	var distance = direction.length()
	
	if distance <= arrival_distance:
		target.add_trail_dot(dot_color)
		queue_free()
		return
		
	global_position += direction.normalized() * pull_speed * delta
	

func hop_to(end: Vector2, height: float, duration: float) -> void:
	set_deferred("monitorable", false)  # can't be magnet-grabbed mid-hop
	var start = global_position

	var tween = create_tween()
	tween.tween_method(func(t: float):
		var pos = start.lerp(end, t)
		pos.y -= sin(t * PI) * height  # arc up and back down
		global_position = pos
	, 0.0, 1.0, duration)
	tween.tween_interval(0.5)  # short grace period after landing
	tween.tween_callback(func(): monitorable = true)
