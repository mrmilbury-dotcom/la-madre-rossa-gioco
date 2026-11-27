# Emissari

*Un'esplorazione testuale da «La madre rossa» di Maico Morellini (Agenzia Alcatraz, 2026).*

Due linee di gioco, una scelta all'inizio:

- **La Piattaforma Baldr** — Iselin, l'amica di Kristina, sale sulla piattaforma sette settimane dopo la scomparsa dei cinque.
- **La RSS Arthur Dee** — Leif Aamodt, che nel 2022 inseguì la nave dalla baleniera *Willow*, la ritrova nel Mare di Barents.

Niente enigmi, niente mappa: si esplora, si esamina, si ascolta. Più ascolti, più l'emissario ti sente. Poi arriva la Madre.

## Attivare la pubblicazione automatica (una volta sola)

1. **Add file → Create new file**, come nome scrivi `.github/workflows/pubblica.yml`, incolla dentro il contenuto di `strumenti/pubblica.yml`, poi **Commit changes**.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**.

Da quel momento ogni modifica al ramo `main` viene verificata e pubblicata su GitHub Pages
(scheda **Actions** per vedere l'esito). Per incorporarlo nel sito:

```html
<iframe src="https://mrmilbury-dotcom.github.io/la-madre-rossa-gioco/"
        style="width:100%;height:85vh;border:0" allow="autoplay; fullscreen"></iframe>
```

## Per chi scrive

- **`GUIDA_AI_TESTI.md`** — come modificare i testi (anche direttamente dal sito di GitHub).
- **`docs/BIBBIA_NARRATIVA.md`** — personaggi, mappe, meccaniche, finali, legami con il romanzo.
- I testi sono in `storia/baldr/` e `storia/dee/`.

## Per chi programma

Godot 4.7 (GDScript, renderer Compatibility, export Web senza thread).

| File | Cosa fa |
|---|---|
| `scripts/storia.gd` | legge e controlla i file di testo |
| `scripts/motore.gd` | regole del gioco: stanze, oggetti, ascolto, risonanza, eventi |
| `scripts/stato.gd` | stato della partita, salvataggio JSON |
| `scripts/comandi.gd` | interpreta i comandi scritti («esamina la polaroid») |
| `scripts/main.gd` | interfaccia, scala per telefono/desktop, salvataggi |
| `scripts/suono.gd` | sottofondo sintetizzato in tempo reale |
| `shaders/sfondo.gdshader` | mare, nebbia e la rete rossa che cresce con la risonanza |
| `tests/verifica.gd` | verifica automatica: errori di formato e 500 partite simulate per linea |

```bash
bash strumenti/scarica_font.sh                           # i font non sono nel repository
godot --headless --import
godot --headless --script res://tests/verifica.gd      # verifica i testi
godot --headless --export-release "Web" build/web/index.html
```

Font: Cormorant Garamond e IBM Plex Mono, licenza SIL Open Font License.
