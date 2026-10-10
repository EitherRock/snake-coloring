extends Node2D
# Region.gd

const MAX_BANDS := 10  # must match MAX_BANDS in region_fill.gdshader

@onready var fill_material: ShaderMaterial = $FillEffect.material.duplicate()

@export var max_dots: int = 50

var band_colors: Array[Color] = []
var band_amounts: Array[float] = []
var band_count: int = 0
var band_width: float = 1.0
var fill_origin_px: Vector2 = Vector2.ZERO

var picture_manager: Node2D = null
var is_complete: bool = false

func _ready() -> void:
	$FillEffect.material = fill_material

	band_colors.resize(MAX_BANDS)
	band_amounts.resize(MAX_BANDS)
	for i in MAX_BANDS:
		band_colors[i] = Color(0, 0, 0, 0)
		band_amounts[i] = 0.0
	band_width = 1.0 / float(max_dots)

# Called by PictureManager right after the region is added to the tree
func setup(data: RegionData, picture_size: Vector2) -> void:
	max_dots = min(data.max_dots, MAX_BANDS)  # can't have more dots than bands
	band_width = 1.0 / float(max_dots)

	$FillEffect.size = picture_size
	fill_material.set_shader_parameter("region_mask", data.mask)
	fill_material.set_shader_parameter("mask_size", picture_size)
	fill_material.set_shader_parameter("fill_origin", data.fill_origin)
	fill_material.set_shader_parameter("max_distance", data.max_distance)
	
	fill_origin_px = data.fill_origin * picture_size

func deposit_dot(dot_color: Color) -> void:
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

func get_deposit_position() -> Vector2:
	return to_global(fill_origin_px)

func glow_pulse() -> void:
	var tween = create_tween()
	tween.tween_method(func(v): fill_material.set_shader_parameter("glow_intensity", v), 0.0, 1.0, 0.15)
	tween.tween_method(func(v): fill_material.set_shader_parameter("glow_intensity", v), 1.0, 0.0, 0.35)
