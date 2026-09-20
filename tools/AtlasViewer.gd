extends Node
## Dev-only: renders every tile in the placeholder sheet with its index label,
## screenshots it, and quits. Lets us pick correct tile indices by eye.

const OUT := "res://.captures/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Use real window pixels so the contact sheet is large and readable.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(1024, 960)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var sheet := Art.sheet()
	var cols := int(sheet.get_width() / Art.TILE_SIZE)
	var rows := int(sheet.get_height() / Art.TILE_SIZE)

	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.position = Vector2(12, 12)
	add_child(grid)

	for i in cols * rows:
		var cell := VBoxContainer.new()
		var tex := TextureRect.new()
		tex.texture = Art.tile(i)
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(tex)
		var label := Label.new()
		label.text = str(i)
		label.add_theme_font_size_override("font_size", 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(label)
		grid.add_child(cell)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out_path := ProjectSettings.globalize_path(OUT + "atlas.png")
	var err := img.save_png(out_path)
	print("atlas -> %s (err %d) size=%s" % [out_path, err, img.get_size()])
	get_tree().quit()
