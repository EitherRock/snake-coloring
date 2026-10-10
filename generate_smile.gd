@tool
extends EditorScript

const FOLDER := "res://pictures/smiley/"
const SIZE := 1024

const CENTER := Vector2(512, 512)
const FACE_R := 440.0
const LEFT_EYE := Vector2(370, 400)
const RIGHT_EYE := Vector2(654, 400)
const EYE_R := 70.0

const MOUTH_C := Vector2(512, 540)
const MOUTH_R := 230.0
const MOUTH_A0 := 0.436  # ~25 degrees
const MOUTH_A1 := 2.705  # ~155 degrees

const LINE_W := 12.0
const TUCK := 3.0  # masks extend this far under the lines to avoid white halos

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))

	var lines := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var left := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var right := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var face := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)

			# Line art: distance to the nearest outline
			var d := absf(p.distance_to(CENTER) - FACE_R)
			d = minf(d, absf(p.distance_to(LEFT_EYE) - EYE_R))
			d = minf(d, absf(p.distance_to(RIGHT_EYE) - EYE_R))
			d = minf(d, _mouth_distance(p))
			lines.set_pixel(x, y, Color(0, 0, 0, _cover(LINE_W * 0.5 - d)))

			# Eye masks
			left.set_pixel(x, y, Color(1, 1, 1, _cover(EYE_R + TUCK - p.distance_to(LEFT_EYE))))
			right.set_pixel(x, y, Color(1, 1, 1, _cover(EYE_R + TUCK - p.distance_to(RIGHT_EYE))))

			# Face mask: big circle minus the two eye circles
			var face_a := _cover(FACE_R + TUCK - p.distance_to(CENTER))
			var hole := maxf(
				_cover(EYE_R - TUCK - p.distance_to(LEFT_EYE)),
				_cover(EYE_R - TUCK - p.distance_to(RIGHT_EYE)))
			face.set_pixel(x, y, Color(1, 1, 1, face_a * (1.0 - hole)))

	lines.save_png(FOLDER + "lines.png")
	left.save_png(FOLDER + "mask_1_left_eye.png")
	right.save_png(FOLDER + "mask_2_right_eye.png")
	face.save_png(FOLDER + "mask_3_face.png")

	EditorInterface.get_resource_filesystem().scan()
	print("Done. Images saved to ", FOLDER)

# Turns a signed distance into a soft 0-1 alpha (gives smooth anti-aliased edges)
func _cover(v: float) -> float:
	return clampf(v + 0.5, 0.0, 1.0)

# Distance from p to the smile arc, with rounded ends
func _mouth_distance(p: Vector2) -> float:
	var v := p - MOUTH_C
	var a := atan2(v.y, v.x)
	if a >= MOUTH_A0 and a <= MOUTH_A1:
		return absf(v.length() - MOUTH_R)
	var e0 := MOUTH_C + Vector2.from_angle(MOUTH_A0) * MOUTH_R
	var e1 := MOUTH_C + Vector2.from_angle(MOUTH_A1) * MOUTH_R
	return minf(p.distance_to(e0), p.distance_to(e1))
