extends Node2D
# PictureManager.gd

@export var data: PictureData
@export var region_scene: PackedScene
@export var magnet_margin: float = 1.0  # 1.0 = just covers the picture, higher = extends past the edges

@onready var magnet_area: Area2D = $MagnetArea

var regions: Array[Node2D] = []
var selected_region: Node2D = null

func _ready() -> void:
	build_picture()
	magnet_area.body_entered.connect(_on_body_entered)

func build_picture() -> void:
	setup_magnet_area()
	var sorted := data.regions.duplicate()
	sorted.sort_custom(func(a, b): return a.fill_order < b.fill_order)

	for region_data in sorted:
		var region = region_scene.instantiate()
		add_child(region)  # add first so the region's _ready() runs
		region.setup(region_data, data.size)
		region.picture_manager = self
		regions.append(region)

	# Line art last so it draws on top of the fills
	var lines := Sprite2D.new()
	lines.texture = data.line_art
	lines.centered = false
	add_child(lines)

	if regions.size() > 0:
		selected_region = regions[0]

func select_region(region: Node2D) -> void:
	selected_region = region
	region.glow_pulse()

func get_current_region() -> Node2D:
	return selected_region

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var region = get_current_region()
		if region and not region.is_complete:
			body.deposit_trail_to(region)

func on_region_filled(region: Node2D) -> void:
	for r in regions:
		if not r.is_complete:
			selected_region = r
			return
	print("Picture complete!")

func setup_magnet_area() -> void:
	var shape_node: CollisionShape2D = magnet_area.get_node("CollisionShape2D")

	# Center it on the picture. the picture's origin is its top-left corner
	magnet_area.position = data.size / 2.0

	# Duplicate so pictures don't share one shape resource
	var circle := CircleShape2D.new()
	circle.radius = (max(data.size.x, data.size.y) / 2.0) * magnet_margin
	shape_node.shape = circle
