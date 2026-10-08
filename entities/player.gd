extends CharacterBody2D


@export var move_speed: float = 300.0
@export var stop_distance: float = 10.0 # prevents jittering when close to cursor
@export var friction: float = 1500.0
@export var acceleration: float = 1500.0

@export var dot_spacing: float = 20.0
@export var first_dot_spacing: float = 40.0

@export var trail_container_path: NodePath
@export var dots_container_path: NodePath

@export var hop_distance: float = 80.0
@export var hop_height: float = 30.0
@export var hop_duration: float = 0.4

@onready var trail_container: Node2D = get_node(trail_container_path)
@onready var dots_container: Node2D = get_node(dots_container_path)
@onready var magnet_collision: CollisionShape2D = $MagneticRadius/CollisionShape2D

var trail_dots: Array[Node2D] = []
var trail_dot_scene: PackedScene = preload('res://trail_dot.tscn')
var dot_scene: PackedScene = preload('res://entities/dot.tscn')
var is_depositing: bool = false


func set_magnet_range(radius: float) -> void:
	magnet_collision.shape.radius += radius


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed('right_click'):
		var target_position = get_global_mouse_position()
		var direction = (target_position - global_position)
		
		# only move if we're not already at the target
		if direction.length() > stop_distance:
			direction = direction.normalized()
			velocity = velocity.move_toward(direction * move_speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	

func add_trail_dot(dot_color: Color = Color.WHITE) -> void:
	var new_dot = trail_dot_scene.instantiate()
	trail_container.add_child(new_dot)
	
	# Spawn it at the position of the last dot (or player, if its the first)
	var spawn_position = global_position
	if trail_dots.size() > 0:
		spawn_position = trail_dots[-1].global_position
	new_dot.global_position = spawn_position
	
	# set what it follows
	new_dot.target = self if trail_dots.size() == 0 else trail_dots[-1]
	new_dot.target_distance = first_dot_spacing if new_dot.target == self else dot_spacing
	new_dot.dot_color = dot_color
	new_dot.set_color(dot_color)
	
	trail_dots.append(new_dot)

func remove_trail_dot() -> void:
	if trail_dots.size() > 0:
		var last_dot = trail_dots.pop_back()
		last_dot.queue_free()

func remove_front_trail_dot() -> void:
	if trail_dots.size() > 0:
		var last_dot = trail_dots.pop_front()
		last_dot.queue_free()


func _on_magnetic_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("dot"):
		area.start_pull(self)
		set_magnet_range(.5)

func deposit_trail_to(container: Node2D) -> void:
	if is_depositing:
		return
	is_depositing = true
	_deposit_loop(container)
	
func _deposit_loop(container: Node2D) -> void:
	while trail_dots.size() > 0:
		var dot = trail_dots.pop_back()  # take from the back of the trail
		dot.fly_to_container(container)
		await get_tree().create_timer(0.05).timeout  # small delay between each dot leaving
	is_depositing = false
	

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_last_dot()


func pop_last_dot() -> void:
	if trail_dots.is_empty() or is_depositing:
		return

	var last_dot = trail_dots.pop_back()
	var color = last_dot.dot_color
	var start = last_dot.global_position

	# Hop away from whatever the dot was following
	var origin = trail_dots[-1].global_position if trail_dots.size() > 0 else global_position
	var dir = start - origin
	if dir.length() < 1.0:
		dir = Vector2.RIGHT.rotated(randf() * TAU)
	var end = start + dir.normalized() * hop_distance

	last_dot.queue_free()

	var new_dot = dot_scene.instantiate()
	new_dot.dot_color = color  # set before add_child so _ready() can apply it
	dots_container.add_child(new_dot)
	new_dot.global_position = start
	new_dot.hop_to(end, hop_height, hop_duration)
