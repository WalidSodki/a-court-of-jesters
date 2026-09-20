class_name RhythmChart
extends Resource
## A rhythm-minigame chart, defined as data so charts are authored without code.
##
## Notes sit on a grid: `pattern[i]` is the lane (0..3) for step i, or -1 for a
## rest. Step spacing comes from `bpm` and `step_beats`, so authoring a chart is
## just writing a list of lane indices — same data-as-content spirit as
## `items/ItemData.gd` and `items/CombineRecipe.gd`.

const LANES := 4

@export var title: String = "Performance"
@export var bpm: float = 100.0
## Beats between steps (1.0 = quarter notes, 0.5 = eighths).
@export var step_beats: float = 1.0
## Silent lead-in before the first note reaches the hit line, in seconds.
@export var lead_in: float = 2.0
## One entry per step: lane index 0..3, or -1 for a rest.
@export var pattern: PackedInt32Array = PackedInt32Array()
## How long a note falls before reaching the hit line, in seconds.
@export var approach: float = 1.4
## Timing windows (seconds) either side of a note's target time.
@export var perfect_window: float = 0.06
@export var good_window: float = 0.14
## Optional music; if set, the conductor follows its playback position.
@export var music: AudioStream


func step_duration() -> float:
	return (60.0 / maxf(bpm, 1.0)) * step_beats


## Expanded notes as [{time: float, lane: int}], in play order.
func get_notes() -> Array:
	var notes: Array = []
	var dt := step_duration()
	for i in pattern.size():
		var lane := pattern[i]
		if lane < 0 or lane >= LANES:
			continue
		notes.append({"time": lead_in + i * dt, "lane": lane})
	return notes


## Total chart length in seconds (last step + a short tail).
func length() -> float:
	return lead_in + pattern.size() * step_duration() + 1.0
