class_name RhythmGame
extends Node
## The court-performance rhythm minigame — a self-contained set-piece.
##
## It owns its own control-mode handoff (pushes MINIGAME on start, and ALWAYS
## pops it again through the single `_finish()` path, like `cutscene/Cutscene.gd`)
## and reports its result via `finished` — the launcher/room never reaches
## inside it. Content is a `RhythmChart` Resource, so new performances are data,
## not code. Notes fall down four lanes hit with the movement directions
## (`move_left/up/down/right`), so it's controller-first with no new input map.
##
## Usage: see `minigames/Performance.gd`.

signal finished(result: Dictionary)

# Lane 0..3 map to the four movement directions, laid out left-to-right.
const LANE_ACTIONS: Array[StringName] = [&"move_left", &"move_up", &"move_down", &"move_right"]
const LANE_GLYPHS: Array[String] = ["<", "^", "v", ">"]
const LANE_COLORS: Array[Color] = [
	Color(0.95, 0.55, 0.35), Color(0.95, 0.82, 0.40),
	Color(0.55, 0.85, 0.60), Color(0.55, 0.70, 0.95),
]

const TOP_Y := 26.0
const HIT_Y := 162.0
const LANE_W := 26.0
const LANE_GAP := 6.0

var _chart: RhythmChart
var _notes: Array = []                    # [{time, lane, judged}]
var _note_rects: Array[ColorRect] = []    # parallel to _notes
var _targets: Array[ColorRect] = []       # the four hit-line boxes

var _song_time := 0.0
var _running := false
var _finished := false

var _perfects := 0
var _goods := 0
var _misses := 0

var _canvas: CanvasLayer
var _score_label: Label
var _judge_label: Label


## Begin the performance. Safe to call once; pushes MINIGAME control-mode.
func start(chart: RhythmChart) -> void:
	_chart = chart
	for n in chart.get_notes():
		_notes.append({"time": n.time, "lane": n.lane, "judged": false})
	_build_ui()
	GameState.push_mode(GameState.Mode.MINIGAME)
	if chart.music != null:
		# Placeholder charts have no music; when real music lands, follow the
		# stream's playback position here instead of the delta clock below.
		AudioManager.play_music(chart.music)
	_running = true


func _process(delta: float) -> void:
	if not _running:
		return
	_song_time += delta
	_update_notes()
	if _song_time >= _chart.length():
		_finish(false)


