class_name Cutscene
extends RefCounted
## Minimal scripted-sequence helper. A cutscene is just an async function that
## drives in-game actors; this wrapper owns the control-mode handoff so every
## cutscene disables input the same way and ALWAYS restores it when finished.
##
## Full tooling (timelines, actor commands, skip-to-end state) is Milestone 2;
## this proves the handoff the whole game relies on.
##
## Usage:
##   await Cutscene.play(func(): await _my_sequence())

static func play(sequence: Callable) -> void:
	GameState.push_mode(GameState.Mode.CUTSCENE)
	await sequence.call()
	GameState.pop_mode()
