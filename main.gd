class_name Main
extends Node2D

const BACKGROUND_COLOR := Color("ffffffff")

@export_group("Pictures")
@export var picture_scene: PackedScene  # Picture.tscn
@export var picture_scale: float = 0.5  # a 1024px picture is big, so shrink it

@onready var player: CharacterBody2D = $Player
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var hud: Control = canvas.get_child(0)
@onready var ui_bar: UIBar = $UI/Root
@onready var pictures: Node2D = $Pictures
@onready var placement: PlacementController = $PlacementController

#var current_pattern := "radial"
var target_region: Node2D = null  # the region the Pattern menu applies to

func _ready() -> void:
	RenderingServer.set_default_clear_color(BACKGROUND_COLOR)

	ui_bar.picture_dropped.connect(_on_picture_dropped)
	ui_bar.pattern_chosen.connect(_on_pattern_chosen)


func _process(_delta: float) -> void:
	pass


# ---------------------------------------------------------------------------
# Pictures
# ---------------------------------------------------------------------------
func _place_picture(data: PictureData, world_pos: Vector2) -> void:
	if placement.is_placing():
		return  # one pending picture at a time

	var pic: PictureManager = picture_scene.instantiate()
	pic.data = data
	pic.confirmed = false  # set before add_child so _ready() starts it pending
	pic.scale = Vector2.ONE * picture_scale
	pic.position = world_pos - data.size * picture_scale / 2.0
	#pic.pattern_id = current_pattern
	
	pic.region_selected.connect(_on_region_selected)
	
	pictures.add_child(pic)
	placement.begin(pic)
	

# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------
func _on_picture_dropped(data: PictureData, world_pos: Vector2) -> void:
	_place_picture(data, world_pos)


func _on_region_selected(region: Node2D) -> void:
	if not region.picture_manager.confirmed:
		return  # ignore pictures that are still being placed
	target_region = region

func _on_pattern_chosen(id: String) -> void:
	if not is_instance_valid(target_region):
		return
	target_region.set_pattern(id)
	target_region.glow_pulse()  # shows which region changed
