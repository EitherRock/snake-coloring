@tool
extends EditorScript

const FOLDER := "res://pictures/smiley/"

func _run() -> void:
	var data := PictureData.new()
	data.title = "smiley"
	data.line_art = load(FOLDER + "lines.png")
	data.size = data.line_art.get_size()

	var files: Array[String] = []
	for f in DirAccess.open(FOLDER).get_files():
		if f.begins_with("mask_") and f.ends_with(".png"):
			files.append(f)
	files.sort()  # "mask_1_..." sorts before "mask_2_..."

	for i in files.size():
		var region := RegionData.new()
		region.mask = load(FOLDER + files[i])
		region.fill_order = i
		_compute_origin(region)
		data.regions.append(region)
		print("Baked ", files[i], "  origin=", region.fill_origin, "  max_distance=", region.max_distance)

	ResourceSaver.save(data, FOLDER + "picture_data.tres")
	print("Saved picture_data.tres")

func _compute_origin(region: RegionData) -> void:
	var img := region.mask.get_image()
	var w := img.get_width()
	var h := img.get_height()

	var sum := Vector2.ZERO
	var count := 0
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				sum += Vector2(x, y)
				count += 1
	if count == 0:
		return

	var origin := sum / count
	var max_d := 1.0
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				max_d = max(max_d, origin.distance_to(Vector2(x, y)))

	region.fill_origin = origin / Vector2(w, h)
	region.max_distance = max_d
