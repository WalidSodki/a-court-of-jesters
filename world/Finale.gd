class_name Finale
extends Room
## The closing room of the vertical slice. On entry it plays a reaction cutscene
## that reads everything the player did across the golden path (perform → sneak →
## flee) and branches the court's verdict on it — the "choices matter" payoff.
## Reuses the base Room spawn/camera setup and layers the outro on top.

var _outro_played := false


func _ready() -> void:
	super._ready()
	# Reaching this room IS escaping the chase — record the success flag.
	GameState.set_flag("escaped_threat", true)
	call_deferred("_run_outro")


func _run_outro() -> void:
	if _outro_played:
		return
	_outro_played = true
	await Cutscene.play(_outro_sequence)
	GameState.set_flag("slice_complete", true)


func _outro_sequence() -> void:
	Dialogue.start(_verdict_lines())
	await Dialogue.finished


## Build the closing lines from the accrued flags: the performance tier and the
## steward's opinion set the tone; getting caught while sneaking/fleeing colours it.
func _verdict_lines() -> Array:
	var tier := String(GameState.get_flag("performance_tier", "pass"))
	var impressed := GameState.has_flag("steward_impressed")
	var slipped_clean := not GameState.has_flag("caught_sneaking") and not GameState.has_flag("caught_fleeing")

	var lines: Array = [
		{"text": "You spill into the throne room, breath ragged. The court turns to look."},
	]

	var opening := {
		"great": "Word of your dazzling performance has already reached the throne.",
		"pass": "The court recalls your turn upon the stage — a fair showing.",
		"flop": "The memory of your fumbled performance still hangs in the air.",
	}
	lines.append({"speaker": "Steward", "text": String(opening.get(tier, opening["pass"]))})

	if slipped_clean:
		lines.append({"speaker": "Steward", "text": "And not a soul saw you slip through the dark. Resourceful."})
	else:
		lines.append({"speaker": "Steward", "text": "Though word travels of a jester caught where he ought not to be. We are watching you now."})

	if impressed:
		lines.append({"speaker": "Steward", "text": "The family is charmed. You have earned your place at this court — for now."})
	else:
		lines.append({"text": "The steward says nothing more. You have survived the night, but won no friends here."})

	lines.append({"text": "( The vertical slice ends here. )"})
	return lines
