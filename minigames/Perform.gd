class_name Perform
extends RefCounted
## Thin launcher for the court-performance minigame, mirroring
## `cutscene/Cutscene.gd`'s `play()`: it instances the modular `RhythmGame`
## scene, runs it, and returns the result — so callers (the Pedestal/stage, a
## debug shortcut) depend only on this and a `RhythmChart`, never on the
## minigame's internals.
##
## (Named `Perform`, not `Performance`, to avoid Godot's built-in `Performance`
## monitor class.)
##
## Usage:
##   var result := await Perform.run(chart)
##   # result = {perfects, goods, misses, total, accuracy, tier, skipped}

const SCENE := preload("res://minigames/RhythmGame.tscn")


static func run(chart: RhythmChart) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var game: RhythmGame = SCENE.instantiate()
	tree.current_scene.add_child(game)
	game.start(chart)
	var result: Dictionary = await game.finished
	if is_instance_valid(game):
		game.queue_free()
	return result
