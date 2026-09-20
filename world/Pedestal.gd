class_name Pedestal
extends Interactable
## The stage prop stand. Accepts a required item (the combined marotte),
## sets a story flag, and gives a satisfying flourish. This is the seam the
## Milestone 2 court-performance minigame will hook onto.

@export var required_item: ItemData
@export var flag: String = "stage_ready"
## The performance played when the stage is ready. Data-driven; assign in the
## inspector (e.g. res://minigames/charts/court_debut.tres).
@export var chart: RhythmChart
var done := false
var performed := false

signal completed


func _on_interact(_by: Node) -> void:
	if done:
		await _perform()
		return

	# "Use item on world object": prefer the explicitly held item, but accept
	# simply carrying it so the puzzle is forgiving.
	var have := Inventory.held_item == required_item or Inventory.has(required_item)
	if not have:
		Dialogue.start([{"text": "The stage needs a proper prop. Perhaps something can be made from what you carry."}])
		return

	done = true
	prompt = "Perform"
	if Inventory.has(required_item):
		Inventory.remove(required_item)
	GameState.set_flag(flag, true)
	AudioManager.play_sfx(&"success")
	_flourish()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("shake_camera"):
		player.shake_camera(3.0, 0.35)
	completed.emit()

	var impressed := GameState.has_flag("steward_impressed")
	var line := "You set the %s upon the stage. Lanterns flare to life and the court leans in, delighted." % required_item.display_name
	if not impressed:
		line = "You set the %s upon the stage. The court quiets — the steward watches, unamused." % required_item.display_name
	Dialogue.start([{"text": line}])


## Launch the rhythm minigame, then play a reaction that branches on the earlier
## steward choice and the score. Consequences go through GameState flags.
func _perform() -> void:
	if performed:
		Dialogue.start([{"text": "The court still hums with talk of your performance."}])
		return
	if chart == null:
		Dialogue.start([{"text": "The stage is set. The court is waiting."}])
		return
	performed = true
	var result := await Perform.run(chart)
	GameState.set_flag("performance_done", true)
	GameState.set_flag("performance_tier", result.tier)
	await Cutscene.play(func() -> void:
		Dialogue.start(_reaction_lines(GameState.has_flag("steward_impressed"), result.tier))
		await Dialogue.finished
	)


func _reaction_lines(impressed: bool, tier: String) -> Array:
	var reactions := {
		"great": {
			true: "The royal family rises, delighted — the steward permits himself a thin, approving smile.",
			false: "The court gasps, then roars with laughter. Even the doubting steward cannot hide his surprise.",
		},
		"pass": {
			true: "Polite applause ripples through the hall. The steward gives a small, satisfied nod.",
			false: "A scattering of claps. The steward's eyes narrow — you have not yet won this house.",
		},
		"flop": {
			true: "The music falters and dies. The steward looks away, disappointed he vouched for you.",
			false: "Silence, then a single cruel snicker from the gallery. The steward has seen enough.",
		},
	}
	var tier_lines: Dictionary = reactions.get(tier, reactions["pass"])
	return [{"text": String(tier_lines[impressed])}]


func _flourish() -> void:
	var s := get_node_or_null("Sprite") as Node2D
	if s == null:
		return
	var t := create_tween()
	t.tween_property(s, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "scale", Vector2.ONE, 0.15)
