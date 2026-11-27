# Come modificare i testi del gioco

Tutti i testi stanno in due cartelle:

- `storia/baldr/` — la linea della Piattaforma Baldr
- `storia/dee/` — la linea della RSS Arthur Dee

Sono normali file `.txt`, uno per stanza. **Non serve toccare il codice.**

## Il modo più semplice: dal sito di GitHub

1. Apri il repository su github.com, entra in `storia/baldr` (o `storia/dee`) e clicca sul file.
2. Clicca sulla matita ✏️ in alto a destra.
3. Modifica il testo.
4. Clicca **Commit changes** (in alto a destra), scrivi due parole su cosa hai cambiato, conferma.

Entro due o tre minuti il gioco online si aggiorna da solo. Se hai fatto un errore di formato, GitHub ti manda una mail e nella scheda **Actions** trovi l'elenco esatto: file, riga, cosa non va. Il gioco online resta quello di prima finché l'errore non è corretto, quindi non puoi romperlo.

## Le regole del formato

È quasi tutto testo libero. Ci sono solo quattro tipi di righe speciali.

| Riga che inizia con | Significato |
|---|---|
| `# ` | apre una STANZA, un EVENTO, un RICORDO (o la LINEA) |
| `## ` | apre un blocco dentro la stanza: DESCRIZIONE, USCITA, OGGETTO, ASCOLTA, TESTO, SCELTA |
| `>> ` | un effetto: alza la risonanza, fa affiorare un ricordo, porta altrove |
| `// ` | un commento: il gioco lo ignora, serve a te |

Tutto il resto è testo che il giocatore legge. **Si va a capo dove vuoi andare a capo**; una riga vuota fa un paragrafo.

Dentro il testo:

- `*parola*` → *corsivo* (i pensieri del protagonista)
- `**parola**` → **grassetto**
- una riga che inizia con `~` → la **voce della nave/piattaforma**, in rosso

### Una stanza, esempio completo

```
# STANZA mensa
titolo: La mensa
stile: luce

## DESCRIZIONE
Il testo che si legge la prima volta che si entra.

## DESCRIZIONE ritorno
Il testo delle volte successive.

## DESCRIZIONE se risonanza >= 4
Il testo quando la piattaforma ha già "sentito" il giocatore.
~ Questa riga la dice la Baldr.

## USCITA nord -> sala_controllo
Testo facoltativo che si legge mentre si passa.

## OGGETTO bicchieri: i cinque bicchieri
Cosa si legge esaminandoli.
>> risonanza +1
>> ricordo arianna_bicchieri

## ASCOLTA
Cosa si sente la prima volta che si ascolta.
>> risonanza +1

## ASCOLTA
La seconda volta.
```

### La regola d'oro: vince il blocco più in basso

Quando ci sono più versioni dello stesso blocco (più DESCRIZIONI, più versioni dello stesso OGGETTO, più USCITE nella stessa direzione), il gioco usa **l'ultima scritta nel file la cui condizione è vera**. Quindi: scrivi prima la versione normale, poi sotto le varianti, dalla meno alla più "avanzata".

Fanno eccezione gli ASCOLTA: si mostrano **in ordine**, uno per volta, ogni volta che il giocatore ascolta. Quando sono finiti si ripete l'ultimo.

### Le condizioni (dopo la parola `se`)

| Scrivi | Vero quando |
|---|---|
| `ritorno` | il giocatore è già stato in questa stanza |
| `risonanza >= 4` | la risonanza è almeno 4 (si possono usare `>= <= > < =`) |
| `ricordi >= 7` | il giocatore ha trovato almeno 7 ricordi |
| `azioni >= 50` | il giocatore ha fatto almeno 50 azioni |
| `esaminato bicchieri` | l'oggetto `bicchieri` è stato esaminato almeno una volta prima |
| `visitato mensa` | il giocatore è stato nella mensa |
| `ricordo kristina_notte` | quel ricordo è già affiorato |
| `vista_scritta` | è stato "segnato" con `>> segna vista_scritta` |
| `non …` | il contrario: `non vista_scritta` |

Si combinano con `e`: `se risonanza >= 5 e ricordo trym_ragnatela`.

Trucco utile: `## OGGETTO foto: la foto se esaminato foto` è il testo che si legge **dalla seconda volta** in poi.

### Gli effetti (righe `>>`)

| Effetto | Cosa fa |
|---|---|
| `>> risonanza +1` | aumenta la risonanza (anche `-1`, o un numero fisso come `5`) |
| `>> ricordo nome` | fa affiorare quel RICORDO (una volta sola) |
| `>> segna nome` / `>> togli nome` | mette/toglie un segno da usare nelle condizioni |
| `>> vai nome` | porta il giocatore in una STANZA o in un EVENTO |
| `>> fine nome` | finisce la partita (il nome serve a distinguere i finali) |

### Le uscite

`## USCITA giù -> locali_tecnici` crea il pulsante «Giù». La direzione è una parola qualunque: il pulsante mostra solo quella, mai il nome della stanza (la mappa se la fa il giocatore). Per un passaggio chiuso si mette `-` come destinazione:

```
## USCITA est -> - se risonanza < 6
Il volantino non gira.

## USCITA est -> red_carpet se risonanza >= 6
La porta si apre da sola.
```

### Eventi e scelte

Un EVENTO è una pagina senza movimento (inizio, contatto, finali). I suoi `## TESTO` si leggono tutti, in ordine (quelli con condizione solo se vera). Le `## SCELTA` diventano pulsanti:

```
## SCELTA Lasciati andare -> finale_noi
## SCELTA Torna su -> finale_ritorno
## SCELTA Lascia che parli con la tua voce -> finale_voce se ricordi >= 7
```

### I ricordi

Stanno in `10_ricordi.txt`. Ognuno ha un nome, chi ricorda e un titolo:

```
# RICORDO kristina_polaroid
persona: Kristina
titolo: Gunther–o–come–si–chiamava
Il testo del ricordo, scritto come lo ricorda lei.
```

### Aggiungere una stanza nuova

Crea un file nuovo nella cartella della linea (il nome del file non conta, solo che finisca in `.txt`), scrivi `# STANZA nome_nuovo`, e aggiungi un'`## USCITA … -> nome_nuovo` in una stanza esistente. Nient'altro.

### Le impostazioni della linea (`00_linea.txt`)

| Chiave | Cosa fa |
|---|---|
| `inizio:` | stanza di partenza |
| `intro:` | evento iniziale |
| `limite_azioni:` | dopo quante azioni arriva comunque la Madre |
| `tempo:` | l'evento che parte quando il tempo scade |
| `non_vedo:`, `non_si_passa:`, `non_capisco:`, `silenzio:` | le frasi di servizio |

Gli stili visivi disponibili per `stile:` sono: `notte`, `nebbia`, `interno`, `ruggine`, `luce`, `abisso`, `madre`, `alba`.

## Errori frequenti

- **Il nome dopo `->` deve esistere** ed essere scritto uguale (`sala_controllo`, non `sala controllo`).
- **I nomi di oggetti, stanze, ricordi sono una parola sola**, senza spazi: usa il trattino basso.
- Un'etichetta di SCELTA non può contenere `->`.
- Nel nome visibile di un OGGETTO evita la parola isolata «se»: il gioco la prenderebbe per l'inizio di una condizione.
