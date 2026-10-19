extends Control

signal picture_chosen(data: PictureData)
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
				_add_item(p.title, p.line_art, func(): picture_chosen.emit(p))
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
