extends Node2D
# PictureManager.gd

@export var data: PictureData
@export var region_scene: PackedScene
@export var magnet_margin: float = 1.0  # 1.0 = just covers the picture, higher = extends past the edges

@onready var magnet_area: Area2D = $MagnetArea

var regions: Array[Node2D] = []
var selected_region: Node2D = null

var lines_sprite: Sprite2D

func _ready() -> void:
	if data:
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
	lines_sprite = Sprite2D.new()
	lines_sprite.texture = data.line_art
	lines_sprite.centered = false
	add_child(lines_sprite)

	if regions.size() > 0:
		selected_region = regions[0]

func select_region(region: Node2D) -> void:
	selected_region = region
	region.glow_pulse()
	
	# If the player is already standing in the magnet area, start depositing now
	for body in magnet_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.deposit_trail_to(region)

func get_current_region() -> Node2D:
	return selected_region
	

# Returns the preferred region if it has room, otherwise the first region
# (in fill order) that does. Returns null if the whole picture is spoken for.
func get_region_with_capacity(preferred: Node2D = null) -> Node2D:
	if preferred and preferred.remaining_capacity() > 0:
		return preferred
	for r in regions:
		if r.remaining_capacity() > 0:
			return r
	return null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var region = get_current_region()
		if region and not region.is_complete:
			body.deposit_trail_to(region)

func on_region_filled(_region: Node2D) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point := get_local_mouse_position()  # accounts for position, scale and camera zoom
		for r in regions:
			if r.contains_point(point):
				if not r.is_complete:
					select_region(r)
				return

func load_picture(new_data: PictureData) -> void:
	if new_data == data and not regions.is_empty():
		return  # already showing this picture

	_clear_picture()
	data = new_data
	build_picture()

func _clear_picture() -> void:
	# Tell the player to stop streaming dots into regions that are about to vanish
	for body in magnet_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("cancel_deposit"):
			body.cancel_deposit()

	for r in regions:
		r.queue_free()
	regions.clear()
	selected_region = null

	if lines_sprite:
		lines_sprite.queue_free()
		lines_sprite = null
