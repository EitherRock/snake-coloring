@tool
extends EditorScript

const SOURCE := "res://pictures/import/sailboat.png"
const OUT_FOLDER := "res://pictures/sailboat/"       

func _run() -> void:
	var importer := LineArtImporter.new()
	# importer.gap_close = 3   # uncomment and adjust to tune (see below)

	var started := Time.get_ticks_msec()
	var data := importer.import_file(SOURCE, OUT_FOLDER)
	if data:
		print("Imported %d regions in %.1f s" % [data.regions.size(), (Time.get_ticks_msec() - started) / 1000.0])
	EditorInterface.get_resource_filesystem().scan()
