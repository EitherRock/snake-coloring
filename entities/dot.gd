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
