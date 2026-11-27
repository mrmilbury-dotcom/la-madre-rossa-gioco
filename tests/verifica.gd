## Verifica automatica dei testi. Si lancia così (senza aprire l'editor):
##   godot --headless --script res://tests/verifica.gd
## 1. controlla errori di formato in tutte le linee;
## 2. gioca centinaia di partite a caso e segnala stanze, ricordi o finali
##    che non si raggiungono mai, e situazioni in cui il giocatore resta bloccato;
## 3. stima parole e tempo di lettura.
extends SceneTree

const LINEE := ["res://storia/baldr", "res://storia/dee"]
const PARTITE := 500
const PASSI_MAX := 400


func _initialize() -> void:
	var errori_totali := 0
	for cartella in LINEE:
		errori_totali += _verifica_linea(cartella)
	print("")
	print("ESITO: %s" % ("OK" if errori_totali == 0 else "%d PROBLEMI" % errori_totali))
	quit(0 if errori_totali == 0 else 1)


func _verifica_linea(cartella: String) -> int:
	var s := Storia.carica(cartella)
	print("\n=== %s  (%s) ===" % [cartella, s.meta.get("titolo", "?")])
	print("stanze %d · eventi %d · ricordi %d" % [s.stanze.size(), s.eventi.size(), s.ricordi.size()])
	for a in s.avvisi:
		print("  avviso: ", a)
	for e in s.errori:
		print("  ERRORE: ", e)
	if not s.errori.is_empty():
		return s.errori.size()

	var problemi := 0
	var stanze_viste := {}
	var ricordi_visti := {}
	var finali := {}
	var eventi_visti := {}
	var oggetti_visti := {}
	var bloccate := 0
	var lunghezze: Array = []
	var parole_lette_tot := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1942

	for n in PARTITE:
		var m := Motore.new(s)
		var parole_lette := _conta(m.avvia())
		var passi := 0
		# Stili di gioco diversi: chi corre, chi si ferma ad ascoltare.
		var pigrizia := rng.randf()
		while not m.stato.finito and passi < PASSI_MAX:
			passi += 1
			if m.stato.evento != "":
				eventi_visti[m.stato.evento] = true
				var sc := m.scelte_valide()
				if sc.is_empty():
					bloccate += 1
					if bloccate <= 3:
						print("  BLOCCO: evento '%s' senza scelte valide" % m.stato.evento)
					break
				parole_lette += _conta(m.scegli(rng.randi_range(0, sc.size() - 1)))
				continue
			stanze_viste[m.stato.stanza] = true
			var usc := m.uscite_valide()
			var ogg := m.oggetti_validi()
			var r := rng.randf()
			if usc.is_empty() and ogg.is_empty() and s.stanze[m.stato.stanza]["ascolta"].is_empty():
				bloccate += 1
				if bloccate <= 3:
					print("  BLOCCO: stanza '%s' senza uscite né azioni" % m.stato.stanza)
				break
			if r < 0.35 * (1.0 - pigrizia * 0.6) and not usc.is_empty():
				parole_lette += _conta(m.vai(usc[rng.randi_range(0, usc.size() - 1)]))
			elif r < 0.75 and not ogg.is_empty():
				var o: Dictionary = ogg[rng.randi_range(0, ogg.size() - 1)]
				oggetti_visti[o["id"]] = true
				parole_lette += _conta(m.esamina(o["id"]))
			elif not usc.is_empty() and r < 0.85:
				parole_lette += _conta(m.vai(usc[rng.randi_range(0, usc.size() - 1)]))
			else:
				parole_lette += _conta(m.ascolta())
		for rid in m.stato.ricordi:
			ricordi_visti[rid] = true
		for k in m.stato.visite:
			if String(k).begins_with("evento:"):
				eventi_visti[String(k).substr(7)] = true
		if m.stato.finito:
			finali[m.stato.finale] = int(finali.get(m.stato.finale, 0)) + 1
			lunghezze.append(m.stato.azioni)
			parole_lette_tot += parole_lette
		elif passi >= PASSI_MAX:
			problemi += 1
			if problemi <= 3:
				print("  ATTENZIONE: partita senza fine dopo %d passi (stanza %s, risonanza %d)" % [passi, m.stato.stanza, m.stato.risonanza])

	for sid in s.stanze:
		if not stanze_viste.has(sid):
			print("  ATTENZIONE: stanza mai raggiunta: ", sid)
			problemi += 1
	for eid in s.eventi:
		if not eventi_visti.has(eid):
			print("  avviso: evento mai visto in %d partite: %s" % [PARTITE, eid])
	for rid in s.ricordi:
		if not ricordi_visti.has(rid):
			print("  ATTENZIONE: ricordo mai trovato: ", rid)
			problemi += 1
	problemi += bloccate
	print("finali raggiunti: ", finali)
	if not lunghezze.is_empty():
		lunghezze.sort()
		print("azioni per partita: min %d · mediana %d · max %d" % [lunghezze[0], lunghezze[lunghezze.size() / 2], lunghezze[lunghezze.size() - 1]])
		var medie: int = parole_lette_tot / maxi(1, lunghezze.size())
		print("parole lette in media in una partita: %d (circa %d minuti a 180 parole/min, più il tempo per decidere)" % [medie, medie / 180])
	var totale := _parole_totali(s)
	print("parole scritte in tutta la linea: %d" % totale)
	return problemi


func _conta(pezzi: Array) -> int:
	var n := 0
	for p in pezzi:
		if p.has("testo"):
			n += String(p["testo"]).split(" ", false).size()
	return n


func _parole_totali(s: Storia) -> int:
	var n := 0
	for sid in s.stanze:
		var st: Dictionary = s.stanze[sid]
		for b in st["descrizioni"] + st["uscite"] + st["ascolta"]:
			n += String(b["testo"]).split(" ", false).size()
		for oid in st["oggetti"]:
			for b in st["oggetti"][oid]["blocchi"]:
				n += String(b["testo"]).split(" ", false).size()
	for eid in s.eventi:
		for b in s.eventi[eid]["testi"] + s.eventi[eid]["scelte"]:
			n += String(b["testo"]).split(" ", false).size()
	for rid in s.ricordi:
		n += s.testo_ricordo(rid).split(" ", false).size()
	return n
