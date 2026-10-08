extends Node2D
# Region.gd


const MAX_BANDS := 50

@onready var fill_material: ShaderMaterial = $FillEffect.material.duplicate()
@onready var click_area: Area2D = $ClickArea  # sized to match the region's shape

@export var radius: float = 290
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 2.0
@export var max_dots: int = 50


var band_colors: Array[Color] = []
var band_amounts: Array[float] = []
var band_count: int = 0
var band_width: float = 1.0

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
	click_area.input_event.connect(_on_click_area_input_event)
	
func _draw():
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, outline_color, outline_width, true)


func _on_click_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_complete and picture_manager:
			glow_pulse()
			picture_manager.select_region(self)

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


func glow_pulse() -> void:
	var tween = create_tween()
	tween.tween_method(func(v): fill_material.set_shader_parameter("glow_intensity", v), 0.0, 1.0, 0.15)
	tween.tween_method(func(v): fill_material.set_shader_parameter("glow_intensity", v), 1.0, 0.0, 0.35)