func _update_notes() -> void:
	var travel := HIT_Y - TOP_Y
	for i in _notes.size():
		var note: Dictionary = _notes[i]
		var rect := _note_rects[i]
		if note.judged:
			continue
		var remaining: float = note.time - _song_time
		# A note past its window with no input is a miss.
		if remaining < -_chart.good_window:
			note.judged = true
			_misses += 1
			rect.visible = false
			_flash_target(note.lane, Color(0.8, 0.2, 0.2), false)
			_set_judge("MISS", Color(0.85, 0.3, 0.3))
			_update_score()
			continue
		var frac: float = remaining / _chart.approach   # 1 at spawn, 0 at hit line
		if frac > 1.0:
			rect.visible = false
			continue
		rect.visible = true
		var center_x := _lane_center(note.lane)
		rect.position = Vector2(center_x - rect.size.x * 0.5, HIT_Y - frac * travel - rect.size.y * 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("cancel"):
		_finish(true)
		get_viewport().set_input_as_handled()
		return
	for lane in LANE_ACTIONS.size():
		if event.is_action_pressed(LANE_ACTIONS[lane]):
			_judge(lane)
			get_viewport().set_input_as_handled()
			return


func _judge(lane: int) -> void:
	# Nearest unjudged note in this lane, within the (larger) good window.
	var best := -1
	var best_dist := _chart.good_window + 0.001
	for i in _notes.size():
		var note: Dictionary = _notes[i]
		if note.judged or note.lane != lane:
			continue
		var dist: float = absf(note.time - _song_time)
		if dist < best_dist:
			best_dist = dist
			best = i
	if best == -1:
		return   # nothing to hit; ignore stray presses (no penalty)

	_notes[best].judged = true
	_note_rects[best].visible = false
	if best_dist <= _chart.perfect_window:
		_perfects += 1
		_flash_target(lane, Color(1, 1, 0.7), true)
		_set_judge("PERFECT!", Color(1, 0.95, 0.6))
		AudioManager.play_sfx(&"success")
	else:
		_goods += 1
		_flash_target(lane, LANE_COLORS[lane], true)
		_set_judge("good", Color(0.7, 0.9, 0.7))
		AudioManager.play_sfx(&"ui")
	_update_score()


func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	_running = false
	# Remaining unjudged notes (e.g. on skip) count as misses so the tally is
	# always consistent and the world is left in a defined end-state.
	for note in _notes:
		if not note.judged:
			note.judged = true
			_misses += 1
	if _chart.music != null:
		AudioManager.stop_music()
	GameState.pop_mode()
	if _canvas != null:
		_canvas.queue_free()
	finished.emit(_result(skipped))


func _result(skipped: bool) -> Dictionary:
	var total := _perfects + _goods + _misses
	var accuracy := 0.0 if total == 0 else (_perfects + _goods * 0.5) / float(total)
	var tier := "great" if accuracy >= 0.8 else ("pass" if accuracy >= 0.5 else "flop")
	return {
		"perfects": _perfects, "goods": _goods, "misses": _misses,
		"total": total, "accuracy": accuracy, "tier": tier, "skipped": skipped,
	}


# --- Feedback (systemic juice, reused helpers) -------------------------------

func _flash_target(lane: int, color: Color, good: bool) -> void:
	var box := _targets[lane]
	var t := create_tween()
	box.color = color
	t.tween_property(box, "color", _target_base(lane), 0.18)
	if good:
		box.scale = Vector2(1.35, 1.35)
		t.parallel().tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		AudioManager.play_sfx(&"error")
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("shake_camera"):
			player.shake_camera(2.0, 0.2)


func _set_judge(text: String, color: Color) -> void:
	_judge_label.text = text
	_judge_label.modulate = color
	_judge_label.scale = Vector2(1.2, 1.2)
	var t := create_tween()
	t.tween_property(_judge_label, "scale", Vector2.ONE, 0.15)


func _update_score() -> void:
	_score_label.text = "Perfect %d   Good %d   Miss %d" % [_perfects, _goods, _misses]


# --- Layout / UI (built in code, like DialogueManager) -----------------------

func _lane_center(lane: int) -> float:
	var span := RhythmChart.LANES * LANE_W + (RhythmChart.LANES - 1) * LANE_GAP
	var start_x := (320.0 - span) * 0.5
	return start_x + lane * (LANE_W + LANE_GAP) + LANE_W * 0.5


func _target_base(lane: int) -> Color:
	var c := LANE_COLORS[lane]
	return Color(c.r, c.g, c.b, 0.35)


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 40   # above the world, below dialogue (50) and debug (90)
	add_child(_canvas)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(dim)

	var title := Label.new()
	title.text = _chart.title
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1, 0.88, 0.5))
	title.position = Vector2(0, 6)
	title.size = Vector2(320, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_canvas.add_child(title)

	# Lanes: a faint track, a hit-line box, and a direction glyph each.
	for lane in RhythmChart.LANES:
		var cx := _lane_center(lane)
		var track := ColorRect.new()
		track.color = Color(1, 1, 1, 0.04)
		track.position = Vector2(cx - LANE_W * 0.5, TOP_Y)
		track.size = Vector2(LANE_W, HIT_Y - TOP_Y + 12)
		_canvas.add_child(track)

		var target := ColorRect.new()
		target.color = _target_base(lane)
		target.size = Vector2(LANE_W, 10)
		target.pivot_offset = target.size * 0.5
		target.position = Vector2(cx - LANE_W * 0.5, HIT_Y - 5)
		_canvas.add_child(target)
		_targets.append(target)

		var glyph := Label.new()
		glyph.text = LANE_GLYPHS[lane]
		glyph.add_theme_font_size_override("font_size", 10)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.size = Vector2(LANE_W, 12)
		glyph.position = Vector2(cx - LANE_W * 0.5, HIT_Y + 8)
		_canvas.add_child(glyph)

	# One rect per note, pre-created so nothing allocates per frame.
	for note in _notes:
		var rect := ColorRect.new()
		rect.color = LANE_COLORS[note.lane]
		rect.size = Vector2(LANE_W - 4, 8)
		rect.visible = false
		_canvas.add_child(rect)
		_note_rects.append(rect)

	_judge_label = Label.new()
	_judge_label.add_theme_font_size_override("font_size", 12)
	_judge_label.position = Vector2(0, HIT_Y - 34)
	_judge_label.size = Vector2(320, 14)
	_judge_label.pivot_offset = Vector2(160, 7)
	_judge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_canvas.add_child(_judge_label)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 8)
	_score_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_score_label.position = Vector2(0, 182)
	_score_label.size = Vector2(320, 10)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_canvas.add_child(_score_label)
	_update_score()

	var hint := Label.new()
	hint.text = "hit the beat with the D-pad / arrows      [B] skip"
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	hint.position = Vector2(0, 191)
	hint.size = Vector2(320, 8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_canvas.add_child(hint)
