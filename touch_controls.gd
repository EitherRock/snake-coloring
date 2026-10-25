extends Control

@export var player: Node
#@export var camera: Camera2D

@onready var pop_button: Button = $HBoxContainer/PopButton
@onready var zoom_in_button: Button = $HBoxContainer/ZoomInButton
@onready var zoom_out_button: Button = $HBoxContainer/ZoomOutButton
@onready var audio: AudioStreamPlayer = $"../../ButtonSound"
@onready var auido_pop: AudioStreamPlayer2D = $"../../AudioStreamPlayer2D"


func _ready() -> void:
	var camera = player.get_node('Camera2D')
	visible = Platform.is_touch
	pop_button.pressed.connect(func(): 
		player.pop_last_dot() 
		#auido_pop.play()
	)
	
	zoom_in_button.pressed.connect(func(): 
		camera.zoom_in()
		audio.play()
	)
	
	zoom_out_button.pressed.connect(func(): 
		camera.zoom_out()
		audio.play()
	)
