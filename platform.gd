extends Node

# True on phones, touchscreens, or when testing touch on desktop
var is_touch: bool = (
	DisplayServer.is_touchscreen_available()
	or OS.has_feature("mobile")
	or ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)
)

# Set by the joystick while a finger is steering. Click handlers check this
# so a steering touch isn't also treated as a tap.
var joystick_active: bool = false
