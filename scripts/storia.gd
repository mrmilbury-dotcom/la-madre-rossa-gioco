## Storia: legge i file di testo di una linea di gioco (una cartella dentro
## res://storia/) e li trasforma in dati che il Motore sa usare.
##
## Il formato è descritto per intero in GUIDA_AI_TESTI.md. In breve:
##   # LINEA / # STANZA / # EVENTO / # RICORDO   -> apre un'entità
##   ## DESCRIZIONE / ## USCITA / ## OGGETTO / ## ASCOLTA / ## TESTO / ## SCELTA
##                                               -> apre un blocco dell'entità
##   >> risonanza +1, >> segna x, >> ricordo x, >> vai x, >> fine
##                                               -> effetti del blocco
##   // commento                                 -> ignorato
class_name Storia
extends RefCounted

var id: String = ""
var meta: Dictionary = {}       # chiavi della sezione # LINEA
var stanze: Dictionary = {}     # id -> entità stanza
var eventi: Dictionary = {}     # id -> entità evento
var ricordi: Dictionary = {}    # id -> entità ricordo
var errori: Array[String] = []  # problemi che bloccano il gioco
var avvisi: Array[String] = []  # problemi che non bloccano ma vanno guardati

const _CONFRONTI := [">=", "<=", "!=", ">", "<", "="]


static func carica(cartella: String) -> Storia:
	var s := Storia.new()
	s.id = cartella.trim_suffix("/").get_file()
	var files := DirAccess.get_files_at(cartella)
	var nomi: Array[String] = []
	for f in files:
		# In alcune esportazioni i file possono comparire con suffisso .remap:
		# lo togliamo e teniamo solo i .txt.
		var n := String(f).trim_suffix(".remap")
		if n.ends_with(".txt") and not nomi.has(n):
			nomi.append(n)
	nomi.sort()
	if nomi.is_empty():
		s.errori.append("Nessun file .txt trovato in %s" % cartella)
	for n in nomi:
		s._analizza_file(cartella.path_join(n))
	s._verifica()
	return s


# ---------------------------------------------------------------- lettura

func _analizza_file(percorso: String) -> void:
	var fa := FileAccess.open(percorso, FileAccess.READ)
	if fa == null:
		errori.append("Impossibile aprire %s" % percorso)
		return
	var testo := fa.get_as_text()
	fa.close()
	var nome_file := percorso.get_file()
	var righe := testo.replace("\r\n", "\n").replace("\r", "\n").split("\n")

	var entita: Dictionary = {}
	var blocco: Dictionary = {}

	for i in righe.size():
		var riga: String = righe[i].strip_edges(false, true)
		var t := riga.strip_edges()
		var dove := "%s, riga %d" % [nome_file, i + 1]

		if t.begins_with("//"):
			continue

		if t.begins_with("## "):
			_chiudi_blocco(blocco)
			blocco = {}
			if entita.is_empty():
				errori.append("%s: blocco '%s' fuori da una STANZA/EVENTO/RICORDO" % [dove, t])
				continue
			blocco = _nuovo_blocco(t.substr(3).strip_edges(), entita, dove)
			continue

		if t.begins_with("# "):
			_chiudi_blocco(blocco)
			blocco = {}
			entita = _nuova_entita(t.substr(2).strip_edges(), dove, nome_file)
			continue

		if t.begins_with(">>"):
			if blocco.is_empty():
				errori.append("%s: effetto '%s' fuori da un blocco" % [dove, t])
				continue
			var eff := _leggi_effetto(t.substr(2).strip_edges(), dove)
			if not eff.is_empty():
				blocco["effetti"].append(eff)
			continue

		# Metadati (chiave: valore) subito dopo l'intestazione dell'entità.
		if blocco.is_empty() and not entita.is_empty():
			if t == "":
				continue
			var p := t.find(":")
			if p > 0 and p < 24 and not t.substr(0, p).contains(" "):
				entita["meta"][t.substr(0, p).strip_edges().to_lower()] = t.substr(p + 1).strip_edges()
				continue
			# Un ricordo può non avere blocchi: il testo va direttamente nell'entità.
			if entita["tipo"] == "ricordo":
				blocco = {"tipo": "testo", "cond": [], "righe": [], "effetti": [], "dove": dove}
				entita["blocchi"].append(blocco)
				blocco["righe"].append(riga)
				continue
			avvisi.append("%s: testo fuori da un blocco, ignorato: '%s'" % [dove, t.left(40)])
			continue

		if not blocco.is_empty():
			blocco["righe"].append(riga)
		elif t != "":
			avvisi.append("%s: testo prima di qualsiasi intestazione, ignorato" % dove)

	_chiudi_blocco(blocco)


