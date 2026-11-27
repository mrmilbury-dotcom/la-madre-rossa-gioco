# EMISSARI — bibbia narrativa

*Un'esplorazione testuale ambientata dopo «La madre rossa» di Maico Morellini.*
Questo documento è la mappa di tutto quello che c'è nel gioco: chi, dove, perché.
I testi veri stanno in `storia/baldr/` e `storia/dee/`; il modo di modificarli è in `GUIDA_AI_TESTI.md`.

---

## 1. L'idea in una frase

Nel romanzo la Madre Rossa lascia dietro di sé due **emissari**: la Piattaforma Baldr e la RSS Arthur Dee, luoghi diventati vivi, con memoria e voce. Il giocatore sale a bordo di uno dei due, lo esplora senza mappa, e viene lentamente *ascoltato* — finché la Madre torna, i suoi ricordi si mescolano con quelli di chi c'era prima, e lui si ritrova fuori. Ma non più da solo.

## 2. Regole di tono

- **Seconda persona, presente.** «Sei sull'eliporto.» È la lingua delle avventure testuali, piegata alla prosa del romanzo.
- **Dettaglio fisico prima della paura.** Freddo, sale, odore di terra e funghi, metallo che parla. L'orrore arriva dalla somma, mai dallo spavento.
- **Frasi brevi a chiusura.** «Era solido. Reale.» Il ritmo del romanzo.
- **I pensieri del protagonista** sono in *corsivo*.
- **La voce dell'emissario** (righe che iniziano con `~`) ha un idioletto proprio:
  - *Baldr*: parole composte col trattino come nel romanzo — *prima-ieri, dentro-fuori, non-silenzio, disse-pensò* — chiama gli umani «Figli di Carne». È giovane: scopre la gioia di avere ricordi.
  - *Arthur Dee*: è emissaria da più tempo, ha imparato il linguaggio degli uomini dal suo capitano. Parla con la cortesia tagliente di Matthew Bailey («Si prenda tutto il tempo necessario»), tiene un diario di bordo dove i giorni non si contano più, e misura ogni cosa in percentuali come il dottor Fraser.
- **Niente spiegazioni.** La Madre non viene mai definita. I documenti si contraddicono quando serve.

## 3. Le due linee

### A. La Piattaforma Baldr

| | |
|---|---|
| **Protagonista** | **Iselin**, collega e amica di Kristina Isaksen al Ministero del Clima e dell'Ambiente. È quella che «fiutava» gli incubi di Kina. |
| **Quando** | Metà dicembre, sette settimane dopo l'epilogo. Luce per poche ore. |
| **Perché è lì** | Il Ministero manda qualcuno a recuperare gli effetti personali dei dispersi. Iselin si è offerta. Il pilota è Ruben Blom — lo stesso che nell'epilogo disse «col cazzo che scendo». Non scende neanche stavolta: le dà novanta minuti. |
| **Ferita** | Kristina non voleva nessuno accanto di notte. Iselin è rimasta fuori. Da quando Kina è sparita, Iselin sogna i suoi sogni e al mattino il caffè sa di terra. |
| **Cosa le dà la Madre** | Ciò che Kristina le negava: condividere la notte. |
| **La voce** | La Baldr parla dalla filodiffusione, fa suonare ‘La Primavera’ di Vivaldi anche se la chiavetta è stata repertata, chiama Iselin «Figlia di Carne». |

**Mappa (il giocatore non la vede mai):**

```
                 ELIPORTO ──est── CORRIDOIO ──nord── CABINE
                    │ giù            │ est
                    │              MENSA
                    │                │ nord
                  COPERTA ──ovest── SALA DI CONTROLLO
                    │ giù
                 LOCALI TECNICI ──est (risonanza ≥ 6)── RED CARPET ──giù── la Madre
```

### B. La RSS Arthur Dee

| | |
|---|---|
| **Protagonista** | **Leif Aamodt**, cinquantun anni, nel 2022 marinaio sulla baleniera *Willow*: era al radar durante i quattro giorni d'inseguimento. Oggi pesca sul *Skarv* con il cugino Odd. |
| **Quando** | Un mese dopo l'incidente della Baldr. Mare di Barents, vicino all'Isola degli Orsi. Una tempesta che nessuno ha previsto. |
| **Perché è lì** | Il radar dello Skarv dà un'eco dove non dovrebbe esserci niente. Leif riconosce la sagoma prima ancora di vederla. Sale a bordo da solo: «Stavolta non scappa». |
| **Ferita** | È uno che arriva sempre tardi: alla Dee nel 2022, alla vita di sua figlia Sunniva, al matrimonio con Marit. Ed è stato uno dei pochi della Willow a parlare: con un giornalista di Oslo, Trym Solbakken. Ha letto il nome di Trym tra i dispersi della Baldr. |
| **Cosa gli dà la Madre** | Arrivare. Finalmente. |
| **La voce** | La nave parla dall'impianto di emergenza con le cadenze di Bailey, scrive sui terminali del laboratorio con l'IA addestrata sul Sigillo, conta i giorni di un diario di bordo che non finisce. |

