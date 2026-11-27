## Interfaccia del gioco: titolo, pagina di gioco, ricordi, salvataggi.
## Tutta la grafica è costruita qui in codice (niente scene complicate da
## mantenere): sfondo animato, colonna di testo, pulsanti d'azione.
extends Control

const LINEE := {
	"baldr": {
		"cartella": "res://storia/baldr",
		"titolo": "La Piattaforma Baldr",
		"sottotitolo": "Mar di Norvegia. Sette settimane dopo. Qualcuno deve andare a riprendere le borse.",
	},
	"dee": {
		"cartella": "res://storia/dee",
		"titolo": "La RSS Arthur Dee",
		"sottotitolo": "Mare di Barents. Una tempesta che nessuno ha previsto. Di nuovo.",
	},
}

# Stili visivi richiamabili dai testi con "stile: nome".
const STILI := {
	"notte":    {"alto": Color(0.035, 0.05, 0.065), "basso": Color(0.01, 0.02, 0.03), "nebbia": 0.45},
	"nebbia":   {"alto": Color(0.07, 0.085, 0.095), "basso": Color(0.025, 0.035, 0.045), "nebbia": 0.9},
	"interno":  {"alto": Color(0.06, 0.05, 0.045), "basso": Color(0.02, 0.018, 0.016), "nebbia": 0.25},
	"ruggine":  {"alto": Color(0.08, 0.045, 0.035), "basso": Color(0.025, 0.012, 0.01), "nebbia": 0.35},
	"luce":     {"alto": Color(0.03, 0.06, 0.07), "basso": Color(0.01, 0.025, 0.03), "nebbia": 0.3},
	"abisso":   {"alto": Color(0.012, 0.018, 0.03), "basso": Color(0.0, 0.004, 0.01), "nebbia": 0.15},
	"madre":    {"alto": Color(0.09, 0.025, 0.02), "basso": Color(0.03, 0.005, 0.005), "nebbia": 0.55},
	"alba":     {"alto": Color(0.13, 0.08, 0.07), "basso": Color(0.03, 0.03, 0.04), "nebbia": 0.6},
}

const COL_TESTO := Color("d9d3c7")
const COL_TENUE := Color("8b9298")
const COL_VOCE := Color("d0705a")
const COL_RICORDO := Color("c9a58a")
const COL_ACCENTO := Color("b4412f")
const RISONANZA_MAX := 14.0

var font_serif: Font
var font_corsivo: Font
var font_mono: Font

var sfondo: ColorRect
var materiale: ShaderMaterial
var suono: AudioStreamPlayer

var schermo_titolo: Control
var schermo_gioco: Control
var colonna: VBoxContainer
var etichetta_luogo: Label
var pulsante_ricordi: Button
var testo: RichTextLabel
var riquadro_azioni: VBoxContainer
var campo_comando: LineEdit
var velo_ricordi: Control
var testo_ricordi: RichTextLabel

var storia: Storia
var motore: Motore
var linea_id := ""

var _visibili := 0.0
var _velocita := 80.0          # caratteri al secondo (0 = istantaneo)
var _rosso_obiettivo := 0.0
var _rosso := 0.0
var _stile_obiettivo := "notte"
var _col_alto := Color(0.035, 0.05, 0.065)
var _col_basso := Color(0.01, 0.02, 0.03)
var _nebbia := 0.45
var _impostazioni := {"suono": true, "velocita": 1, "effetti": 1}


func _ready() -> void:
	_carica_font()
	_carica_impostazioni()
	_costruisci_sfondo()
	_costruisci_titolo()
	_costruisci_gioco()
	_costruisci_velo_ricordi()
	suono = preload("res://scripts/suono.gd").new()
	add_child(suono)
	suono.attivo = _impostazioni["suono"]
	get_window().size_changed.connect(_adatta_scala)
	_adatta_scala()
	_mostra_titolo()


