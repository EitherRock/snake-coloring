@tool
extends EditorScript

const FOLDER := "res://pictures/house/"
const SIZE := 1024

const ROOF := [Vector2(512, 260), Vector2(774, 500), Vector2(250, 500)]
const CHIMNEY_C := Vector2(630, 355)
const CHIMNEY_H := Vector2(30, 45)
const WALLS_C := Vector2(512, 675)
const WALLS_H := Vector2(212, 175)
const DOOR_C := Vector2(512, 775)
const DOOR_H := Vector2(50, 75)
const WIN_L_C := Vector2(405, 600)
const WIN_R_C := Vector2(619, 600)
const WIN_H := Vector2(45, 40)

const LINE_W := 12.0
const TUCK := 3.0  # masks extend this far under the lines to avoid white halos

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))

	var lines := _blank()
	var win_l := _blank()
	var win_r := _blank()
	var door := _blank()
	var chimney := _blank()
	var roof := _blank()
	var walls := _blank()

	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)

			var s_roof := _sd_polygon(p, ROOF)
			var s_chim := _sd_box(p, CHIMNEY_C, CHIMNEY_H)
			var s_walls := _sd_box(p, WALLS_C, WALLS_H)
			var s_door := _sd_box(p, DOOR_C, DOOR_H)
			var s_wl := _sd_box(p, WIN_L_C, WIN_H)
			var s_wr := _sd_box(p, WIN_R_C, WIN_H)

			# Line art: distance to the nearest outline
			var d := minf(absf(s_roof), absf(s_chim))
			d = minf(d, absf(s_walls))
			d = minf(d, absf(s_door))
			d = minf(d, absf(s_wl))
			d = minf(d, absf(s_wr))
			lines.set_pixel(x, y, Color(0, 0, 0, _cover(LINE_W * 0.5 - d)))

			# Simple shapes (negative distance = inside)
			win_l.set_pixel(x, y, Color(1, 1, 1, _cover(-s_wl + TUCK)))
			win_r.set_pixel(x, y, Color(1, 1, 1, _cover(-s_wr + TUCK)))
			door.set_pixel(x, y, Color(1, 1, 1, _cover(-s_door + TUCK)))
			chimney.set_pixel(x, y, Color(1, 1, 1, _cover(-s_chim + TUCK)))

			# Roof: triangle minus the chimney
			var roof_a := _cover(-s_roof + TUCK)
			var chim_hole := _cover(-s_chim - TUCK)
			roof.set_pixel(x, y, Color(1, 1, 1, roof_a * (1.0 - chim_hole)))

			# Walls: rectangle minus the door and both windows
			var walls_a := _cover(-s_walls + TUCK)
			var hole := maxf(_cover(-s_door - TUCK),
					maxf(_cover(-s_wl - TUCK), _cover(-s_wr - TUCK)))
			walls.set_pixel(x, y, Color(1, 1, 1, walls_a * (1.0 - hole)))

	lines.save_png(FOLDER + "lines.png")
	win_l.save_png(FOLDER + "mask_1_left_window.png")
	win_r.save_png(FOLDER + "mask_2_right_window.png")
	door.save_png(FOLDER + "mask_3_door.png")
	chimney.save_png(FOLDER + "mask_4_chimney.png")
	roof.save_png(FOLDER + "mask_5_roof.png")
	walls.save_png(FOLDER + "mask_6_walls.png")

	EditorInterface.get_resource_filesystem().scan()
	print("Done. Images saved to ", FOLDER)

func _blank() -> Image:
	return Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

# Turns a signed distance into a soft 0-1 alpha (smooth anti-aliased edges)
func _cover(v: float) -> float:
	return clampf(v + 0.5, 0.0, 1.0)

# Signed distance to a rectangle: negative inside, positive outside
func _sd_box(p: Vector2, center: Vector2, half: Vector2) -> float:
	var q := (p - center).abs() - half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)

# Signed distance to any polygon: negative inside, positive outside
func _sd_polygon(p: Vector2, pts: Array) -> float:
	var d := INF
	var inside := false
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var e := b - a
		var w := p - a
		var t := clampf(w.dot(e) / e.dot(e), 0.0, 1.0)
		d = minf(d, (w - e * t).length())
		if (a.y > p.y) != (b.y > p.y):
			if p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
				inside = not inside
	return -d if inside else d
