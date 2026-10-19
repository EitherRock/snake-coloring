extends Node2D

@export var picture_scene: PackedScene   # Picture.tscn
@export var picture_scale: float = 0.5   # a 1024px picture is big, so shrink it

@onready var player: CharacterBody2D = $Player
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var UI: Control
@onready var ui_bar = $UI/Root

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("ffffffff"))
	UI = canvas.get_child(0)
	
	ui_bar.picture_dropped.connect(_on_picture_dropped)
	ui_bar.pattern_chosen.connect(_on_pattern_chosen)

func _process(_delta: float) -> void:
	var dots = player.trail_dots.size()
	var dots_string = '%d / 0' % dots
	UI.update_label_text(dots_string)


func _on_picture_dropped(data: PictureData, world_pos: Vector2) -> void:
	var pic = picture_scene.instantiate()
	pic.data = data  # set before add_child so _ready() builds with it
	pic.scale = Vector2.ONE * picture_scale
	# the picture's origin is its top-left corner, so offset to center it on the drop point
	pic.position = world_pos - data.size * picture_scale / 2.0
	$Pictures.add_child(pic)
	
func _on_pattern_chosen(id: String) -> void:
	$Picture.set_pattern(id) 
