@tool
class_name RegionData
extends Resource

@export var mask: Texture2D
@export var fill_origin: Vector2 = Vector2(0.5, 0.5)  # where the fill starts (0-1)
@export var max_distance: float = 500.0               # farthest pixel from the origin
@export var max_dots: int = 50
@export var fill_order: int = 0
@export var baked_bounds := Rect2i()  # set by the importer; empty for hand-made masks


# Filled in by prepare(); not exported, so it isn't saved into the .tres
var bounds := Rect2i()          # bounding box in picture pixels
var cropped_image: Image        # used for click detection
var cropped_texture: Texture2D  # used by the shader

func prepare() -> void:
	if cropped_texture != null:
		return

	if baked_bounds.size.x > 0 and baked_bounds.size.y > 0:
		bounds = baked_bounds
		cropped_image = mask.get_image()
		cropped_texture = mask
		return

	# Hand-made full-size mask: find the box and crop it
	var full := mask.get_image()
	bounds = full.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		bounds = Rect2i(0, 0, 1, 1)
	cropped_image = full.get_region(bounds)
	cropped_texture = ImageTexture.create_from_image(cropped_image)
	
