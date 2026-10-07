extends StaticBody2D

@export var radius: float = 290
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _draw():
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, outline_color, outline_width, true)
