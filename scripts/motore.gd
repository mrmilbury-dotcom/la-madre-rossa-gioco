## Motore: le regole del gioco. Non disegna niente: riceve un'azione
## (entra, guarda, esamina, ascolta, vai, scegli) e restituisce una lista di
## "pezzi" di testo da mostrare. L'interfaccia (main.gd) li impagina.
##
## Ogni pezzo è un dizionario con "tipo":
##   "luogo"   -> nome della stanza/evento (intestazione)
##   "testo"   -> prosa normale
##   "ricordo" -> frammento di memoria (con "persona" e "titolo")
##   "nota"    -> riga di servizio (es. comando non capito)
##   "fine"    -> la partita è finita
class_name Motore
extends RefCounted

var storia: Storia
var stato: Stato
var _salto: String = ""


func _init(s: Storia, st: Stato = null) -> void:
	storia = s
	stato = st if st != null else Stato.new()
	stato.linea = s.id


# ---------------------------------------------------------------- avvio

func avvia() -> Array:
	var out: Array = []
	var intro: String = storia.meta.get("intro", "")
	if intro != "" and storia.eventi.has(intro):
		out.append_array(_apri_evento(intro))
	else:
		out.append_array(_entra(storia.meta.get("inizio", "")))
	_risolvi_salti(out)
	return out


## Testo da mostrare quando si riprende una partita salvata.
func riprendi() -> Array:
	var out: Array = []
	if stato.evento != "":
		out.append_array(_mostra_evento(stato.evento, false))
	else:
		out.append({"tipo": "luogo", "testo": _titolo_stanza(stato.stanza)})
		var d := _ultimo_valido(storia.stanze[stato.stanza]["descrizioni"])
		if not d.is_empty():
			out.append({"tipo": "testo", "testo": d["testo"]})
	return out


# ---------------------------------------------------------------- azioni

func guarda() -> Array:
	var out: Array = []
	if stato.evento != "":
		return out
	var d := _ultimo_valido(storia.stanze[stato.stanza]["descrizioni"])
	if not d.is_empty():
		out.append({"tipo": "testo", "testo": d["testo"]})
	return out


func esamina(oid: String) -> Array:
	var out: Array = []
	var st: Dictionary = storia.stanze.get(stato.stanza, {})
	if st.is_empty() or not st["oggetti"].has(oid):
		out.append({"tipo": "nota", "testo": String(storia.meta.get("non_vedo", "Non vedi niente del genere, qui."))})
		return out
	var b := _ultimo_valido(st["oggetti"][oid]["blocchi"])
	if b.is_empty():
		out.append({"tipo": "nota", "testo": String(storia.meta.get("non_vedo", "Non vedi niente del genere, qui."))})
		return out
	stato.esaminati[oid] = int(stato.esaminati.get(oid, 0)) + 1
	_mostra_blocco(b, out)
	_dopo_azione(out)
	return out


func ascolta() -> Array:
	var out: Array = []
	var st: Dictionary = storia.stanze.get(stato.stanza, {})
	if st.is_empty():
		return out
	var validi: Array = []
	for i in st["ascolta"].size():
		if valida(st["ascolta"][i]["cond"]):
			validi.append(i)
	var gia: Array = stato.ascolti.get(stato.stanza, [])
	var scelto := -1
	for i in validi:
		if not gia.has(i):
			scelto = i
			break
	if scelto >= 0:
		gia.append(scelto)
		stato.ascolti[stato.stanza] = gia
		_mostra_blocco(st["ascolta"][scelto], out)
	elif not validi.is_empty():
		# Tutto già ascoltato: si ripete l'ultimo, senza effetti.
		out.append({"tipo": "testo", "testo": st["ascolta"][validi[validi.size() - 1]]["testo"]})
	else:
		out.append({"tipo": "testo", "testo": String(storia.meta.get("silenzio", "Ascolti. Niente risponde."))})
	_dopo_azione(out)
	return out


