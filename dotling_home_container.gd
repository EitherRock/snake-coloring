#extends Node2D
#
#@onready var fill_material: ShaderMaterial = $FillEffect.material
#
#@onready var magnet_area: Area2D = $MagnetArea
#var depositing: bool = false
#
#var dot_count = 0
#var max_dots = 100
#
#const MAX_COLORS := 6
#var band_colors: Array[Color] = []
#var band_amounts: Array[float] = []
#var color_index_map: Dictionary = {}  # maps a Color -> its band index
#
#func set_fill(amount: float) -> void:
	#var tween = create_tween()
	#tween.tween_method(func(v): fill_material.set_shader_parameter("fill_amount", v), 
		#fill_material.get_shader_parameter("fill_amount"), amount, 0.3)
		#
#func _ready() -> void:
	#magnet_area.body_entered.connect(_on_body_entered)
	#magnet_area.body_exited.connect(_on_body_exited)
	#
	#band_colors.resize(MAX_COLORS)
	#band_amounts.resize(MAX_COLORS)
	#for i in MAX_COLORS:
		#band_colors[i] = Color(0, 0, 0, 0)
		#band_amounts[i] = 0.0
	#
##func deposit_dot() -> void:
	##dot_count += 1
	##var fill_ratio = float(dot_count) / float(max_dots)
	##set_fill(fill_ratio)
#
#func deposit_dot(dot_color: Color) -> void:
	#var index = get_band_index(dot_color)
	#band_amounts[index] += 1.0 / float(max_dots)
	#
	#fill_material.set_shader_parameter("band_colors", band_colors)
	#fill_material.set_shader_parameter("band_amounts", band_amounts)
	#
#func get_band_index(color: Color) -> int:
	#if color_index_map.has(color):
		#return color_index_map[color]
	#
	#var new_index = color_index_map.size()
	#color_index_map[color] = new_index
	#band_colors[new_index] = color
	#return new_index
#
#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#if not depositing:
			#start_depositing(body)
	#
			#
#func _on_body_exited(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#depositing = false
		#
#
#func start_depositing(player: Node2D) -> void:
	#depositing = true
	#player.deposit_trail_to(self)
	
extends Node2D

@onready var fill_material: ShaderMaterial = $FillEffect.material

@onready var magnet_area: Area2D = $MagnetArea
var depositing: bool = false

@export var max_dots: int = 50
const MAX_BANDS := 100  # must match MAX_COLORS in the shader

var band_colors: Array[Color] = []
var band_amounts: Array[float] = []
var band_count: int = 0
var band_width: float = 1.0

func _ready() -> void:
	magnet_area.body_entered.connect(_on_body_entered)
	magnet_area.body_exited.connect(_on_body_exited)
	
	band_colors.resize(MAX_BANDS)
	band_amounts.resize(MAX_BANDS)
	for i in MAX_BANDS:
		band_colors[i] = Color(0, 0, 0, 0)
		band_amounts[i] = 0.0
	
	band_width = 1.0 / float(max_dots)

func deposit_dot(dot_color: Color) -> void:
	if band_count >= MAX_BANDS:
		return  # container full
	
	band_colors[band_count] = dot_color
	band_amounts[band_count] = band_width
	band_count += 1
	
	fill_material.set_shader_parameter("band_colors", band_colors)
	fill_material.set_shader_parameter("band_amounts", band_amounts)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not depositing:
			start_depositing(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		depositing = false

func start_depositing(player: Node2D) -> void:
	depositing = true
	player.deposit_trail_to(self)