func _process(delta: float) -> void:
	# Macchina da scrivere.
	var totale := testo.get_total_character_count()
	if testo.visible_characters >= 0 and testo.visible_characters < totale:
		if _velocita <= 0.0:
			testo.visible_characters = -1
		else:
			_visibili += delta * _velocita * (1.0 + (totale - testo.visible_characters) / 900.0)
			testo.visible_characters = mini(int(_visibili), totale)
			if testo.visible_characters >= totale:
				testo.visible_characters = -1
	# Sfondo: avvicinamento morbido ai valori obiettivo.
	var s: Dictionary = STILI.get(_stile_obiettivo, STILI["notte"])
	_col_alto = _col_alto.lerp(s["alto"], delta * 0.6)
	_col_basso = _col_basso.lerp(s["basso"], delta * 0.6)
	_nebbia = lerpf(_nebbia, s["nebbia"], delta * 0.6)
	_rosso = lerpf(_rosso, _rosso_obiettivo, delta * 0.35)
	materiale.set_shader_parameter("col_alto", _col_alto)
	materiale.set_shader_parameter("col_basso", _col_basso)
	materiale.set_shader_parameter("nebbia", _nebbia)
	materiale.set_shader_parameter("rosso", _rosso)
	materiale.set_shader_parameter("battito", clampf(_rosso * 1.2 - 0.2, 0.0, 1.0))
	if suono:
		suono.risonanza = _rosso


# ================================================================ costruzione

func _carica_font() -> void:
	font_serif = _font_con_riserva("cormorant-garamond-latin-500-normal", "cormorant-garamond-latin-ext-500-normal")
	font_corsivo = _font_con_riserva("cormorant-garamond-latin-400-italic", "cormorant-garamond-latin-ext-400-italic")
	font_mono = _font_con_riserva("ibm-plex-mono-latin-400-normal", "ibm-plex-mono-latin-ext-400-normal")


func _font_con_riserva(principale: String, riserva: String) -> Font:
	var f: FontFile = load("res://assets/font/%s.woff2" % principale)
	var r: FontFile = load("res://assets/font/%s.woff2" % riserva)
	if f == null:
		return ThemeDB.fallback_font
	if r != null:
		f.fallbacks = [r]
	return f


