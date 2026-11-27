## Comandi: trasforma una frase scritta dal giocatore ("vai a nord",
## "esamina la polaroid", "ascolta") in un'azione per il Motore.
## Il gioco si può giocare anche solo con i pulsanti: questo è un di più,
## un omaggio alle vecchie avventure testuali.
class_name Comandi
extends RefCounted

const ABBREVIAZIONI := {
	"n": "nord", "s": "sud", "e": "est", "o": "ovest", "w": "ovest",
	"u": "su", "d": "giù", "giu": "giù", "alto": "su", "basso": "giù",
	"sali": "su", "scendi": "giù", "pr": "prua", "pp": "poppa",
	"bab": "babordo", "trib": "tribordo", "sinistra": "babordo", "destra": "tribordo",
}
const PAROLE_VUOTE := ["il", "lo", "la", "i", "gli", "le", "l", "un", "uno", "una",
	"a", "al", "allo", "alla", "ai", "agli", "alle", "verso", "di", "del", "della",
	"dei", "delle", "da", "dal", "dalla", "in", "nel", "nella", "sul", "sulla"]
const VERBI_VAI := ["vai", "va", "andare", "cammina", "entra", "esci", "torna", "prosegui", "dirigiti"]
const VERBI_ESAMINA := ["esamina", "x", "guarda", "osserva", "leggi", "tocca", "apri",
	"prendi", "studia", "controlla", "annusa", "ispeziona", "scruta"]
const VERBI_ASCOLTA := ["ascolta", "aspetta", "attendi", "z", "resta", "rimani", "fermati", "taci"]


static func normalizza(s: String) -> String:
	var t := s.to_lower().strip_edges()
	for coppia in [["à", "a"], ["è", "e"], ["é", "e"], ["ì", "i"], ["ò", "o"], ["ù", "u"], ["'", " "], ["’", " "]]:
		t = t.replace(coppia[0], coppia[1])
	var pulito := ""
	for ch in t:
		pulito += ch if (ch.is_valid_identifier() or ch == " " or ch.is_valid_int()) else " "
	while pulito.contains("  "):
		pulito = pulito.replace("  ", " ")
	return pulito.strip_edges()


## Restituisce {"azione": "vai"/"esamina"/"ascolta"/"guarda"/"ricordi"/"aiuto"/"scegli"/"ignoto", "arg": ...}
static func interpreta(frase: String, motore: Motore) -> Dictionary:
	var t := normalizza(frase)
	if t == "":
		return {"azione": "nulla"}
	var parole := t.split(" ", false)

	if t in ["aiuto", "help", "comandi", "h"]:
		return {"azione": "aiuto"}
	if t in ["ricordi", "memoria", "memorie", "inventario", "i"]:
		return {"azione": "ricordi"}
	if t in ["guarda", "g", "l", "descrivi", "guardati intorno", "guarda intorno", "dove sono"]:
		return {"azione": "guarda"}

	# Scelte di un evento: per numero o per parole dell'etichetta.
	var scelte := motore.scelte_valide()
	if not scelte.is_empty():
		if t.is_valid_int() and int(t) >= 1 and int(t) <= scelte.size():
			return {"azione": "scegli", "arg": int(t) - 1}
		for i in scelte.size():
			if normalizza(scelte[i]["etichetta"]).contains(t) or t.contains(normalizza(scelte[i]["etichetta"])):
				return {"azione": "scegli", "arg": i}
		return {"azione": "ignoto"}

	if parole[0] in VERBI_ASCOLTA:
		return {"azione": "ascolta"}

	# Direzioni.
	var uscite := motore.uscite_valide()
	var candidate: Array = []
	for p in parole:
		if p in VERBI_VAI or p in PAROLE_VUOTE:
			continue
		candidate.append(ABBREVIAZIONI.get(p, p))
	if candidate.size() >= 1:
		for d in uscite:
			if normalizza(d) == normalizza(candidate[0]):
				return {"azione": "vai", "arg": d}
		if parole[0] in VERBI_VAI:
			return {"azione": "vai", "arg": candidate[0]}

	# Oggetti: se c'è un verbo di esame lo togliamo, poi cerchiamo il nome.
	var resto: Array = []
	for i in parole.size():
		if i == 0 and parole[i] in VERBI_ESAMINA:
			continue
		if parole[i] in PAROLE_VUOTE:
			continue
		resto.append(parole[i])
	if resto.is_empty():
		return {"azione": "guarda"} if parole[0] in VERBI_ESAMINA else {"azione": "ignoto"}
	var migliore := ""
	var punteggio := 0
	for o in motore.oggetti_validi():
		var nome := normalizza(o["nome"] + " " + o["id"])
		var p := 0
		for w in resto:
			if w.length() >= 3 and nome.contains(w):
				p += 2
			elif nome.split(" ").has(w):
				p += 1
		if p > punteggio:
			punteggio = p
			migliore = o["id"]
	if migliore != "":
		return {"azione": "esamina", "arg": migliore}
	return {"azione": "ignoto"}
