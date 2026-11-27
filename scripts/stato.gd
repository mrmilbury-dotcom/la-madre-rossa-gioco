## Stato: tutto quello che il gioco deve ricordare di una partita.
## È un semplice contenitore di dati, salvabile in JSON.
class_name Stato
extends RefCounted

var linea: String = ""
var stanza: String = ""          # stanza in cui si trova il giocatore
var evento: String = ""          # evento in corso ("" se si è in una stanza)
var visite: Dictionary = {}      # stanza -> numero di ingressi
var esaminati: Dictionary = {}   # oggetto -> numero di volte esaminato
var flag: Dictionary = {}        # nome -> true
var ricordi: Array = []          # id dei ricordi trovati, in ordine
var ascolti: Dictionary = {}     # stanza -> indici dei blocchi ASCOLTA già mostrati
var risonanza: int = 0
var azioni: int = 0
var tempo_scaduto: bool = false
var finito: bool = false
var finale: String = ""


func valore(nome: String) -> int:
	match nome:
		"risonanza":
			return risonanza
		"azioni":
			return azioni
		"ricordi":
			return ricordi.size()
		"visite":
			return visite.get(stanza, 0)
	# Contatori liberi: "visite_mensa" = ingressi nella stanza mensa.
	if nome.begins_with("visite_"):
		return visite.get(nome.substr(7), 0)
	if nome.begins_with("esaminato_"):
		return esaminati.get(nome.substr(10), 0)
	return 1 if flag.has(nome) else 0


func a_dizionario() -> Dictionary:
	return {
		"versione": 1,
		"linea": linea, "stanza": stanza, "evento": evento,
		"visite": visite, "esaminati": esaminati, "flag": flag,
		"ricordi": ricordi, "ascolti": ascolti,
		"risonanza": risonanza, "azioni": azioni,
		"tempo_scaduto": tempo_scaduto, "finito": finito, "finale": finale,
	}


static func da_dizionario(d: Dictionary) -> Stato:
	var s := Stato.new()
	s.linea = d.get("linea", "")
	s.stanza = d.get("stanza", "")
	s.evento = d.get("evento", "")
	s.visite = d.get("visite", {})
	s.esaminati = d.get("esaminati", {})
	s.flag = d.get("flag", {})
	s.ricordi = d.get("ricordi", [])
	s.ascolti = d.get("ascolti", {})
	s.risonanza = int(d.get("risonanza", 0))
	s.azioni = int(d.get("azioni", 0))
	s.tempo_scaduto = bool(d.get("tempo_scaduto", false))
	s.finito = bool(d.get("finito", false))
	s.finale = d.get("finale", "")
	# JSON trasforma gli interi in float: li riportiamo a interi.
	for k in s.visite.keys():
		s.visite[k] = int(s.visite[k])
	for k in s.esaminati.keys():
		s.esaminati[k] = int(s.esaminati[k])
	for k in s.ascolti.keys():
		var arr: Array = []
		for v in s.ascolti[k]:
			arr.append(int(v))
		s.ascolti[k] = arr
	return s