func vai(direzione: String) -> Array:
	var out: Array = []
	var u := _uscita(direzione)
	if u.is_empty():
		out.append({"tipo": "nota", "testo": String(storia.meta.get("non_si_passa", "Da quella parte non si va."))})
		return out
	var target: String = u["target"]
	if u["testo"] != "":
		out.append({"tipo": "testo", "testo": u["testo"]})
	_esegui(u["effetti"], out)
	if target != "-" and _salto == "":
		_salto = target
	_risolvi_salti(out)
	_dopo_azione(out)
	return out


func scegli(indice: int) -> Array:
	var out: Array = []
	var scelte := scelte_valide()
	if indice < 0 or indice >= scelte.size():
		return out
	var sc: Dictionary = scelte[indice]
	if sc["testo"] != "":
		out.append({"tipo": "testo", "testo": sc["testo"]})
	_esegui(sc["effetti"], out)
	var target: String = sc["target"]
	if target != "" and target != "-" and _salto == "" and not stato.finito:
		_salto = target
	_risolvi_salti(out)
	return out


# ---------------------------------------------------------------- cosa si può fare

## Direzioni disponibili qui, nell'ordine in cui compaiono nel file.
func uscite_valide() -> Array:
	var out: Array = []
	if stato.evento != "" or stato.finito:
		return out
	for u in storia.stanze[stato.stanza]["uscite"]:
		var d: String = u["dir"]
		if not out.has(d) and not _uscita(d).is_empty():
			out.append(d)
	return out


## Oggetti visibili qui: [{id, nome}]
func oggetti_validi() -> Array:
	var out: Array = []
	if stato.evento != "" or stato.finito:
		return out
	var st: Dictionary = storia.stanze[stato.stanza]
	for oid in st["ordine_oggetti"]:
		var b := _ultimo_valido(st["oggetti"][oid]["blocchi"])
		if not b.is_empty():
			var nome: String = b.get("nome", oid)
			out.append({"id": oid, "nome": nome if nome != "" else oid})
	return out


func scelte_valide() -> Array:
	var out: Array = []
	if stato.evento == "" or stato.finito:
		return out
	for sc in storia.eventi[stato.evento]["scelte"]:
		if valida(sc["cond"]):
			out.append(sc)
	return out


func titolo_corrente() -> String:
	if stato.evento != "":
		return String(storia.eventi[stato.evento]["meta"].get("titolo", ""))
	return _titolo_stanza(stato.stanza)


func stile_corrente() -> String:
	if stato.evento != "":
		return String(storia.eventi[stato.evento]["meta"].get("stile", storia.meta.get("stile", "")))
	if storia.stanze.has(stato.stanza):
		return String(storia.stanze[stato.stanza]["meta"].get("stile", storia.meta.get("stile", "")))
	return ""


# ---------------------------------------------------------------- condizioni

func valida(cond: Array) -> bool:
	for c in cond:
		if _termine(c) == bool(c.get("neg", false)):
			return false
	return true


func _termine(c: Dictionary) -> bool:
	match c["t"]:
		"prima":
			return int(stato.visite.get(stato.stanza, 0)) <= 1
		"ritorno":
			return int(stato.visite.get(stato.stanza, 0)) > 1
		"visitato":
			return int(stato.visite.get(c["x"], 0)) > 0
		"esaminato":
			return int(stato.esaminati.get(c["x"], 0)) > 0
		"ricordo":
			return stato.ricordi.has(c["x"])
		"flag":
			return stato.flag.has(c["x"])
		"cmp":
			var v := stato.valore(c["var"])
			var n: int = c["val"]
			match c["op"]:
				">=": return v >= n
				"<=": return v <= n
				">": return v > n
				"<": return v < n
				"=": return v == n
				"!=": return v != n
	return false


func _ultimo_valido(blocchi: Array) -> Dictionary:
	var scelto: Dictionary = {}
	for b in blocchi:
		if valida(b["cond"]):
			scelto = b
	return scelto