func _nuova_entita(intest: String, dove: String, nome_file: String) -> Dictionary:
	var parti := intest.split(" ", false, 1)
	var tipo := parti[0].to_upper()
	var eid := parti[1].strip_edges() if parti.size() > 1 else ""
	var e := {"id": eid, "meta": {}, "blocchi": [], "dove": dove, "file": nome_file}
	match tipo:
		"LINEA":
			e["tipo"] = "linea"
			# La linea condivide il dizionario meta con la Storia.
			e["meta"] = meta
			meta["id"] = eid
		"STANZA":
			e["tipo"] = "stanza"
			e["descrizioni"] = []
			e["uscite"] = []
			e["oggetti"] = {}
			e["ordine_oggetti"] = []
			e["ascolta"] = []
			_registra(stanze, eid, e, dove, "STANZA")
		"EVENTO":
			e["tipo"] = "evento"
			e["testi"] = []
			e["scelte"] = []
			_registra(eventi, eid, e, dove, "EVENTO")
		"RICORDO":
			e["tipo"] = "ricordo"
			_registra(ricordi, eid, e, dove, "RICORDO")
		_:
			errori.append("%s: intestazione sconosciuta '# %s' (usa LINEA, STANZA, EVENTO o RICORDO)" % [dove, parti[0]])
			e["tipo"] = "ignota"
	if eid == "" and e["tipo"] != "ignota":
		errori.append("%s: manca il nome dopo '# %s'" % [dove, tipo])
	return e


func _registra(dove_reg: Dictionary, eid: String, e: Dictionary, dove: String, cosa: String) -> void:
	if dove_reg.has(eid):
		errori.append("%s: %s '%s' esiste già (%s)" % [dove, cosa, eid, dove_reg[eid]["dove"]])
	dove_reg[eid] = e


func _nuovo_blocco(intest: String, entita: Dictionary, dove: String) -> Dictionary:
	var parti := intest.split(" ", false, 1)
	var chiave := parti[0].to_upper()
	var resto := parti[1].strip_edges() if parti.size() > 1 else ""
	var b := {"tipo": chiave.to_lower(), "cond": [], "righe": [], "effetti": [], "dove": dove}
	var tipo_e: String = entita["tipo"]

	match chiave:
		"DESCRIZIONE":
			if tipo_e != "stanza":
				errori.append("%s: DESCRIZIONE è ammessa solo in una STANZA" % dove)
				return {}
			b["cond"] = _leggi_condizioni(_dopo_se(resto, true), dove)
			entita["descrizioni"].append(b)
		"ASCOLTA":
			if tipo_e != "stanza":
				errori.append("%s: ASCOLTA è ammessa solo in una STANZA" % dove)
				return {}
			b["cond"] = _leggi_condizioni(_dopo_se(resto, true), dove)
			entita["ascolta"].append(b)
		"USCITA":
			if tipo_e != "stanza":
				errori.append("%s: USCITA è ammessa solo in una STANZA" % dove)
				return {}
			var freccia := resto.find("->")
			if freccia < 0:
				errori.append("%s: USCITA senza '->' (esempio: ## USCITA nord -> mensa)" % dove)
				return {}
			b["dir"] = resto.substr(0, freccia).strip_edges().to_lower()
			var dx := resto.substr(freccia + 2).strip_edges()
			var se := _cerca_se(dx)
			b["target"] = (dx.substr(0, se) if se >= 0 else dx).strip_edges()
			b["cond"] = _leggi_condizioni(dx.substr(se + 4) if se >= 0 else "", dove)
			if b["dir"] == "":
				errori.append("%s: USCITA senza direzione" % dove)
			entita["uscite"].append(b)
		"OGGETTO":
			if tipo_e != "stanza":
				errori.append("%s: OGGETTO è ammesso solo in una STANZA" % dove)
				return {}
			var dp := resto.find(":")
			var oid := ""
			var nome := ""
			var dopo := ""
			if dp < 0:
				var se2 := _cerca_se(resto)
				oid = (resto.substr(0, se2) if se2 >= 0 else resto).strip_edges()
				nome = oid
				dopo = resto.substr(se2 + 4) if se2 >= 0 else ""
			else:
				oid = resto.substr(0, dp).strip_edges()
				var dx2 := resto.substr(dp + 1).strip_edges()
				var se3 := _cerca_se(dx2)
				nome = (dx2.substr(0, se3) if se3 >= 0 else dx2).strip_edges()
				dopo = dx2.substr(se3 + 4) if se3 >= 0 else ""
			oid = oid.to_lower()
			if oid == "" or oid.contains(" "):
				errori.append("%s: nome dell'oggetto non valido '%s' (una parola sola, senza spazi)" % [dove, oid])
				return {}
			b["cond"] = _leggi_condizioni(dopo, dove)
			var oggetti: Dictionary = entita["oggetti"]
			if not oggetti.has(oid):
				oggetti[oid] = {"id": oid, "nome": nome, "blocchi": []}
				entita["ordine_oggetti"].append(oid)
			elif nome != "" and nome != oid:
				# Il nome può cambiare nelle varianti: vale quello del blocco scelto.
				pass
			b["nome"] = nome
			oggetti[oid]["blocchi"].append(b)
		"TESTO":
			if tipo_e == "evento":
				b["cond"] = _leggi_condizioni(_dopo_se(resto, true), dove)
				entita["testi"].append(b)
			elif tipo_e == "ricordo":
				b["cond"] = []
				entita["blocchi"].append(b)
			else:
				errori.append("%s: TESTO è ammesso solo in un EVENTO o RICORDO" % dove)
				return {}
		"SCELTA":
			if tipo_e != "evento":
				errori.append("%s: SCELTA è ammessa solo in un EVENTO" % dove)
				return {}
			var fr := resto.find("->")
			if fr < 0:
				errori.append("%s: SCELTA senza '->' (esempio: ## SCELTA Continua -> contatto_2)" % dove)
				return {}
			b["etichetta"] = resto.substr(0, fr).strip_edges()
			var dx3 := resto.substr(fr + 2).strip_edges()
			var se4 := _cerca_se(dx3)
			b["target"] = (dx3.substr(0, se4) if se4 >= 0 else dx3).strip_edges()
			b["cond"] = _leggi_condizioni(dx3.substr(se4 + 4) if se4 >= 0 else "", dove)
			entita["scelte"].append(b)
		_:
			errori.append("%s: blocco sconosciuto '## %s'" % [dove, parti[0]])
			return {}
	return b


