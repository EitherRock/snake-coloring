extends CanvasLayer

@export var audio: AudioStreamPlayer
@onready var root: Node = $Root

func _ready() -> void:
	root.audio = audio
