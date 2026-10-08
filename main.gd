extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var UI: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("ffffffff"))
	UI = canvas.get_child(0)

func _process(_delta: float) -> void:
	var dots = player.trail_dots.size()
	var dots_string = '%d / 0' % dots
	UI.update_label_text(dots_string)