func _chiudi_blocco(b: Dictionary) -> void:
	if b.is_empty():
		return
	var righe: Array = b["righe"]
	# Togliamo righe vuote in testa e in coda; dentro restano (sono i paragrafi).
	while righe.size() > 0 and String(righe[0]).strip_edges() == "":
		righe.pop_front()
	while righe.size() > 0 and String(righe[righe.size() - 1]).strip_edges() == "":
		righe.pop_back()
	b["testo"] = "\n".join(PackedStringArray(righe))


# Restituisce la posizione di " se " (con spazi) o -1.
func _cerca_se(s: String) -> int:
	return (" " + s + " ").find(" se ") - 1 if (" " + s + " ").find(" se ") >= 0 else -1


# Per DESCRIZIONE/ASCOLTA/TESTO il resto dell'intestazione è tutto condizione.
# Si accetta sia "se risonanza >= 3" sia la scorciatoia "ritorno".
func _dopo_se(resto: String, _tutto: bool) -> String:
	var r := resto.strip_edges()
	if r.to_lower().begins_with("se "):
		return r.substr(3)
	return r


func _leggi_condizioni(s: String, dove: String) -> Array:
	var out: Array = []
	var testo := s.strip_edges()
	if testo == "":
		return out
	for termine in testo.split(" e ", false):
		var t := String(termine).strip_edges()
		var neg := false
		if t.to_lower().begins_with("non "):
			neg = true
			t = t.substr(4).strip_edges()
		var c := _leggi_termine(t, dove)
		if c.is_empty():
			continue
		c["neg"] = neg
		out.append(c)
	return out


func _leggi_termine(t: String, dove: String) -> Dictionary:
	var basso := t.to_lower()
	if basso == "prima volta":
		return {"t": "prima"}
	if basso == "ritorno":
		return {"t": "ritorno"}
	for op in _CONFRONTI:
		var p := basso.find(op)
		if p > 0:
			var nome := basso.substr(0, p).strip_edges()
			var val := basso.substr(p + op.length()).strip_edges()
			if not val.is_valid_int():
				errori.append("%s: nella condizione '%s' il valore deve essere un numero" % [dove, t])
				return {}
			return {"t": "cmp", "var": nome, "op": op, "val": int(val)}
	var parti := basso.split(" ", false)
	if parti.size() == 2 and parti[0] in ["visitato", "visitata", "esaminato", "esaminata", "ricordo"]:
		var tipo := "visitato" if parti[0].begins_with("visitat") else ("esaminato" if parti[0].begins_with("esaminat") else "ricordo")
		return {"t": tipo, "x": parti[1]}
	if parti.size() == 1:
		return {"t": "flag", "x": parti[0]}
	errori.append("%s: condizione non capita '%s'" % [dove, t])
	return {}