func _costruisci_sfondo() -> void:
	sfondo = ColorRect.new()
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	materiale = ShaderMaterial.new()
	materiale.shader = load("res://shaders/sfondo.gdshader")
	sfondo.material = materiale
	add_child(sfondo)

	var t := Theme.new()
	t.default_font = font_serif
	t.default_font_size = 22
	t.set_color("font_color", "Label", COL_TESTO)
	t.set_color("default_color", "RichTextLabel", COL_TESTO)
	t.set_font("normal_font", "RichTextLabel", font_serif)
	t.set_font("italics_font", "RichTextLabel", font_corsivo)
	t.set_font("mono_font", "RichTextLabel", font_mono)
	t.set_font_size("normal_font_size", "RichTextLabel", 23)
	t.set_font_size("italics_font_size", "RichTextLabel", 23)
	t.set_font_size("mono_font_size", "RichTextLabel", 14)
	t.set_constant("line_separation", "RichTextLabel", 4)
	for stato_p in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.07, 0.08, 0.55) if stato_p == "normal" else Color(0.2, 0.07, 0.05, 0.7)
		if stato_p == "focus":
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = COL_ACCENTO
			sb.set_border_width_all(1)
		elif stato_p == "disabled":
			sb.bg_color = Color(0.05, 0.05, 0.05, 0.3)
		else:
			sb.border_color = Color(COL_TESTO, 0.18) if stato_p == "normal" else COL_ACCENTO
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 7
		sb.content_margin_bottom = 7
		t.set_stylebox(stato_p, "Button", sb)
	t.set_font("font", "Button", font_mono)
	t.set_font_size("font_size", "Button", 15)
	t.set_color("font_color", "Button", COL_TESTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", COL_TESTO)
	var le := StyleBoxFlat.new()
	le.bg_color = Color(0, 0, 0, 0.35)
	le.border_color = Color(COL_TESTO, 0.2)
	le.border_width_bottom = 1
	le.content_margin_left = 10
	le.content_margin_right = 10
	le.content_margin_top = 6
	le.content_margin_bottom = 6
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = COL_ACCENTO
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_font("font", "LineEdit", font_mono)
	t.set_font_size("font_size", "LineEdit", 15)
	t.set_color("font_color", "LineEdit", COL_TESTO)
	t.set_color("font_placeholder_color", "LineEdit", Color(COL_TENUE, 0.7))
	t.set_color("caret_color", "LineEdit", COL_ACCENTO)
	var pan := StyleBoxFlat.new()
	pan.bg_color = Color(0.02, 0.025, 0.03, 0.94)
	pan.border_color = Color(COL_ACCENTO, 0.6)
	pan.set_border_width_all(1)
	pan.content_margin_left = 22
	pan.content_margin_right = 22
	pan.content_margin_top = 18
	pan.content_margin_bottom = 18
	t.set_stylebox("panel", "PanelContainer", pan)
	var sep := StyleBoxLine.new()
	sep.color = Color(COL_TESTO, 0.12)
	t.set_stylebox("separator", "HSeparator", sep)
	theme = t


func _costruisci_titolo() -> void:
	schermo_titolo = MarginContainer.new()
	schermo_titolo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(schermo_titolo)
	var centro := CenterContainer.new()
	schermo_titolo.add_child(centro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(560, 0)
	v.name = "ColonnaTitolo"
	centro.add_child(v)

	var t := Label.new()
	t.text = "E M I S S A R I"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", font_mono)
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", COL_VOCE)
	v.add_child(t)
	var st := Label.new()
	st.text = "un'esplorazione da «La madre rossa» di Maico Morellini"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_override("font", font_corsivo)
	st.add_theme_font_size_override("font_size", 22)
	st.add_theme_color_override("font_color", COL_TENUE)
	v.add_child(st)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 18)
	v.add_child(sp)
	var dove := Label.new()
	dove.text = "Scegli dove salire a bordo."
	dove.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dove.add_theme_font_size_override("font_size", 21)
	v.add_child(dove)
	var scatola := VBoxContainer.new()
	scatola.name = "Linee"
	scatola.add_theme_constant_override("separation", 12)
	v.add_child(scatola)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 10)
	v.add_child(sp2)
	var opzioni := HFlowContainer.new()
	opzioni.name = "Opzioni"
	opzioni.alignment = FlowContainer.ALIGNMENT_CENTER
	opzioni.add_theme_constant_override("h_separation", 8)
	opzioni.add_theme_constant_override("v_separation", 8)
	v.add_child(opzioni)
	var crediti := Label.new()
	crediti.text = "Testi tratti dall'universo di «La madre rossa» (Agenzia Alcatraz, 2026) · rssarthurdee.it"
	crediti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crediti.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crediti.add_theme_font_override("font", font_mono)
	crediti.add_theme_font_size_override("font_size", 12)
	crediti.add_theme_color_override("font_color", Color(COL_TENUE, 0.7))
	v.add_child(crediti)


