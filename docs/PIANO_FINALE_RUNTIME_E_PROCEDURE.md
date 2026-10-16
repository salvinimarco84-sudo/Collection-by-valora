# COLLECTION by VALORA | Piano finale runtime e procedure
Data: 13 ottobre 2026 | Ambiente esclusivo: TEST `eeiekkflpnkummxtvljy`

## Verifica effettuata
Confrontati sorgente Flutter `lib/main.dart` e Edge Function attiva `collection-procedure-runtime-test`, deployment 14, contratto API v8. Il sorgente Flutter corrente NON è compatibile con il contratto v8: non trasmette `session_id` e `request_id`, non acquisisce né mantiene il blocco esclusivo e non dispone di coda SQLite. Non compilare o distribuire come beta funzionante finché non risolto.

## Priorità tecnica 1: compatibilità client/server
- Conservare un `session_id` UUID stabile per installazione/sessione di lavoro, con regole esplicite di ripristino dopo riavvio.
- Per ogni salvataggio generare e conservare un `request_id` UUID fino a risposta verificata, riutilizzandolo in ogni retry; mai generare un nuovo ID per ripetere la stessa operazione.
- Richiedere `acquire_lock` prima di entrare in modifica; controllare `acquisito=true`; heartbeat durante lavoro; `release_lock` solo a condizioni sicure.
- Allineare richieste `preview`, `review`, `save` al contratto API v8; per consultazioni usare `action=consultation`, per report `action=report`.
- Non confermare operazioni in base al solo codice HTTP: richiedere esito della procedura e verifica post-scrittura.
- Vietare risoluzione fuzzy dei comandi: codice/alias ufficiale esatto, senza substring matching.

## Priorità tecnica 2: offline e ripresa
- SQLite locale conserva bozze e operazioni confermate ma non ancora sincronizzate, non rappresenta il database ufficiale.
- Coda FIFO persistente, con payload immutabile, request_id, session_id, data di creazione, stato e ultimo errore.
- Prima di mettere in coda una scrittura confermata, verificare lo stato del blocco e notificare `queue_pending=true` quando connessi.
- Se il client perde la connessione prima di notificare al server la coda, non assumere di possedere il blocco: bloccare nuove modifiche fino a riconciliazione esplicita.
- Al ritorno della rete, eseguire `sync_operation` in ordine; controllare idempotenza e rilettura dei record; solo dopo svuotamento verificato usare `queue_pending=false` e rilasciare il blocco.
- Conflitti, blocchi orfani, cambio dispositivo, logout e disinstallazione con coda non vuota richiedono percorsi espliciti; mai scartare la coda in silenzio.

## Priorità tecnica 3: procedure ancora da definire insieme
1. `CMD-DATA-OUT`: selezione oggetto/vendita, data di uscita proposta o immessa, fonte, conferma e conseguenze su storico e contabilità.
2. `CMD-PRICE-OUT`: prezzo realizzato, commissioni, spedizioni, valuta, sconti, piattaforma, flussi di cassa, rettifiche.
3. `CMD-DATE-PRICE-OUT`: ordine delle due operazioni, comportamento atomico, riconciliazione con vendita già chiusa.
4. `EXIT-DATE-PRICE-FLOW`: fonti esterne ammesse, comparabili verificati, cosa si propone e cosa NON si applica senza conferma.
5. Recupero offline e conflitti: scenari pratici e scelta dell'operatore in caso di modifica concorrente o coda irrecuperabile.
6. Maschere e interazione: ordine dei campi, elenco record completo, lettura dei campi vuoti, singolo/multiplo, conferma e nuova operazione, input touch/testo/voce.

## Regola universale già definita
Bozza -> controllo/riepilogo senza scrittura -> conferma dati -> domanda «Vuoi fare un'altra operazione?» -> SÌ: ritorno alla bozza e aggiunta record -> NO: riepilogo finale -> conferma definitiva -> scrittura atomica -> rilettura -> chiusura. Una procedura non deve salvare parzialmente il lotto prima del NO e della conferma definitiva.

## Criteri di accettazione prima della beta
- Zero accessi alla produzione.
- Account TEST autorizzato esplicitamente; oggi non ancora autorizzato.
- Test singolo/multiplo e casi limite per tutte le procedure.
- Nessuna scrittura nelle fasi preview/review.
- Idempotenza con retry e timeout simulati.
- Offline/online, chiusura forzata, riavvio, conflitto e blocco esclusivo verificati su Android e Windows.
- Rilettura dopo ogni scrittura e confronti con registro storico e saldi.
- `flutter analyze`, `flutter test`, compilazioni e prove reali documentate.

## Stato
Questo file è un piano tecnico, non una dichiarazione di implementazione o di collaudo dell'app. Backend SQL parzialmente collaudato; test end-to-end app non ancora effettuati.
