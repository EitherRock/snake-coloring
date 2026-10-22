class_name Region
extends Node2D

const MAX_BANDS := 10  # must match MAX_BANDS in region_fill.gdshader
const DEBUG_BOUNDS := true  # set to false when done debugging stuff

@export var max_dots: int = 50

var picture_manager: Node2D = null
var is_complete: bool = false

var band_colors: Array[Color] = []
var band_amounts: Array[float] = []
var band_count: int = 0
var band_width: float = 1.0

var pending_dots: int = 0  # dots currently flying toward this region
var fill_origin_px: Vector2 = Vector2.ZERO
var mask_image: Image

var bounds_origin := Vector2.ZERO  # top-left of the box, in picture pixels

@onready var fill_effect: ColorRect = $FillEffect
@onready var fill_material: ShaderMaterial = fill_effect.material.duplicate()


func _ready() -> void:
	fill_effect.material = fill_material

	band_colors.resize(MAX_BANDS)
	band_amounts.resize(MAX_BANDS)
	band_colors.fill(Color(0, 0, 0, 0))
	band_amounts.fill(0.0)
	band_width = 1.0 / float(max_dots)


func _draw() -> void:
	if DEBUG_BOUNDS and mask_image:
		draw_rect(Rect2(bounds_origin, mask_image.get_size()), Color.RED, false, 2.0)

# ---------------------------------------------------------------------------
# Setup (called by PictureManager right after the region is added to the tree)
# ---------------------------------------------------------------------------
func setup(data: RegionData, picture_size: Vector2) -> void:
	data.prepare()

	var box_size := Vector2(data.bounds.size)
	bounds_origin = Vector2(data.bounds.position)
	mask_image = data.cropped_image
	fill_origin_px = data.fill_origin * picture_size  # still in full-picture pixels

	max_dots = mini(data.max_dots, MAX_BANDS)
	band_width = 1.0 / float(max_dots)

	# Size and place the rect around just this region
	fill_effect.position = bounds_origin
	fill_effect.size = box_size

	fill_material.set_shader_parameter("region_mask", data.cropped_texture)
	fill_material.set_shader_parameter("mask_size", box_size)
	fill_material.set_shader_parameter("fill_origin", (fill_origin_px - bounds_origin) / box_size)
	fill_material.set_shader_parameter("max_distance", data.max_distance)
	queue_redraw()


# ---------------------------------------------------------------------------
# Filling
# ---------------------------------------------------------------------------
func remaining_capacity() -> int:
	return max_dots - band_count - pending_dots


func reserve_slot() -> void:
	pending_dots += 1


func get_deposit_position() -> Vector2:
	return to_global(fill_origin_px)


func deposit_dot(dot_color: Color) -> void:
	pending_dots = maxi(pending_dots - 1, 0)

	if band_count >= MAX_BANDS or is_complete:
		return

	band_colors[band_count] = dot_color
	band_amounts[band_count] = band_width
	band_count += 1

	fill_material.set_shader_parameter("band_colors", band_colors)
	fill_material.set_shader_parameter("band_amounts", band_amounts)

	if band_count >= max_dots:
		is_complete = true
		if picture_manager:
			picture_manager.on_region_filled(self)


# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------
# point is in picture pixel coordinates (the Picture node's local space)
func contains_point(point: Vector2) -> bool:
	var x := floori(point.x - bounds_origin.x)
	var y := floori(point.y - bounds_origin.y)
	if x < 0 or y < 0 or x >= mask_image.get_width() or y >= mask_image.get_height():
		return false
	return mask_image.get_pixel(x, y).a > 0.5


func glow_pulse() -> void:
	var tween := create_tween()
	tween.tween_method(_set_glow, 0.0, 1.0, 0.15)
	tween.tween_method(_set_glow, 1.0, 0.0, 0.35)


func _set_glow(value: float) -> void:
	fill_material.set_shader_parameter("glow_intensity", value)
