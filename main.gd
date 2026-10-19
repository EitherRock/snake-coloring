extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var UI: Control
@onready var ui_bar = $UI/Root

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("ffffffff"))
	UI = canvas.get_child(0)
	
	ui_bar.picture_chosen.connect(_on_picture_chosen)
	ui_bar.pattern_chosen.connect(_on_pattern_chosen)

func _process(_delta: float) -> void:
	var dots = player.trail_dots.size()
	var dots_string = '%d / 0' % dots
	UI.update_label_text(dots_string)


func _on_picture_chosen(data: PictureData) -> void:
	$Picture.load_picture(data)
	
func _on_pattern_chosen(id: String) -> void:
	$Picture.set_pattern(id) 
