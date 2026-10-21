extends CharacterBody2D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export_group("Movement")
@export var move_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1500.0
@export var stop_distance: float = 10.0  # prevents jittering when close to cursor
@export var joystick: VirtualJoystick_

@export_group("Trail")
@export var first_dot_spacing: float = 40.0
@export var dot_spacing: float = 20.0

@export_group("Dot Hop")
@export var hop_distance: float = 80.0
@export var hop_height: float = 30.0
@export var hop_duration: float = 0.4

@export_group("Node Paths")
@export var trail_container_path: NodePath
@export var dots_container_path: NodePath
@export var bloop_sound_path: NodePath

# ---------------------------------------------------------------------------
# Scenes
# ---------------------------------------------------------------------------
var trail_dot_scene: PackedScene = preload('res://entities/trail_dot.tscn')
var dot_scene: PackedScene = preload('res://entities/dot.tscn')

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var trail_dots: Array[Node2D] = []
var is_depositing: bool = false
var deposit_cancelled: bool = false

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
@onready var trail_container: Node2D = get_node(trail_container_path)
@onready var dots_container: Node2D = get_node(dots_container_path)
@onready var bloop_sound_player: AudioStreamPlayer2D = get_node(bloop_sound_path)
@onready var magnet_collision: CollisionShape2D = $MagneticRadius/CollisionShape2D


# ---------------------------------------------------------------------------
# Built-in callbacks
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_update_movement(delta)
	move_and_slide()


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------
func _update_movement(delta: float) -> void:
	var target_velocity := Vector2.ZERO
	var rate := friction

	if joystick and joystick.output != Vector2.ZERO:
		target_velocity = joystick.output * move_speed
		rate = acceleration
	elif Input.is_action_pressed('right_click'):
		var direction := get_global_mouse_position() - global_position
		if direction.length() > stop_distance:
			target_velocity = direction.normalized() * move_speed
			rate = acceleration

	velocity = velocity.move_toward(target_velocity, rate * delta)

# ---------------------------------------------------------------------------
# Magnet
# ---------------------------------------------------------------------------
func set_magnet_range(radius: float) -> void:
	magnet_collision.shape.radius += radius


# ---------------------------------------------------------------------------
# Trail management
# ---------------------------------------------------------------------------
func add_trail_dot(dot_color: Color = Color.WHITE) -> void:
	var new_dot = trail_dot_scene.instantiate()
	trail_container.add_child(new_dot)

	# Spawn at the last dot's position (or the player's, if it's the first)
	var is_first := trail_dots.is_empty()
	new_dot.global_position = global_position if is_first else trail_dots[-1].global_position

	# Set what it follows
	new_dot.target = self if is_first else trail_dots[-1]
	new_dot.target_distance = first_dot_spacing if is_first else dot_spacing
	new_dot.dot_color = dot_color
	new_dot.set_color(dot_color)

	trail_dots.append(new_dot)
	bloop_sound_player.play()


func remove_trail_dot() -> void:
	if not trail_dots.is_empty():
		trail_dots.pop_back().queue_free()


func remove_front_trail_dot() -> void:
	if not trail_dots.is_empty():
		trail_dots.pop_front().queue_free()


# ---------------------------------------------------------------------------
# Depositing into pictures
# ---------------------------------------------------------------------------
func deposit_trail_to(container: Node2D) -> void:
	if is_depositing:
		return
	is_depositing = true
	_deposit_loop(container)


func cancel_deposit() -> void:
	deposit_cancelled = true


func _deposit_loop(container: Node2D) -> void:
	var manager = container.get("picture_manager")  # null for non-picture containers

	while not trail_dots.is_empty():
		if deposit_cancelled:
			break

		var target: Node2D = container
		if manager:
			target = manager.get_region_with_capacity(manager.selected_region)
		if target == null:
			break  # picture is full, keep the remaining dots on the trail

		if target.has_method("reserve_slot"):
			target.reserve_slot()

		var dot = trail_dots.pop_back()
		dot.fly_to_container(target, bloop_sound_player)
		await get_tree().create_timer(0.05).timeout

	deposit_cancelled = false
	is_depositing = false


# ---------------------------------------------------------------------------
# Popping a dot off the tail
# ---------------------------------------------------------------------------
func pop_last_dot() -> void:
	if trail_dots.is_empty() or is_depositing:
		return

	var last_dot = trail_dots.pop_back()
	var color: Color = last_dot.dot_color
	var start: Vector2 = last_dot.global_position

	# Hop away from whatever the dot was following
	var origin: Vector2 = trail_dots[-1].global_position if not trail_dots.is_empty() else global_position
	var dir := start - origin
	if dir.length() < 1.0:
		dir = Vector2.RIGHT.rotated(randf() * TAU)
	var end := start + dir.normalized() * hop_distance

	last_dot.queue_free()

	var new_dot = dot_scene.instantiate()
	new_dot.dot_color = color  # set before add_child so _ready() can apply it
	dots_container.add_child(new_dot)
	new_dot.global_position = start
	new_dot.hop_to(end, hop_height, hop_duration)


# ---------------------------------------------------------------------------
# Signal callbacks (connected in the editor, so don't rename these)
# ---------------------------------------------------------------------------
func _on_magnetic_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("dot"):
		area.start_pull(self)
		set_magnet_range(.5)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Platform.is_touch:
		return  # touch uses the pop button instead
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pop_last_dot()
