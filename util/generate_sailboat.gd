@tool
extends EditorScript

const OUT_PATH := "res://pictures/import/sailboat.png"
const SIZE := 1024
const LINE_W := 12.0

var seg_a := PackedVector2Array()
var seg_b := PackedVector2Array()
var circle_c := PackedVector2Array()
var circle_r := PackedFloat32Array()


func _run() -> void:
	seg_a.clear()
	seg_b.clear()
	circle_c.clear()
	circle_r.clear()

	# Sails sit on the hull's top edge, so the outlines overlap with no gap
	_add_polygon([Vector2(490, 230), Vector2(490, 620), Vector2(270, 620)])  # left sail
	_add_polygon([Vector2(510, 200), Vector2(510, 620), Vector2(740, 620)])  # right sail
	_add_segment(Vector2(500, 170), Vector2(500, 620))                       # mast
	_add_polygon([Vector2(500, 170), Vector2(580, 192), Vector2(500, 214)])  # flag
	_add_polygon([Vector2(250, 620), Vector2(774, 620), Vector2(700, 710), Vector2(324, 710)])  # hull
	_add_polygon([Vector2(60, 710), Vector2(964, 710), Vector2(964, 900), Vector2(60, 900)])    # sea
	_add_circle(Vector2(800, 230), 90.0)  # sun
	_add_circle(Vector2(512, 665), 22.0)  # porthole

	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := INF
			for i in seg_a.size():
				d = minf(d, _dist_to_segment(p, seg_a[i], seg_b[i]))
			for i in circle_c.size():
				d = minf(d, absf(p.distance_to(circle_c[i]) - circle_r[i]))
			# Black line with soft anti-aliased edges, transparent elsewhere
			img.set_pixel(x, y, Color(0, 0, 0, clampf(LINE_W * 0.5 - d + 0.5, 0.0, 1.0)))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_PATH.get_base_dir()))
	img.save_png(OUT_PATH)
	EditorInterface.get_resource_filesystem().scan()
	print("Saved ", OUT_PATH)


func _add_segment(a: Vector2, b: Vector2) -> void:
	seg_a.append(a)
	seg_b.append(b)


func _add_polygon(points: Array) -> void:
	for i in points.size():
		_add_segment(points[i], points[(i + 1) % points.size()])


func _add_circle(center: Vector2, radius: float) -> void:
	circle_c.append(center)
	circle_r.append(radius)


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var e := b - a
	var t := clampf((p - a).dot(e) / e.dot(e), 0.0, 1.0)
	return p.distance_to(a + e * t)
