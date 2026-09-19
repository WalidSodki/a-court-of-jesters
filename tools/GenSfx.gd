extends Node
## Dev-only: synthesizes tiny placeholder SFX as .wav files, then quits.
## Run once, then re-import so AudioManager can load them.
##   godot --path . res://tools/GenSfx.tscn

const OUT := "res://audio/"
const RATE := 22050


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_save("pickup", _seq([[880, 0.05, "square", 0.32], [1320, 0.07, "square", 0.28]]))
	_save("ui", _seq([[1000, 0.035, "square", 0.20]]))
	_save("dialogue", _seq([[620, 0.028, "sine", 0.14]]))
	_save("footstep", _noise(0.05, 0.12))
	_save("error", _sweep(320, 150, 0.22, "saw", 0.28))
	_save("combine", _seq([[523, 0.06, "square", 0.24], [659, 0.06, "square", 0.24], [784, 0.10, "square", 0.26]]))
	_save("success", _seq([[523, 0.07, "sine", 0.30], [659, 0.07, "sine", 0.30], [784, 0.07, "sine", 0.30], [1046, 0.13, "sine", 0.33]]))

	print("SFX generated in ", OUT)
	get_tree().quit()


func _w(kind: String, phase: float) -> float:
	var f := phase - floorf(phase)
	match kind:
		"sine":
			return sin(TAU * phase)
		"square":
			return 1.0 if f < 0.5 else -1.0
		"saw":
			return 2.0 * f - 1.0
	return 0.0


func _tone(freq: float, dur: float, kind: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var phase := 0.0
	var inc := freq / RATE
	for i in n:
		var t := float(i) / n
		var env := minf(1.0, t / 0.05) * pow(1.0 - t, 1.5)
		a[i] = _w(kind, phase) * env * vol
		phase += inc
	return a


func _seq(notes: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for note in notes:
		out.append_array(_tone(note[0], note[1], note[2], note[3]))
	return out


func _sweep(f0: float, f1: float, dur: float, kind: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq: float = lerpf(f0, f1, t)
		var env := minf(1.0, t / 0.03) * pow(1.0 - t, 1.2)
		a[i] = _w(kind, phase) * env * vol
		phase += freq / RATE
	return a


func _noise(dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / n
		var env := pow(1.0 - t, 2.0)
		a[i] = randf_range(-1.0, 1.0) * env * vol
	return a


func _save(name: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	var err := w.save_to_wav(OUT + name + ".wav")
	print("  %s.wav (err %d, %d samples)" % [name, err, samples.size()])
