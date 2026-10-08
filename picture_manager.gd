#extends Node2D
## PictureManager.gd
#
#@export var regions: Array[Node2D] = []
#
#@onready var magnet_area: Area2D = $MagnetArea
#
#var current_region_index: int = 0
#
#func _ready() -> void:
	#for region in regions:
		#region.picture_manager = self
	#
	#magnet_area.body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#var region = get_current_region()
		#if region:
			#body.deposit_trail_to(region)
#
#func get_current_region() -> Node2D:
	#if current_region_index >= regions.size():
		#return null
	#return regions[current_region_index]
#
#func on_region_filled() -> void:
	#current_region_index += 1
	#if current_region_index >= regions.size():
		#print("Picture complete!")


extends Node2D
# PictureManager.gd

@export var regions: Array[Node2D] = []
@onready var magnet_area: Area2D = $MagnetArea

var selected_region: Node2D = null

func _ready() -> void:
	for region in regions:
		region.picture_manager = self
	
	magnet_area.body_entered.connect(_on_body_entered)
	
	# Optionally auto-select the first region by default
	if regions.size() > 0:
		selected_region = regions[0]

func select_region(region: Node2D) -> void:
	selected_region = region
	print("Selected region: ", region.name)

func get_current_region() -> Node2D:
	return selected_region

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var region = get_current_region()
		if region and not region.is_complete:
			body.deposit_trail_to(region)

func on_region_filled(region: Node2D) -> void:
	# Auto-advance to next incomplete region, or leave selection as-is — your choice
	for r in regions:
		if not r.is_complete:
			selected_region = r
			return
	print("Picture complete!")
