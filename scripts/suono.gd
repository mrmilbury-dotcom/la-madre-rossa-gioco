## Suono: un respiro sintetico, senza file audio.
## Rumore marrone filtrato (il mare dietro le paratie) + una nota grave che
## pulsa lenta (la struttura che respira). Con la risonanza compare una
## seconda nota leggermente stonata: i battimenti rendono l'aria instabile.
extends AudioStreamPlayer

var risonanza: float = 0.0    # 0..1, impostata dall'interfaccia
var attivo: bool = true

const FREQ := 22050.0
var _gen: AudioStreamGeneratorPlayback
var _fase1 := 0.0
var _fase2 := 0.0
var _fase_lfo := 0.0
var _marrone := 0.0
var _filtro := 0.0
var _volume := 0.0


func _ready() -> void:
	var g := AudioStreamGenerator.new()
	g.mix_rate = FREQ
	g.buffer_length = 0.4
	stream = g
	volume_db = -6.0
	# Sul web Godot usa di default la riproduzione a "campioni", che non
	# supporta i suoni generati in tempo reale: forziamo lo streaming.
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM


## Il browser permette l'audio solo dopo un clic: si avvia da lì.
func avvia() -> void:
	if not playing:
		play()
		_gen = get_stream_playback()


func _process(_delta: float) -> void:
	if _gen == null:
		return
	var n := _gen.get_frames_available()
	var obiettivo := (0.55 + risonanza * 0.45) if attivo else 0.0
	for i in n:
		_volume = lerpf(_volume, obiettivo, 0.00005)
		_fase_lfo += 1.0 / (FREQ * 7.5)
		if _fase_lfo > 1.0:
			_fase_lfo -= 1.0
		var respiro := 0.55 + 0.45 * sin(TAU * _fase_lfo)
		# Rumore marrone (integrazione del bianco) e passa-basso.
		_marrone = clampf(_marrone + (randf() * 2.0 - 1.0) * 0.02, -1.0, 1.0) * 0.998
		_filtro = lerpf(_filtro, _marrone, 0.08)
		var mare := _filtro * 0.9 * respiro
		_fase1 += 49.0 / FREQ
		_fase2 += (49.0 * (1.0 + 0.012 + risonanza * 0.02)) / FREQ
		_fase1 = fmod(_fase1, 1.0)
		_fase2 = fmod(_fase2, 1.0)
		var nota := sin(TAU * _fase1) * 0.10 * respiro
		var stonata := sin(TAU * _fase2) * 0.09 * risonanza
		var s := (mare + nota + stonata) * _volume
		_gen.push_frame(Vector2(s, s * 0.96))