func _uscita(direzione: String) -> Dictionary:
	var scelta: Dictionary = {}
	if not storia.stanze.has(stato.stanza):
		return scelta
	for u in storia.stanze[stato.stanza]["uscite"]:
		if u["dir"] == direzione and valida(u["cond"]):
			scelta = u
	return scelta


# ---------------------------------------------------------------- interno

func _titolo_stanza(sid: String) -> String:
	if not storia.stanze.has(sid):
		return ""
	return String(storia.stanze[sid]["meta"].get("titolo", sid))


func _entra(sid: String) -> Array:
	var out: Array = []
	if not storia.stanze.has(sid):
		out.append({"tipo": "nota", "testo": "[stanza mancante: %s]" % sid})
		return out
	stato.evento = ""
	stato.stanza = sid
	stato.visite[sid] = int(stato.visite.get(sid, 0)) + 1
	out.append({"tipo": "luogo", "testo": _titolo_stanza(sid), "nuova_pagina": true})
	var d := _ultimo_valido(storia.stanze[sid]["descrizioni"])
	if not d.is_empty():
		_mostra_blocco(d, out)
	return out


func _apri_evento(eid: String) -> Array:
	stato.evento = eid
	stato.visite["evento:" + eid] = int(stato.visite.get("evento:" + eid, 0)) + 1
	return _mostra_evento(eid, true)


func _mostra_evento(eid: String, con_effetti: bool) -> Array:
	var out: Array = []
	var ev: Dictionary = storia.eventi[eid]
	out.append({"tipo": "luogo", "testo": String(ev["meta"].get("titolo", "")), "nuova_pagina": true})
	for b in ev["testi"]:
		if valida(b["cond"]):
			if con_effetti:
				_mostra_blocco(b, out)
				if _salto != "" or stato.finito:
					break
			elif b["testo"] != "":
				out.append({"tipo": "testo", "testo": b["testo"]})
	return out


func _mostra_blocco(b: Dictionary, out: Array) -> void:
	if String(b.get("testo", "")) != "":
		out.append({"tipo": "testo", "testo": b["testo"]})
	_esegui(b["effetti"], out)


func _esegui(effetti: Array, out: Array) -> void:
	for e in effetti:
		match e["e"]:
			"risonanza":
				var prima := stato.risonanza
				stato.risonanza = maxi(0, (stato.risonanza + e["val"]) if e["rel"] else e["val"])
				if stato.risonanza != prima:
					out.append({"tipo": "risonanza", "valore": stato.risonanza})
			"segna":
				stato.flag[e["x"]] = true
			"togli":
				stato.flag.erase(e["x"])
			"ricordo":
				var rid: String = e["x"]
				if not stato.ricordi.has(rid) and storia.ricordi.has(rid):
					stato.ricordi.append(rid)
					var r: Dictionary = storia.ricordi[rid]
					out.append({
						"tipo": "ricordo",
						"persona": String(r["meta"].get("persona", "")),
						"titolo": String(r["meta"].get("titolo", "")),
						"testo": storia.testo_ricordo(rid),
					})
			"vai":
				_salto = e["x"]
			"pausa":
				out.append({"tipo": "pausa"})
			"fine":
				stato.finito = true
				stato.finale = e.get("x", "")
				out.append({"tipo": "fine", "finale": stato.finale})


func _risolvi_salti(out: Array) -> void:
	var giri := 0
	while _salto != "" and giri < 20 and not stato.finito:
		giri += 1
		var t := _salto
		_salto = ""
		if storia.stanze.has(t):
			out.append_array(_entra(t))
		elif storia.eventi.has(t):
			out.append_array(_apri_evento(t))
	_salto = ""


func _dopo_azione(out: Array) -> void:
	stato.azioni += 1
	if stato.finito or stato.tempo_scaduto or stato.evento != "":
		return
	var limite := int(storia.meta.get("limite_azioni", "0"))
	var t: String = storia.meta.get("tempo", "")
	if limite > 0 and stato.azioni >= limite and t != "":
		stato.tempo_scaduto = true
		_salto = t
		_risolvi_salti(out)
