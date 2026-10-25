@tool
class_name LineArtImporter
extends RefCounted

# --- Settings (change from the runner script) ---
var working_size: int = 1024    # long edge, in pixels
var line_threshold: float = 0.5 # pixels darker than this count as line
var gap_close: int = 2          # closes breaks in the outline up to about twice this
var tuck: int = 2               # how far fills extend under the lines
var min_area: int = 250         # regions smaller than this are dropped as specks
var max_bands: int = 10         # must match MAX_BANDS in Region.gd and the shader

var width: int = 0
var height: int = 0

var _labels := PackedInt32Array()  # -1 = wall, 0 = none, 1..n = region
var _comps: Array[Dictionary] = []
var _min_x := PackedInt32Array()
var _min_y := PackedInt32Array()
var _max_x := PackedInt32Array()
var _max_y := PackedInt32Array()
var _area := PackedInt32Array()
var _max_d2 := PackedFloat32Array()


func import_file(source: String, out_folder: String) -> PictureData:
	var img := Image.load_from_file(source)
	if img == null:
		push_error("Could not load " + source)
		return null
	_prepare_image(img)
	width = img.get_width()
	height = img.get_height()
	var n := width * height

	# 1. Line mask, plus clean line art (black, alpha = darkness)
	var px := img.get_data()
	var darkness := PackedByteArray()
	darkness.resize(n)
	var blocked := PackedByteArray()
	blocked.resize(n)
	var art := PackedByteArray()
	art.resize(n * 4)
	var cut := int((1.0 - line_threshold) * 255.0)
	for i in n:
		var o := i * 4
		var luma := (0.299 * px[o] + 0.587 * px[o + 1] + 0.114 * px[o + 2]) / 255.0
		luma = lerpf(1.0, luma, px[o + 3] / 255.0)  # transparent counts as white paper
		var d := int(round((1.0 - luma) * 255.0))
		darkness[i] = d
		art[o + 3] = d
		if d > cut:
			blocked[i] = 1

	# 2-5. Close gaps, label regions, find origins, grow under the lines
	var walls := _dilate(blocked, gap_close)
	var count := _label_components(walls)
	if count == 0:
		push_error("No fillable regions found. Check that the outlines are closed and dark.")
		return null
	var origin := _find_origins(count)
	_grow_labels(gap_close + tuck)
	_measure(count, origin)

	# 6. Bake
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_folder))
	var data := _build_data(source.get_file().get_basename(), count, origin, art)
	ResourceSaver.save(data, out_folder + "picture_data.res")
	_save_preview(out_folder + "preview.png", darkness, count)
	print("Saved ", out_folder, "picture_data.res and preview.png")
	return data