func _leggi_effetto(s: String, dove: String) -> Dictionary:
	var parti := s.strip_edges().split(" ", false)
	if parti.is_empty():
		return {}
	var k := parti[0].to_lower()
	match k:
		"risonanza":
			if parti.size() < 2:
				errori.append("%s: '>> risonanza' vuole un numero (es. +1)" % dove)
				return {}
			var v := parti[1]
			var relativo := v.begins_with("+") or v.begins_with("-")
			if not v.trim_prefix("+").is_valid_int():
				errori.append("%s: '>> risonanza %s' non è un numero" % [dove, v])
				return {}
			return {"e": "risonanza", "val": int(v.trim_prefix("+")), "rel": relativo}
		"segna", "togli", "ricordo", "vai":
			if parti.size() < 2:
				errori.append("%s: '>> %s' vuole un nome" % [dove, k])
				return {}
			return {"e": k, "x": parti[1].to_lower() if k != "vai" else parti[1]}
		"fine":
			return {"e": "fine", "x": parti[1] if parti.size() > 1 else ""}
		"pausa":
			return {"e": "pausa"}
		_:
			errori.append("%s: effetto sconosciuto '>> %s'" % [dove, s])
			return {}


# ---------------------------------------------------------------- verifica

func _verifica() -> void:
	if meta.is_empty():
		errori.append("Manca la sezione '# LINEA' (di solito nel file 00_linea.txt)")
		return
	var inizio: String = meta.get("inizio", "")
	if inizio == "" or not stanze.has(inizio):
		errori.append("LINEA: 'inizio: %s' non è una STANZA esistente" % inizio)
	for k in ["intro", "tempo"]:
		var v: String = meta.get(k, "")
		if v != "" and not eventi.has(v) and not stanze.has(v):
			errori.append("LINEA: '%s: %s' non è un EVENTO o una STANZA esistente" % [k, v])
	if meta.has("limite_azioni") and not String(meta["limite_azioni"]).is_valid_int():
		errori.append("LINEA: 'limite_azioni' deve essere un numero")

	var visti_oggetti := {}
	for sid in stanze:
		var st: Dictionary = stanze[sid]
		if st["descrizioni"].is_empty():
			errori.append("%s: la STANZA '%s' non ha nessuna DESCRIZIONE" % [st["dove"], sid])
		for u in st["uscite"]:
			var tg: String = u["target"]
			if tg != "-" and not stanze.has(tg) and not eventi.has(tg):
				errori.append("%s: l'USCITA '%s' porta a '%s', che non esiste" % [u["dove"], u["dir"], tg])
			_verifica_effetti(u)
		for b in st["descrizioni"] + st["ascolta"]:
			_verifica_effetti(b)
		for oid in st["oggetti"]:
			if visti_oggetti.has(oid):
				avvisi.append("%s: l'oggetto '%s' esiste anche in '%s' (meglio nomi unici)" % [st["dove"], oid, visti_oggetti[oid]])
			visti_oggetti[oid] = sid
			for b in st["oggetti"][oid]["blocchi"]:
				_verifica_effetti(b)
	for eid in eventi:
		var ev: Dictionary = eventi[eid]
		for b in ev["testi"]:
			_verifica_effetti(b)
		for sc in ev["scelte"]:
			var tg2: String = sc["target"]
			if tg2 != "" and tg2 != "-" and not stanze.has(tg2) and not eventi.has(tg2):
				errori.append("%s: la SCELTA '%s' porta a '%s', che non esiste" % [sc["dove"], sc["etichetta"], tg2])
			_verifica_effetti(sc)
		var ha_fine := false
		for b in ev["testi"]:
			for e in b["effetti"]:
				if e["e"] == "fine" or e["e"] == "vai":
					ha_fine = true
		if ev["scelte"].is_empty() and not ha_fine:
			errori.append("%s: l'EVENTO '%s' non ha SCELTE né '>> vai' né '>> fine': il giocatore resterebbe bloccato" % [ev["dove"], eid])
	for rid in ricordi:
		var r: Dictionary = ricordi[rid]
		var testo := ""
		for b in r["blocchi"]:
			testo += String(b.get("testo", ""))
		if testo.strip_edges() == "":
			avvisi.append("%s: il RICORDO '%s' è vuoto" % [r["dove"], rid])


func _verifica_effetti(b: Dictionary) -> void:
	for e in b["effetti"]:
		match e["e"]:
			"ricordo":
				if not ricordi.has(e["x"]):
					errori.append("%s: '>> ricordo %s' ma quel RICORDO non esiste" % [b["dove"], e["x"]])
			"vai":
				if not stanze.has(e["x"]) and not eventi.has(e["x"]):
					errori.append("%s: '>> vai %s' ma non è una STANZA o un EVENTO" % [b["dove"], e["x"]])


func testo_ricordo(rid: String) -> String:
	if not ricordi.has(rid):
		return ""
	var parti: PackedStringArray = []
	for b in ricordi[rid]["blocchi"]:
		parti.append(String(b.get("testo", "")))
	return "\n\n".join(parti).strip_edges()