func _costruisci_gioco() -> void:
	schermo_gioco = MarginContainer.new()
	schermo_gioco.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo_gioco.visible = false
	add_child(schermo_gioco)
	var h := HBoxContainer.new()
	schermo_gioco.add_child(h)
	var sx := Control.new()
	sx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sx)
	colonna = VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 10)
	colonna.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Un velo scuro dietro il testo: lo sfondo resta visibile ai lati,
	# ma le venature non disturbano la lettura.
	var velo := PanelContainer.new()
	var sb_velo := StyleBoxFlat.new()
	sb_velo.bg_color = Color(0.012, 0.016, 0.02, 0.74)
	sb_velo.set_corner_radius_all(3)
	sb_velo.content_margin_left = 18
	sb_velo.content_margin_right = 18
	sb_velo.content_margin_top = 12
	sb_velo.content_margin_bottom = 12
	velo.add_theme_stylebox_override("panel", sb_velo)
	velo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(velo)
	velo.add_child(colonna)
	var dx := Control.new()
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)

	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)
	colonna.add_child(barra)
	etichetta_luogo = Label.new()
	etichetta_luogo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etichetta_luogo.add_theme_font_override("font", font_mono)
	etichetta_luogo.add_theme_font_size_override("font_size", 14)
	etichetta_luogo.add_theme_color_override("font_color", COL_VOCE)
	etichetta_luogo.clip_text = true
	barra.add_child(etichetta_luogo)
	pulsante_ricordi = Button.new()
	pulsante_ricordi.text = "Ricordi"
	pulsante_ricordi.pressed.connect(_apri_ricordi)
	barra.add_child(pulsante_ricordi)
	var menu := Button.new()
	menu.text = "Menu"
	menu.pressed.connect(_torna_al_titolo)
	barra.add_child(menu)

	var linea_sopra := HSeparator.new()
	colonna.add_child(linea_sopra)

	testo = RichTextLabel.new()
	testo.bbcode_enabled = true
	testo.scroll_following = true
	testo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	testo.selection_enabled = false
	testo.mouse_filter = Control.MOUSE_FILTER_STOP
	testo.gui_input.connect(_su_clic_testo)
	colonna.add_child(testo)

	colonna.add_child(HSeparator.new())
	riquadro_azioni = VBoxContainer.new()
	riquadro_azioni.add_theme_constant_override("separation", 8)
	colonna.add_child(riquadro_azioni)

	var riga_cmd := HBoxContainer.new()
	riga_cmd.name = "RigaComando"
	colonna.add_child(riga_cmd)
	var prompt := Label.new()
	prompt.text = ">"
	prompt.add_theme_font_override("font", font_mono)
	prompt.add_theme_color_override("font_color", COL_VOCE)
	riga_cmd.add_child(prompt)
	campo_comando = LineEdit.new()
	campo_comando.placeholder_text = "scrivi un comando (oppure: aiuto)"
	campo_comando.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_comando.text_submitted.connect(_su_comando)
	campo_comando.keep_editing_on_text_submit = true
	riga_cmd.add_child(campo_comando)


func _costruisci_velo_ricordi() -> void:
	velo_ricordi = ColorRect.new()
	(velo_ricordi as ColorRect).color = Color(0, 0, 0, 0.6)
	velo_ricordi.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo_ricordi.visible = false
	add_child(velo_ricordi)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 28)
	velo_ricordi.add_child(m)
	var p := PanelContainer.new()
	m.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	testo_ricordi = RichTextLabel.new()
	testo_ricordi.bbcode_enabled = true
	testo_ricordi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(testo_ricordi)
	var chiudi := Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(func(): velo_ricordi.visible = false)
	v.add_child(chiudi)


# ================================================================ scala

func _adatta_scala() -> void:
	var w := get_window()
	var fisico := Vector2(w.size)
	if fisico.x <= 0 or fisico.y <= 0:
		return
	var dpi := DisplayServer.screen_get_scale()
	if dpi <= 0.0:
		dpi = 1.0
	# Larghezza "logica" di riferimento: 640 px. Su telefono si ingrandisce,
	# su schermi grandi si limita perché il testo resti una colonna leggibile.
	var logico := fisico / dpi
	var f := clampf(minf(logico.x / 500.0, logico.y / 700.0), 0.78, 1.45) * dpi
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	w.content_scale_size = Vector2i(fisico / f)
	w.content_scale_factor = 1.0
	var area := Vector2(fisico / f)
	materiale.set_shader_parameter("risoluzione", area)
	var larghezza := minf(760.0, area.x - 32.0 - 36.0)
	colonna.custom_minimum_size = Vector2(larghezza, 0)
	var margine := 16 if area.x < 700 else 28
	for c in [schermo_gioco, schermo_titolo]:
		c.add_theme_constant_override("margin_top", margine)
		c.add_theme_constant_override("margin_bottom", margine)
		c.add_theme_constant_override("margin_left", 16)
		c.add_theme_constant_override("margin_right", 16)
	var ct := schermo_titolo.find_child("ColonnaTitolo", true, false) as Control
	if ct:
		ct.custom_minimum_size = Vector2(minf(560.0, area.x - 32.0), 0)


