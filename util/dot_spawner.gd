class_name DotSpawner
extends Node2D

const CONTAINER_EXTRA_RADIUS := 300.0  # extra clearance around the container on top of exclusion_radius
const ATTEMPTS_PER_DOT := 10           # so the loop can't run forever

const COLORS: Array[Color] = [
	Color.RED,
	Color.DEEP_SKY_BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE_RED,
]

@export_group("Spawning")
@export var dot_scene: PackedScene
@export var spawn_count: int = 50
@export var map_size: Vector2 = Vector2(2000, 2000)

@export_group("Exclusion")
@export var exclusion_radius: float = 100.0  # min distance from the player and container

@export_group("Node Paths")
@export var player_path: NodePath
@export var container_path: NodePath
@export var dots_container_path: NodePath

@onready var player: Node2D = get_node(player_path)
@onready var container: Node2D = get_node(container_path)
@onready var dots_container: Node2D = get_node(dots_container_path)


func _ready() -> void:
	spawn_dots()


# ---------------------------------------------------------------------------
# Spawning
# ---------------------------------------------------------------------------
func spawn_dots() -> void:
	var spawned := 0
	var attempts := 0
	var max_attempts := spawn_count * ATTEMPTS_PER_DOT

	while spawned < spawn_count and attempts < max_attempts:
		attempts += 1

		var pos := _random_position()
		if not _is_valid_position(pos):
			continue

		_spawn_dot(pos)
		spawned += 1


func _spawn_dot(pos: Vector2) -> void:
	var dot = dot_scene.instantiate()
	dot.dot_color = COLORS.pick_random()  # set before add_child so it draws correctly
	dots_container.add_child(dot)
	dot.global_position = pos


# ---------------------------------------------------------------------------
# Position helpers
# ---------------------------------------------------------------------------
func _random_position() -> Vector2:
	return Vector2(
		randf_range(-map_size.x / 2.0, map_size.x / 2.0),
		randf_range(-map_size.y / 2.0, map_size.y / 2.0)
	)


func _is_valid_position(pos: Vector2) -> bool:
	if pos.distance_to(player.global_position) < exclusion_radius:
		return false
	if pos.distance_to(container.global_position) < exclusion_radius + CONTAINER_EXTRA_RADIUS:
		return false
	return true