func _prepare_image(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var longest := maxi(img.get_width(), img.get_height())
	if longest != working_size:
		var s := float(working_size) / float(longest)
		img.resize(maxi(1, roundi(img.get_width() * s)), maxi(1, roundi(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)


# Thickens the lines by `radius` pixels so small gaps close
func _dilate(src: PackedByteArray, radius: int) -> PackedByteArray:
	var cur := src.duplicate()
	for _r in radius:
		var nxt := cur.duplicate()
		for y in height:
			for x in width:
				var i := y * width + x
				if cur[i] == 1:
					continue
				if (x > 0 and cur[i - 1] == 1) or (x < width - 1 and cur[i + 1] == 1) \
						or (y > 0 and cur[i - width] == 1) or (y < height - 1 and cur[i + width] == 1):
					nxt[i] = 1
		cur = nxt
	return cur


# Flood-fills the open areas, drops background and specks, returns the region count
@warning_ignore("integer_division")
func _label_components(walls: PackedByteArray) -> int:
	var n := width * height
	_labels.resize(n)
	for i in n:
		_labels[i] = -1 if walls[i] == 1 else 0

	var stack := PackedInt32Array()
	stack.resize(n)  # each pixel is pushed at most once
	_comps.clear()
	var next_id := 1
	for start in n:
		if _labels[start] != 0:
			continue
		_labels[start] = next_id
		stack[0] = start
		var sp := 1
		var area := 0
		var border := false
		while sp > 0:
			sp -= 1
			var p := stack[sp]
			var x := p % width
			var y := p / width
			area += 1
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				border = true
			if x > 0 and _labels[p - 1] == 0:
				_labels[p - 1] = next_id
				stack[sp] = p - 1
				sp += 1
			if x < width - 1 and _labels[p + 1] == 0:
				_labels[p + 1] = next_id
				stack[sp] = p + 1
				sp += 1
			if y > 0 and _labels[p - width] == 0:
				_labels[p - width] = next_id
				stack[sp] = p - width
				sp += 1
			if y < height - 1 and _labels[p + width] == 0:
				_labels[p + width] = next_id
				stack[sp] = p + width
				sp += 1
		_comps.append({"area": area, "border": border})
		next_id += 1

	# Keep interior regions that are big enough, and renumber them 1..kept
	var remap := PackedInt32Array()
	remap.resize(_comps.size() + 1)
	var kept := 0
	var bg := 0
	var specks := 0
	for c in _comps.size():
		if _comps[c].border:
			bg += 1
		elif _comps[c].area < min_area:
			specks += 1
		else:
			kept += 1
			remap[c + 1] = kept
	for i in n:
		if _labels[i] > 0:
			_labels[i] = remap[_labels[i]]

	print("Regions kept: %d   background areas dropped: %d   specks dropped: %d" % [kept, bg, specks])
	return kept


# Finds the point deepest inside each region (distance to the nearest edge)
@warning_ignore("integer_division")
func _find_origins(count: int) -> PackedInt32Array:
	var n := width * height
	var big := 1 << 20
	var dist := PackedInt32Array()
	dist.resize(n)  # 0 = not in a region

	for y in height:
		for x in width:
			var i := y * width + x
			var l := _labels[i]
			if l <= 0:
				continue
			var edge := x == 0 or y == 0 or x == width - 1 or y == height - 1
			if not edge:
				edge = _labels[i - 1] != l or _labels[i + 1] != l \
						or _labels[i - width] != l or _labels[i + width] != l
			dist[i] = 1 if edge else big

	for y in height:
		for x in width:
			var i := y * width + x
			if dist[i] <= 1:
				continue
			var best := dist[i]
			if x > 0:
				best = mini(best, dist[i - 1] + 1)
			if y > 0:
				best = mini(best, dist[i - width] + 1)
			dist[i] = best

	for y in range(height - 1, -1, -1):
		for x in range(width - 1, -1, -1):
			var i := y * width + x
			if dist[i] <= 1:
				continue
			var best := dist[i]
			if x < width - 1:
				best = mini(best, dist[i + 1] + 1)
			if y < height - 1:
				best = mini(best, dist[i + width] + 1)
			dist[i] = best

	var origin := PackedInt32Array()
	origin.resize(count + 1)
	var best_d := PackedInt32Array()
	best_d.resize(count + 1)
	for i in n:
		var l := _labels[i]
		if l > 0 and dist[i] > best_d[l]:
			best_d[l] = dist[i]
			origin[l] = i
	return origin


# Grows each region into the wall pixels so fills tuck under the line art
func _grow_labels(steps: int) -> void:
	for _s in steps:
		var prev := _labels.duplicate()
		for y in height:
			for x in width:
				var i := y * width + x
				if prev[i] != -1:
					continue
				var l := 0
				if x > 0 and prev[i - 1] > 0:
					l = prev[i - 1]
				elif x < width - 1 and prev[i + 1] > 0:
					l = prev[i + 1]
				elif y > 0 and prev[i - width] > 0:
					l = prev[i - width]
				elif y < height - 1 and prev[i + width] > 0:
					l = prev[i + width]
				if l > 0:
					_labels[i] = l


# Bounding box, area and farthest distance from the origin, per region
@warning_ignore("integer_division")
func _measure(count: int, origin: PackedInt32Array) -> void:
	for arr in [_min_x, _min_y, _max_x, _max_y, _area]:
		arr.resize(count + 1)
	_max_d2.resize(count + 1)
	_min_x.fill(width)
	_min_y.fill(height)
	_max_x.fill(0)
	_max_y.fill(0)
	_area.fill(0)
	_max_d2.fill(0.0)

	for y in height:
		for x in width:
			var l := _labels[y * width + x]
			if l <= 0:
				continue
			if x < _min_x[l]:
				_min_x[l] = x
			if x > _max_x[l]:
				_max_x[l] = x
			if y < _min_y[l]:
				_min_y[l] = y
			if y > _max_y[l]:
				_max_y[l] = y
			_area[l] += 1
			var dx := x - origin[l] % width
			var dy := y - origin[l] / width
			var d2 := float(dx * dx + dy * dy)
			if d2 > _max_d2[l]:
				_max_d2[l] = d2


@warning_ignore("integer_division")
func _build_data(title: String, count: int, origin: PackedInt32Array, art: PackedByteArray) -> PictureData:
	var data := PictureData.new()
	data.title = title
	data.size = Vector2(width, height)
	data.line_art = ImageTexture.create_from_image(
			Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, art))

	# One cropped mask image per region
	var masks: Array[Image] = [null]  # index 0 unused
	for l in range(1, count + 1):
		masks.append(Image.create(_max_x[l] - _min_x[l] + 1, _max_y[l] - _min_y[l] + 1, false, Image.FORMAT_RGBA8))
	for y in height:
		for x in width:
			var l := _labels[y * width + x]
			if l > 0:
				masks[l].set_pixel(x - _min_x[l], y - _min_y[l], Color.WHITE)

	# Smallest regions first
	var order: Array = range(1, count + 1)
	order.sort_custom(func(a: int, b: int): return _area[a] < _area[b])
	var largest := 1
	for l in range(1, count + 1):
		largest = maxi(largest, _area[l])

	for rank in order.size():
		var l: int = order[rank]
		var rd := RegionData.new()
		rd.mask = ImageTexture.create_from_image(masks[l])
		rd.baked_bounds = Rect2i(_min_x[l], _min_y[l], _max_x[l] - _min_x[l] + 1, _max_y[l] - _min_y[l] + 1)
		rd.fill_origin = Vector2((origin[l] % width + 0.5) / width, (origin[l] / width + 0.5) / height)
		rd.max_distance = sqrt(_max_d2[l]) + 1.0
		rd.max_dots = clampi(ceili(max_bands * sqrt(float(_area[l]) / float(largest))), mini(3, max_bands), max_bands)
		rd.fill_order = rank
		data.regions.append(rd)
	return data


# Every region in a random color, with the line art on top, so leaks and misses are obvious
func _save_preview(path: String, darkness: PackedByteArray, count: int) -> void:
	var palette := PackedByteArray()
	palette.resize((count + 1) * 3)
	palette[0] = 255
	palette[1] = 255
	palette[2] = 255
	for l in range(1, count + 1):
		var c := Color.from_hsv(randf(), 0.45, 0.95)
		palette[l * 3] = int(c.r * 255.0)
		palette[l * 3 + 1] = int(c.g * 255.0)
		palette[l * 3 + 2] = int(c.b * 255.0)

	var n := width * height
	var out := PackedByteArray()
	out.resize(n * 4)
	for i in n:
		var l := maxi(_labels[i], 0)
		var k := 1.0 - darkness[i] / 255.0
		var o := i * 4
		out[o] = int(palette[l * 3] * k)
		out[o + 1] = int(palette[l * 3 + 1] * k)
		out[o + 2] = int(palette[l * 3 + 2] * k)
		out[o + 3] = 255
	Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, out).save_png(path)
