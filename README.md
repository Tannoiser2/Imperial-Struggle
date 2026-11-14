# Imperial Struggle - versione digitale

Adattamento digitale per uso personale di **Imperial Struggle** di Ananda Gupta e Jason Matthews (GMT Games,
2a ristampa), fatto in Godot 4.7 per la ludoteca: https://tannoiser2.github.io/

Si gioca qui: https://tannoiser2.github.io/Imperial-Struggle/

## Cosa c'è

- **Regole complete della 2a ristampa**: sei turni di Pace e quattro guerre (Successione Spagnola, Successione
  Austriaca, Sette Anni, Indipendenza Americana); tessere Investimento con Azione Maggiore e Minore, Eventi,
  Migliorie militari; Punti Economici, Diplomatici e Militari con costi, collegamenti, Mercati isolati e protetti,
  supplemento per la seconda Regione; Debito e Punti Trattato come punti jolly; Squadre, Forti (costruzione, danni,
  riparazione, cattura dei Forti danneggiati), Conflitti; Premi regionali, Prestigio, Domanda Globale; Vantaggi;
  guerre con tessere Base e Bonus, forza Bonus, bottino, Punti Conquista, linee di conquista, cessioni rifiutate,
  Vittoria e Sconfitta giacobita, Dominio dell'Atlantico, nascita degli Stati Uniti; punteggio finale e vittorie
  automatiche. Compresa l'azione «pesca un Evento con 3 PD» delle correzioni ufficiali.
- **Tutte le carte in italiano con la grafica originale**: i 41 Eventi (con le versioni aggiornate) e i 26
  Ministeri sono le carte del modulo, con il testo inglese sostituito da quello italiano (`tools/carte.py`:
  ricostruisce la pergamena sotto il testo e riscrive con Besley e Libre Caslon, simili ai caratteri originali).
  Tessere, mappa e segnalini dal modulo Tabletop Simulator.
- **Componenti originali**: tutti i pezzi sono ritagliati con la loro sagoma vera (esagoni per Squadre, tessere
  Guerra, Conflitti e danni ai Forti; quadrati arrotondati per bandiere e segnalini). Sulla mappa ci sono le
  tessere Vantaggio e Premio, i segnalini di PV, Debito, Limite e Trattati, turno, Iniziativa, Ugonotti e giacobiti.
  Le guerre si vedono sulle **schede originali**, con le tessere Guerra nei riquadri blu e rossi di ogni teatro
  (`scripts/scheda_guerra.gd`): le tue scoperte, quelle dell'avversario coperte fino alla risoluzione.
- **IA** per la Francia o per la Gran Bretagna: sceglie tessere Investimento, Eventi e Ministeri, cerca alleanze
  per la prossima guerra, contende Premi e Domanda Globale, dosa Debito e Trattati. Non guarda le tessere e le
  carte coperte dell'avversario. Nel diario lascia brevi «dispacci» sulle sue intenzioni.
- **Online in due** (stanze con codice di 4 lettere su Firebase) e **salvataggio** della partita contro l'IA sul
  dispositivo e su Firebase. Due giocatori anche sullo stesso dispositivo.
- Mappa che si sposta trascinando (mouse o un dito) e si ingrandisce con la rotella o pizzicando con due dita.
- Schermo: Gran Bretagna a sinistra e Francia a destra (con i Premi che ciascuna sta vincendo), in alto le fasi
  del turno con quella in corso in evidenza e le azioni possibili, in basso il diario. Tessere Investimento,
  carte, guerra, Ministeri e diario si aprono in riquadri quando servono o con i pulsanti in alto.
- Interfaccia a tema Settecento con font IM Fell (titoli) ed EB Garamond (testi).

## Scelte e semplificazioni

- I Ministeri si rivelano da soli quando servono (abilità, parola chiave di un Evento) e, all'ultimo Round del
  turno, quelli utili al punteggio o alla guerra imminente; si possono anche rivelare a mano.
- I Vantaggi che riducono un costo valgono per il primo acquisto adatto dopo l'attivazione.
- I bonus di alcuni Ministeri (Cardinali ministri, Choiseul, Pitt, Papato-Hannover, Burke, Banca d'Inghilterra)
  si applicano al primo Round utile del turno.
- Alla nascita degli Stati Uniti le bandiere americane vanno automaticamente dove convengono alla Francia.
- Le linee di conquista e alcuni collegamenti sono stati letti dalla mappa: stanno in `tools/collegamenti.txt`,
  facile da correggere (poi `python3 tools/estrai.py <cartella Mods> .`).
- Regole opzionali (Impero spagnolo, Pianificazione militare, Forti più tosti) non incluse.

## Struttura

- `scripts/motore.gd` - le regole: tutto lo stato in un dizionario, una decisione alla volta con opzioni numerate
  (stessa sequenza = stessa partita: serve a online, salvataggi e IA).
- `scripts/ia.gd` - l'intelligenza artificiale (prova le opzioni su una copia e valuta la posizione).
- `scripts/dati.gd` - Eventi, Ministeri, guerre, Vantaggi, premi (testi in italiano).
- `scripts/dati_gen.gd` - spazi, collegamenti e tessere, generati da `tools/estrai.py` dal modulo TTS.
- `scripts/plancia.gd` - la mappa; `scripts/main.gd` - menu e interfaccia; `scripts/rete.gd` - Firebase.
- Firebase: radice `imperialstruggle` (stanze con registro e salvataggi), coperta dalla regola comune del progetto.

## Prove

```
godot --headless --path . -s res://tests/sim.gd -- 300 caso 1     # 300 partite a caso
godot --headless --path . -s res://tests/sim.gd -- 20 ia 1        # 20 partite IA contro IA
godot --headless --path . -s res://tests/salva.gd                 # salvataggio e ricaricamento
GODOT=godot tests/prova_online.sh                                 # partita online sul finto Firebase
IS_PROVA=ia,13 IS_FOTO=/tmp/foto.png xvfb-run godot --path .      # screenshot dell'interfaccia
python3 tools/controlla_glifi.py
```

## Pubblicazione

Il workflow `Pubblica` parte a mano (Actions -> Pubblica -> Run workflow) oppure con un commit che contiene
`[pubblica]`. Pubblica su GitHub Pages e, se ci sono i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID`,
anche sulla ludoteca privata (`imperialstruggle.ludoteca-digitale.com`).
