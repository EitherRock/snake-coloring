extends Node2D
# DotSpawner.gd

@export var dot_scene: PackedScene
@export var spawn_count: int = 50
@export var map_size: Vector2 = Vector2(2000, 2000)  # map size
@export var exclusion_radius: float = 100.0  # min distance from player/container

@export var player_path: NodePath
@export var container_path: NodePath
@export var dots_container_path: NodePath

var colors = [Color.RED, Color.DEEP_SKY_BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE_RED]

func _ready() -> void:
	randomize()
	spawn_dots()

func spawn_dots() -> void:
	var player = get_node(player_path)
	var container = get_node(container_path)
	var dots_container = get_node(dots_container_path)
	
	var spawned = 0
	var max_attempts = spawn_count * 10  # safety net to avoid infinite loop
	var attempts = 0
	
	while spawned < spawn_count and attempts < max_attempts:
		attempts += 1
		
		var pos = Vector2(
			randf_range(-map_size.x / 2, map_size.x / 2),
			randf_range(-map_size.y / 2, map_size.y / 2)
		)
		
		if pos.distance_to(player.global_position) < exclusion_radius:
			continue
		if pos.distance_to(container.global_position) < exclusion_radius + 300:
			continue
		
		var dot = dot_scene.instantiate()
		dot.global_position = pos
		dot.dot_color = colors[randi() % colors.size()]
		dots_container.add_child(dot)
		
		spawned += 1
