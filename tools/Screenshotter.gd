extends Node
## Dev-only: drives the game through key states via the World manager and saves
## screenshots. Run: godot --path . res://tools/Screenshotter.tscn

const OUT := "res://.captures/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	World.go_to("res://world/GreatHall.tscn")
	await _wait(0.9)
	await _shot("01_intro")

	await _tap("interact")      # skip intro
	await _wait(0.8)
	await _shot("02_room")

	var steward := _find("Talk")
	var player := _player()
	if steward != null and player != null:
		steward.interact(player)
		await _wait(0.4)
		await _shot("03_dialogue")
		await _tap("interact")  # advance to choice
		await _wait(0.5)
		await _shot("04_choice")
		await _tap("interact")  # pick "bow deeply" (impressed)
		await _wait(0.4)
		await _tap("interact")  # give stick + final line
		await _wait(0.4)
		await _tap("interact")  # close
		await _wait(0.4)

	Inventory.add(load("res://items/bells.tres"))
	Inventory.add(load("res://items/stick.tres"))
	await _wait(0.2)
	InventoryScreen.open()
	await _wait(0.4)
	await _shot("05_inventory")
	InventoryScreen.close()
	await _wait(0.3)

	Inventory.combine(load("res://items/bells.tres"), load("res://items/stick.tres"))
	Inventory.set_held(load("res://items/baton.tres"))
	var stage := _find("Place prop")
	if stage != null:
		stage.interact(_player())
		await _wait(0.6)
		await _shot("06_stage_lit")

	# Close the payoff dialogue, then head through the door to the antechamber.
	await _tap("interact")
	await _wait(0.4)
	var door := _find("Enter")
	if door != null:
		door.interact(_player())
		await _wait(1.2)   # fade out + load + fade in
		await _shot("07_antechamber")
		var note := _find("Read")
		if note != null:
			note.interact(_player())
			await _wait(0.4)
			await _shot("08_note")

	await _wait(0.2)
	get_tree().quit()


func _room() -> Node:
	return World.current_room


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _find(prompt: String) -> Interactable:
	var room := _room()
	if room == null:
		return null
	return _find_in(room, prompt)


func _find_in(node: Node, prompt: String) -> Interactable:
	for n in node.get_children():
		if n is Interactable and (n as Interactable).prompt == prompt:
			return n
		var deeper := _find_in(n, prompt)
		if deeper != null:
			return deeper
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _tap(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("shot %s (err %d)" % [name, err])
