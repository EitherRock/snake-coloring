extends Control

signal picture_dropped(data: PictureData, world_position: Vector2)
signal pattern_chosen(pattern_id: String)

@export var pictures: Array[PictureData] = []

const PATTERNS := [
	{"id": "radial", "label": "Radial"},
	{"id": "linear", "label": "Linear"},
	{"id": "spiral", "label": "Spiral"},
	{"id": "checker", "label": "Checker"},
]

@onready var popup: PopupPanel = $VBoxContainer/PopupPanel
@onready var items_box: HBoxContainer = $VBoxContainer/PopupPanel/ScrollContainer/Items
@onready var gallery_button: Button = $VBoxContainer/HotBar/Buttons/GalleryButton
@onready var pattern_button: Button = $VBoxContainer/HotBar/Buttons/PatternButton

var open_menu: String = ""

var drag_data: PictureData = null
var drag_ghost: TextureRect = null

func _ready() -> void:
	gallery_button.pressed.connect(toggle_menu.bind("gallery"))
	pattern_button.pressed.connect(toggle_menu.bind("pattern"))

func toggle_menu(menu: String) -> void:
	if open_menu == menu:
		close_menu()
		return
	open_menu = menu
	_clear_items()

	match menu:
		"gallery":
			for p in pictures:
				_add_picture_item(p)
		"pattern":
			for pat in PATTERNS:
				_add_item(pat.label, null, func(): pattern_chosen.emit(pat.id))

	popup.show()

func close_menu() -> void:
	open_menu = ""
	popup.hide()
	_clear_items()

func _clear_items() -> void:
	for c in items_box.get_children():
		c.queue_free()

func _add_item(label: String, icon: Texture2D, on_pick: Callable) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE 
	
	var b := Button.new()
	b.text = label
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.custom_minimum_size = Vector2(100, 100)
	b.add_theme_stylebox_override('normal', style)
	b.pressed.connect(func():
		on_pick.call()
		#close_menu())
		)  # remove this if I want it to stay open
	items_box.add_child(b)
	
func _add_picture_item(p: PictureData) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE 
	
	var b := Button.new()
	b.text = p.title
	b.icon = p.line_art
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.custom_minimum_size = Vector2(100, 100)
	b.add_theme_stylebox_override('normal', style)
	b.button_down.connect(_start_drag.bind(p))  # starts on press, not on click
	items_box.add_child(b)


func _start_drag(p: PictureData) -> void:
	drag_data = p
	drag_ghost = TextureRect.new()
	drag_ghost.texture = p.line_art
	drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_ghost.custom_minimum_size = Vector2(160, 160)
	drag_ghost.size = Vector2(160, 160)
	drag_ghost.modulate = Color(1, 1, 1, 0.7)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_ghost)
	close_menu()  # clear the popup so the world is visible
	_update_ghost()

func _input(event: InputEvent) -> void:
	if drag_data == null:
		return
	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_drag()

func _update_ghost() -> void:
	drag_ghost.position = get_viewport().get_mouse_position() - drag_ghost.size / 2.0

func _finish_drag() -> void:
	var screen_pos := get_viewport().get_mouse_position()
	var over_bar: bool = $VBoxContainer/HotBar.get_global_rect().has_point(screen_pos)

	if not over_bar:
		# screen position -> world position (accounts for camera pan and zoom)
		var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
		picture_dropped.emit(drag_data, world_pos)

	drag_ghost.queue_free()
	drag_ghost = null
	drag_data = null
