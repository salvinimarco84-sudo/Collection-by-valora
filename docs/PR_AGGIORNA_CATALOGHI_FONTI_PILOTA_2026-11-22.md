# PR AGGIORNA CATALOGHI - Ricognizione fonti pilota
Data: 2026-11-22

Questa ricognizione identifica possibili canali dati, ma NON abilita fonti e NON autorizza scraping automatico. Ogni integrazione resta subordinata a verifica dei termini d'uso, robots/accesso, licenza dei dati, limiti di frequenza e disponibilità di identificativi stabili.

## LEGO
- Il sito LEGO non espone, sulla base delle fonti consultate, un portale pubblico di API developer.
- Rebrickable espone una API v3 con catalogo LEGO di set, parti e minifigure; richiede una API key. La documentazione avverte di sovraccarico e suggerisce i CSV di download per importazioni massive.
- Candidato tecnico: import batch da CSV ufficiali Rebrickable, oppure API a basso volume dopo verifica dei termini e ottenimento di una chiave autorizzata.
- Non attivare la fonte finché non sono valutate licenza/attribuzione e corrispondenza del modello dati VALORA.
Riferimenti:
- https://rebrickable.com/api/v3/docs/
- https://rebrickable.com/api/

## TAMASHII NATIONS / SOUL OF CHOGOKIN / SAINT SEIYA
- TAMASHII WEB è un catalogo ufficiale navigabile con ricerca prodotti, linee, preordini e date di uscita.
- La ricognizione web non ha confermato un'API pubblica documentata.
- Candidato tecnico: adapter HTML solo dopo verifica esplicita di condizioni d'uso e robots, oppure feed/catalogo ufficiale autorizzato dal titolare.
Riferimenti:
- https://tamashiiweb.com/
- https://tamashiiweb.com/item_brand/robot_tamashii/

## MATTEL / BARBIE / HOT WHEELS
- Il Customer Center ufficiale Mattel espone risultati prodotto ricercabili e codici articolo, con paginazione.
- La ricognizione non ha confermato un'API pubblica documentata né il permesso di raccolta automatica.
- Candidato tecnico: richiedere feed/endpoint autorizzato oppure verificare condizioni e robots prima di un adapter read-only con rate limit e cache.
Riferimenti:
- https://service.mattel.com/us/results.aspx?N=4294967196&Ntt=Hot+wheels&tab=Product
- https://service.mattel.com/us/results.aspx?N=4294967241&Ntt=barbie

## Decisione operativa
Nessuna fonte viene attivata in TEST2 in questa fase. Il prossimo sviluppo corretto è un adapter pilota isolato e read-only, inizialmente LEGO tramite CSV/API autorizzata, con staging esclusivo in pr_cataloghi_proposte, senza scrittura diretta nei master e senza gestione immagini.
