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
	pictures.add_child(pic)
	placement.begin(pic)


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------
func _on_picture_dropped(data: PictureData, world_pos: Vector2) -> void:
	_place_picture(data, world_pos)


func _on_pattern_chosen(id: String) -> void:
	for pic in pictures.get_children():
		if pic.has_method("set_pattern"):
			pic.set_pattern(id)