# ================================================================ titolo

func _mostra_titolo() -> void:
	schermo_gioco.visible = false
	schermo_titolo.visible = true
	_stile_obiettivo = "notte"
	_rosso_obiettivo = 0.08
	var scatola := schermo_titolo.find_child("Linee", true, false) as VBoxContainer
	for c in scatola.get_children():
		c.queue_free()
	for lid in LINEE:
		var info: Dictionary = LINEE[lid]
		var b := Button.new()
		b.text = "%s\n%s" % [info["titolo"].to_upper(), info["sottotitolo"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_override("font", font_serif)
		b.add_theme_font_size_override("font_size", 21)
		b.custom_minimum_size = Vector2(0, 84)
		b.pressed.connect(_nuova_partita.bind(lid))
		scatola.add_child(b)
		if FileAccess.file_exists(_percorso_salvataggio(lid)):
			var c := Button.new()
			c.text = "↳ riprendi la partita interrotta"
			c.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			c.pressed.connect(_riprendi_partita.bind(lid))
			scatola.add_child(c)
	_aggiorna_opzioni()


func _aggiorna_opzioni() -> void:
	var o := schermo_titolo.find_child("Opzioni", true, false) as HFlowContainer
	for c in o.get_children():
		c.queue_free()
	var b1 := Button.new()
	b1.text = "Suono: %s" % ("sì" if _impostazioni["suono"] else "no")
	b1.pressed.connect(func():
		_impostazioni["suono"] = not _impostazioni["suono"]
		suono.attivo = _impostazioni["suono"]
		_salva_impostazioni()
		_aggiorna_opzioni())
	o.add_child(b1)
	var nomi_vel := ["lento", "normale", "rapido", "istantaneo"]
	var b2 := Button.new()
	b2.text = "Testo: %s" % nomi_vel[_impostazioni["velocita"]]
	b2.pressed.connect(func():
		_impostazioni["velocita"] = (int(_impostazioni["velocita"]) + 1) % 4
		_applica_velocita()
		_salva_impostazioni()
		_aggiorna_opzioni())
	o.add_child(b2)
	var b3 := Button.new()
	b3.text = "Effetti: %s" % ("pieni" if _impostazioni["effetti"] == 1 else "ridotti")
	b3.pressed.connect(func():
		_impostazioni["effetti"] = 1 - int(_impostazioni["effetti"])
		materiale.set_shader_parameter("qualita", float(_impostazioni["effetti"]))
		_salva_impostazioni()
		_aggiorna_opzioni())
	o.add_child(b3)


func _applica_velocita() -> void:
	_velocita = [45.0, 80.0, 160.0, 0.0][int(_impostazioni["velocita"])]


# ================================================================ partita

func _prepara_linea(lid: String) -> bool:
	linea_id = lid
	storia = Storia.carica(LINEE[lid]["cartella"])
	if not storia.errori.is_empty():
		schermo_titolo.visible = false
		schermo_gioco.visible = true
		testo.clear()
		testo.append_text("[color=#%s]I testi di questa linea contengono errori:[/color]\n\n" % COL_VOCE.to_html(false))
		for e in storia.errori:
			testo.append_text("• %s\n" % _sicuro(e))
		testo.visible_characters = -1
		_svuota_azioni()
		_aggiungi_pulsante(riquadro_azioni, "Torna al titolo", _torna_al_titolo)
		return false
	return true


func _nuova_partita(lid: String) -> void:
	suono.avvia()
	if not _prepara_linea(lid):
		return
	motore = Motore.new(storia)
	_entra_in_gioco()
	_mostra(motore.avvia())


func _riprendi_partita(lid: String) -> void:
	suono.avvia()
	if not _prepara_linea(lid):
		return
	var fa := FileAccess.open(_percorso_salvataggio(lid), FileAccess.READ)
	var dati = JSON.parse_string(fa.get_as_text()) if fa else null
	if typeof(dati) != TYPE_DICTIONARY:
		_nuova_partita(lid)
		return
	var st := Stato.da_dizionario(dati)
	if st.evento != "" and not storia.eventi.has(st.evento) or st.evento == "" and not storia.stanze.has(st.stanza):
		_nuova_partita(lid)
		return
	motore = Motore.new(storia, st)
	_entra_in_gioco()
	_rosso_obiettivo = clampf(st.risonanza / RISONANZA_MAX, 0.0, 1.0)
	_mostra(motore.riprendi())


func _entra_in_gioco() -> void:
	schermo_titolo.visible = false
	schermo_gioco.visible = true
	_rosso_obiettivo = 0.0
	testo.clear()
	_visibili = 0
	_applica_velocita()
	materiale.set_shader_parameter("qualita", float(_impostazioni["effetti"]))


func _torna_al_titolo() -> void:
	velo_ricordi.visible = false
	_mostra_titolo()


func _mostra(pezzi: Array) -> void:
	for p in pezzi:
		match p["tipo"]:
			"luogo":
				if p.get("nuova_pagina", false):
					testo.clear()
					_visibili = 0
					testo.visible_characters = 0
				etichetta_luogo.text = String(p["testo"]).to_upper()
			"testo":
				_aggiungi_bb(_formatta(p["testo"]) + "\n\n")
			"nota":
				_aggiungi_bb("[color=#%s][i]%s[/i][/color]\n\n" % [COL_TENUE.to_html(false), _formatta(p["testo"])])
			"ricordo":
				var chi := String(p.get("persona", "")).to_upper()
				var intest := "· %s ·" % chi if chi != "" else "· · ·"
				_aggiungi_bb("[center][font_size=13][color=#%s][code]%s[/code][/color][/font_size][/center]\n" % [COL_VOCE.to_html(false), _sicuro(intest)])
				_aggiungi_bb("[indent][color=#%s][i]%s[/i][/color][/indent]\n\n" % [COL_RICORDO.to_html(false), _formatta(p["testo"], true)])
			"risonanza":
				_rosso_obiettivo = clampf(float(p["valore"]) / RISONANZA_MAX, 0.0, 1.0)
			"fine":
				_aggiungi_bb("[center][color=#%s][code]— FINE —[/code][/color][/center]\n" % COL_VOCE.to_html(false))
	if motore:
		_stile_obiettivo = motore.stile_corrente() if motore.stile_corrente() != "" else _stile_obiettivo
		if motore.stato.evento == "" and etichetta_luogo.text == "":
			etichetta_luogo.text = motore.titolo_corrente().to_upper()
		if motore.stato.finito:
			DirAccess.remove_absolute(_percorso_salvataggio(linea_id))
		else:
			_salva_partita()
	_ricostruisci_azioni()


func _aggiungi_bb(bb: String) -> void:
	if testo.visible_characters < 0:
		testo.visible_characters = testo.get_total_character_count()
		_visibili = testo.visible_characters
	testo.append_text(bb)


## Converte il testo scritto dall'autore in BBCode per RichTextLabel.
##   *corsivo*   **grassetto**   riga che inizia con ~  -> voce della nave
func _formatta(s: String, dentro_corsivo := false) -> String:
	var righe := s.split("\n")
	var out: PackedStringArray = []
	for r in righe:
		var riga := _sicuro(r)
		if riga.strip_edges().begins_with("~"):
			var v := riga.strip_edges().substr(1).strip_edges()
			v = _enfasi(v)
			out.append("[color=#%s][i]%s[/i][/color]" % [COL_VOCE.to_html(false), v] if not dentro_corsivo else "[/i][color=#%s]%s[/color][i]" % [COL_VOCE.to_html(false), v])
		else:
			out.append(_enfasi(riga))
	return "\n".join(out)


func _enfasi(s: String) -> String:
	var r := s
	r = _sostituisci_coppie(r, "**", "[b]", "[/b]")
	r = _sostituisci_coppie(r, "*", "[i]", "[/i]")
	return r


func _sostituisci_coppie(s: String, segno: String, apri: String, chiudi: String) -> String:
	var parti := s.split(segno)
	if parti.size() < 3:
		return s
	var out := ""
	for i in parti.size():
		out += parti[i]
		if i < parti.size() - 1:
			# Un segno rimasto spaiato alla fine viene lasciato com'è.
			if i % 2 == 0 and i == parti.size() - 2 and parti.size() % 2 == 0:
				out += segno
			else:
				out += apri if i % 2 == 0 else chiudi
	return out


func _sicuro(s: String) -> String:
	# Le parentesi quadre sono comandi per RichTextLabel: le rendiamo innocue.
	return s.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")


# ================================================================ azioni

func _svuota_azioni() -> void:
	for c in riquadro_azioni.get_children():
		riquadro_azioni.remove_child(c)
		c.queue_free()


func _ricostruisci_azioni() -> void:
	_svuota_azioni()
	pulsante_ricordi.text = "Ricordi (%d)" % motore.stato.ricordi.size()
	var riga_cmd := colonna.get_node("RigaComando") as Control
	if motore.stato.finito:
		riga_cmd.visible = false
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 8)
		f.add_theme_constant_override("v_separation", 8)
		riquadro_azioni.add_child(f)
		_aggiungi_pulsante(f, "Torna al titolo", _torna_al_titolo)
		var altra := "dee" if linea_id == "baldr" else "baldr"
		_aggiungi_pulsante(f, "Sali a bordo dell'altra: %s" % LINEE[altra]["titolo"], _nuova_partita.bind(altra))
		_aggiungi_pulsante(f, "Rileggi i ricordi", _apri_ricordi)
		return
	riga_cmd.visible = true

	var scelte := motore.scelte_valide()
	if motore.stato.evento != "":
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		riquadro_azioni.add_child(v)
		for i in scelte.size():
			var b := _aggiungi_pulsante(v, String(scelte[i]["etichetta"]), _azione.bind("scegli", i))
			b.add_theme_font_override("font", font_serif)
			b.add_theme_font_size_override("font_size", 21)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return

	var base := HFlowContainer.new()
	base.add_theme_constant_override("h_separation", 8)
	base.add_theme_constant_override("v_separation", 8)
	riquadro_azioni.add_child(base)
	_aggiungi_pulsante(base, "Guarda", _azione.bind("guarda", ""))
	_aggiungi_pulsante(base, "Ascolta", _azione.bind("ascolta", ""))

	var ogg := motore.oggetti_validi()
	if not ogg.is_empty():
		var r := _riga_con_etichetta("ESAMINA")
		for o in ogg:
			var b := _aggiungi_pulsante(r, String(o["nome"]), _azione.bind("esamina", o["id"]))
			b.add_theme_font_override("font", font_serif)
			b.add_theme_font_size_override("font_size", 19)
	var usc := motore.uscite_valide()
	if not usc.is_empty():
		var r2 := _riga_con_etichetta("VAI")
		for d in usc:
			_aggiungi_pulsante(r2, String(d).capitalize() if d != "giù" else "Giù", _azione.bind("vai", d))


func _riga_con_etichetta(nome: String) -> HFlowContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	riquadro_azioni.add_child(h)
	var l := Label.new()
	l.text = nome
	l.custom_minimum_size = Vector2(78, 0)
	l.add_theme_font_override("font", font_mono)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", COL_TENUE)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var f := HFlowContainer.new()
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f.add_theme_constant_override("h_separation", 8)
	f.add_theme_constant_override("v_separation", 8)
	h.add_child(f)
	return f


func _aggiungi_pulsante(dove: Control, etichetta: String, azione: Callable) -> Button:
	var b := Button.new()
	b.text = etichetta
	b.pressed.connect(azione)
	dove.add_child(b)
	return b


func _azione(tipo: String, arg) -> void:
	# Un clic durante la scrittura completa prima il testo.
	if testo.visible_characters >= 0 and testo.visible_characters < testo.get_total_character_count():
		testo.visible_characters = -1
	match tipo:
		"guarda":
			_mostra([{"tipo": "nota", "testo": "Guardi di nuovo."}] + motore.guarda())
		"ascolta":
			_mostra(motore.ascolta())
		"esamina":
			_mostra(motore.esamina(arg))
		"vai":
			_mostra(motore.vai(arg))
		"scegli":
			_mostra(motore.scegli(arg))


func _su_comando(frase: String) -> void:
	campo_comando.clear()
	if motore == null or motore.stato.finito:
		return
	var c := Comandi.interpreta(frase, motore)
	if c["azione"] != "nulla":
		_aggiungi_bb("[color=#%s][code]> %s[/code][/color]\n\n" % [COL_TENUE.to_html(false), _sicuro(frase)])
	match c["azione"]:
		"nulla":
			pass
		"aiuto":
			_mostra([{"tipo": "nota", "testo": "Puoi usare i pulsanti oppure scrivere: guarda · ascolta · esamina (qualcosa) · una direzione (nord, giù, prua, poppa…) · ricordi. Nelle scelte puoi scrivere il numero."}])
		"ricordi":
			_apri_ricordi()
		"ignoto":
			_mostra([{"tipo": "nota", "testo": String(storia.meta.get("non_capisco", "Non capisci cosa intendi. (Scrivi «aiuto».)"))}])
		"guarda", "ascolta":
			_azione(c["azione"], "")
		_:
			_azione(c["azione"], c.get("arg", ""))
	campo_comando.grab_focus()


func _su_clic_testo(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		testo.visible_characters = -1
	elif ev is InputEventScreenTouch and ev.pressed:
		testo.visible_characters = -1


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_SPACE and schermo_gioco.visible and not campo_comando.has_focus():
			testo.visible_characters = -1


func _apri_ricordi() -> void:
	testo_ricordi.clear()
	testo_ricordi.append_text("[center][color=#%s][code]RICORDI[/code][/color][/center]\n\n" % COL_VOCE.to_html(false))
	if motore == null or motore.stato.ricordi.is_empty():
		testo_ricordi.append_text("[i]Ancora niente. Ma qualcosa, qui, ricorda per te.[/i]")
	else:
		for rid in motore.stato.ricordi:
			var r: Dictionary = storia.ricordi[rid]
			var chi := String(r["meta"].get("persona", "")).to_upper()
			var tit := String(r["meta"].get("titolo", ""))
			testo_ricordi.append_text("[color=#%s][code]%s[/code][/color]  [i]%s[/i]\n" % [COL_VOCE.to_html(false), _sicuro(chi), _sicuro(tit)])
			testo_ricordi.append_text("[color=#%s]%s[/color]\n\n" % [COL_RICORDO.to_html(false), _formatta(storia.testo_ricordo(rid))])
	velo_ricordi.visible = true


# ================================================================ salvataggi

func _percorso_salvataggio(lid: String) -> String:
	return "user://partita_%s.json" % lid


func _salva_partita() -> void:
	var fa := FileAccess.open(_percorso_salvataggio(linea_id), FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(motore.stato.a_dizionario()))
		fa.close()


func _carica_impostazioni() -> void:
	if FileAccess.file_exists("user://impostazioni.json"):
		var fa := FileAccess.open("user://impostazioni.json", FileAccess.READ)
		var d = JSON.parse_string(fa.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			for k in d:
				_impostazioni[k] = d[k]
	_impostazioni["velocita"] = int(_impostazioni["velocita"])
	_impostazioni["effetti"] = int(_impostazioni["effetti"])
	_impostazioni["suono"] = bool(_impostazioni["suono"])
	_applica_velocita()


func _salva_impostazioni() -> void:
	var fa := FileAccess.open("user://impostazioni.json", FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(_impostazioni))
