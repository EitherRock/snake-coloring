class_name RegionData
extends Resource

@export var mask: Texture2D
@export var fill_origin: Vector2 = Vector2(0.5, 0.5)  # where the fill starts (0-1)
@export var max_distance: float = 500.0               # farthest pixel from the origin
@export var max_dots: int = 50
@export var fill_order: int = 0
