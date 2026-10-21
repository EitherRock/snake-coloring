class_name UIBar
extends Control

signal picture_dropped(data: PictureData, world_position: Vector2)
signal pattern_chosen(pattern_id: String)

const PATTERNS := [
	{"id": "radial", "label": "Radial"},
	{"id": "linear", "label": "Linear"},
	{"id": "spiral", "label": "Spiral"},
	{"id": "checker", "label": "Checker"},
]
const ITEM_SIZE := Vector2(150, 150)
const GHOST_SIZE := Vector2(160, 160)
const GHOST_ALPHA := 0.7
const CLOSE_AFTER_PICK := false  # true = popup closes after choosing a pattern
const DRAG_START_DISTANCE := 24.0
const DRAG_DIRECTION_BIAS := 1.5  # sideways movement must beat vertical by this factor
const GHOST_TOUCH_OFFSET := Vector2(0, -90)  # keeps the ghost above the finger

@export var pictures: Array[PictureData] = []

var open_menu: String = ""
var drag_data: PictureData = null
var drag_ghost: TextureRect = null
var _press_item: PictureData = null
var _press_pos := Vector2.ZERO

@onready var popup: PanelContainer = %PopupPanel
@onready var items_box: VBoxContainer = %Items
@onready var hotbar: Control = %HotBar
@onready var gallery_button: Button = %GalleryButton
@onready var pattern_button: Button = %PatternButton


func _ready() -> void:
	gallery_button.pressed.connect(toggle_menu.bind("gallery"))
	pattern_button.pressed.connect(toggle_menu.bind("pattern"))
	_apply_safe_area()


func _input(event: InputEvent) -> void:
	if drag_data == null:
		_check_drag_start(event)
		return

	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_drag()


func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win := Vector2(DisplayServer.window_get_size())
	var to_ui := get_viewport().get_visible_rect().size / win  # window pixels to UI units
	var right_inset := (win.x - safe.end.x) * to_ui.x
	$Side.offset_right = -maxf(right_inset, 0.0)

# ---------------------------------------------------------------------------
# Popup menu
# ---------------------------------------------------------------------------
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
				_add_pattern_item(pat)

	popup.show()


func close_menu() -> void:
	open_menu = ""
	popup.hide()
	_clear_items()


func _clear_items() -> void:
	for c in items_box.get_children():
		c.queue_free()


# ---------------------------------------------------------------------------
# Building items
# ---------------------------------------------------------------------------
func _add_pattern_item(pat: Dictionary) -> void:
	var b := _make_item_button(pat.label, null)
	b.pressed.connect(func():
		pattern_chosen.emit(pat.id)
		if CLOSE_AFTER_PICK:
			close_menu()
	)
	items_box.add_child(b)


func _add_picture_item(p: PictureData) -> void:
	var b := _make_item_button(p.title, p.line_art)
	b.button_down.connect(_on_item_down.bind(p))  # starts on press, not on click
	items_box.add_child(b)


# Shared look for every button in the popup
func _make_item_button(label: String, icon: Texture2D) -> Button:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE

	var b := Button.new()
	b.text = label
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = ITEM_SIZE
	b.add_theme_stylebox_override("normal", style)
	return b


# ---------------------------------------------------------------------------
# Drag and drop
# ---------------------------------------------------------------------------
func _start_drag(p: PictureData) -> void:
	drag_data = p

	drag_ghost = TextureRect.new()
	drag_ghost.texture = p.line_art
	drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_ghost.custom_minimum_size = GHOST_SIZE
	drag_ghost.size = GHOST_SIZE
	drag_ghost.modulate = Color(1, 1, 1, GHOST_ALPHA)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_ghost)

	close_menu()  # clear the popup so the world is visible
	_update_ghost()
	

func _check_drag_start(event: InputEvent) -> void:
	if _press_item == null:
		return

	if event is InputEventMouseMotion:
		var d := get_viewport().get_mouse_position() - _press_pos
		if absf(d.x) > DRAG_START_DISTANCE and absf(d.x) > absf(d.y) * DRAG_DIRECTION_BIAS:
			var p := _press_item
			_press_item = null
			_start_drag(p)
	elif event is InputEventMouseButton and not event.pressed:
		_press_item = null


func _update_ghost() -> void:
	var offset := GHOST_TOUCH_OFFSET if Platform.is_touch else Vector2.ZERO
	drag_ghost.position = get_viewport().get_mouse_position() - drag_ghost.size / 2.0 + offset

func _finish_drag() -> void:
	var screen_pos := get_viewport().get_mouse_position()

	# Releasing over the hotbar cancels the drag
	if not hotbar.get_global_rect().has_point(screen_pos):
		# screen position -> world position (accounts for camera pan and zoom)
		#var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
		var drop_pos := screen_pos + (GHOST_TOUCH_OFFSET if Platform.is_touch else Vector2.ZERO)
		var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * drop_pos
		picture_dropped.emit(drag_data, world_pos)

	drag_ghost.queue_free()
	drag_ghost = null
	drag_data = null


func _on_item_down(p: PictureData) -> void:
	if not Platform.is_touch:
		_start_drag(p)  # desktop: drag immediately
		return
	_press_item = p
	_press_pos = get_viewport().get_mouse_position()