**Mappa:**

```
            PLANCIA ──poppa── CABINA DI BAILEY
               │ sotto            │ sotto
            MURATA ──babordo── MENSA DELL'EQUIPAGGIO
                                  │ sotto
                            CABINA DI EGOROV ──poppa── RETROSCENA ──babordo── LABORATORIO
                                                                                │ sotto (risonanza ≥ 6)
                                                                              STIVA ── la Madre
```

## 4. Come funziona (senza enigmi)

- **Si esplora** con le direzioni (Baldr: nord/sud/est/ovest/su/giù; Dee: prua/poppa/babordo/tribordo/sopra/sotto). I pulsanti mostrano solo la direzione, mai il nome della stanza: la mappa se la costruisce il giocatore.
- **Si esamina** ciò che c'è. Si **ascolta**: è il gesto chiave. Ogni volta che ascolti, l'emissario ti sente un po' di più.
- **Risonanza** (nascosta, ma visibile nello sfondo che si riempie di venature rosse): sale esaminando e ascoltando.
  - da 3: l'emissario comincia a rivolgersi a te nelle descrizioni;
  - da 6: si apre il passaggio verso il cuore (red carpet / stiva);
  - le descrizioni cambiano con la risonanza e con quello che hai già visto.
- **Ricordi**: frammenti dei protagonisti del romanzo (e del protagonista stesso) che affiorano dagli oggetti. Si rileggono dal pulsante «Ricordi».
- **Il tempo**: dopo circa 60 azioni il buio (Baldr) o la tempesta (Dee) arrivano comunque, e la Madre viene a cercarti dove sei.

## 5. Il contatto e i finali

In entrambe le linee la Madre risale, i ricordi si fondono (il testo passa da «tu» a «noi», come nel capitolo finale del romanzo) e poi c'è una scelta. **Tutti i finali hanno il protagonista fuori dalla struttura e parte della Madre.** Cambia il modo.

| Linea | Finale | Come ci si arriva | Cosa succede |
|---|---|---|---|
| Baldr | **Noi** | «Chiamala: Kina.» | Iselin scende nel rosso. Condivide finalmente la notte di Kristina. |
| Baldr | **Ritorno** | «Torna all'elicottero.» | Decolla con Ruben. È fuori, è salva. Ma il caffè, a Oslo, saprà di terra. E lei saprà perché. |
| Baldr | **Voce** | con almeno 7 ricordi | La Baldr le chiede la voce. Iselin resta sull'HRP, fuori; alla radio di Ruben risponde la piattaforma, con la voce di Iselin. |
| Dee | **Arrivo** | «Lasciati andare.» | Leif scende fino al fondale, accanto all'U-7920. Per la prima volta non insegue niente. |
| Dee | **Skarv** | «Risali. Odd ti aspetta.» | Torna sul peschereccio. La Dee si allontana, ma non scappa più: lo segue. |
| Dee | **Lancia** | con il ricordo di Trym e almeno 7 ricordi | Leif prende l'ultima lancia rimasta. La Madre lo porta verso sud, verso le luci di una piattaforma. È l'inizio del romanzo. |

## 6. Legami con il romanzo e con il sito

- **Baldr**: la Polaroid di «Gunther–o–come–si–chiamava», i cartellini con i nomi, le tovagliette-diario di Arianna, i cinque bicchieri, la conchiglia di gabbiani, il faldone rosso, la scritta «Madre» sul vetro, la chiavetta con Vivaldi, i candelotti.
- **Dee**: la busta marrone con gli ordini, il Retroscena, la vasca di coltura, le sbarre e la griglia, le percentuali di Fraser, gli schizzi del Sigillo (con le annotazioni a matita rossa del Dossier 04 del sito), le coordinate 73.25°N 29°E, la battaglia del 31 dicembre 1942, l'U-7920.
- **Incroci**: Leif ha parlato con Trym; nel finale «Lancia» la Dee manda la sua ultima lancia verso la Baldr; nel contatto della Baldr si intravede Egorov.

## 7. Incongruenze tra sito e romanzo (da decidere)

Il gioco segue il romanzo, ma evita le date esatte dove i due divergono:

- data della scomparsa: **22 ottobre 2022** (sito) / **dicembre 2022** (Trym nel romanzo);
- sigla RSS: *Royal Scientific Ship* (sito) / *Royal Research Ship* (romanzo);
- equipaggio: **30** (sito) / **35** (romanzo);
- il sito originale scomparso: **norvegese** (sito) / **svedese** (nota del romanzo).
