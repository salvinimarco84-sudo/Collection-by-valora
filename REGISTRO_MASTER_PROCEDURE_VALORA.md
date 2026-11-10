# Registro Master delle Procedure
## COLLECTION by VALORA

- **Versione:** 1.3
- **Ultima verifica del codice:** 10 novembre 2026
- **Repository:** `salvinimarco84-sudo/Collection-by-valora`
- **Branch verificato:** `main`
- **Ultimo commit del codice aggiornato:** `dff5366d46a1166abeb6c194b6fe65f99ecffa85` (CI e build della scomposizione VALORA in corso)
- **Fonte primaria del menu:** `lib/procedures/procedure_registry.dart`
- **Fonte primaria dei collegamenti UI:** `lib/dashboard/dashboard_home_coordinator.dart`

> Questo registro distingue ciò che è effettivamente presente nel codice, ciò che compare nel catalogo runtime e ciò che è soltanto progettato. La presenza di una voce UI o di un endpoint non equivale a collaudo funzionale end-to-end superato. Per PR-04 VALORA sono state verificate le run CI 663 (test/analyze/contract) e 1670 (build Android e Windows), entrambe concluse con esito SUCCESS; il test manuale end-to-end con salvataggio nel database TEST resta da eseguire.

## 1. Regole di lettura degli stati

| Stato | Significato |
|---|---|
| Presente nel menu | Voce registrata in `procedure_registry.dart` |
| Implementata nella UI | Esiste una pagina o un flusso collegato |
| Mapping runtime | È presente un codice API/runtime associato |
| Da collaudare | Il codice esiste, ma non è certificato qui con test end-to-end |
| Progettata/non collegata | Descritta o prevista, ma non attivata come procedura autonoma |
| Non presente nel menu | Non compare nell'attuale registro UI, anche se può esistere un contratto runtime |

## 2. Catalogo effettivo delle procedure

### A. Catalogo

| Codice | Nome effettivo | Collegamento / implementazione rilevata | Stato rilevato |
|---|---|---|---|
| PR-01 | Nuovo oggetto | `WRITE-PR-01`, procedura runtime dedicata | Presente nel menu; da collaudare |
| PR-02 | Modifica oggetto | `WRITE-PR-02`, procedura runtime dedicata | Presente nel menu; da collaudare |
| PR-03 | Chiudi oggetto | `WRITE-PR-03`, procedura runtime dedicata | Presente nel menu; da collaudare |

Funzioni aggiuntive di catalogo già presenti nel menu: Visualizza scheda, Elenco oggetti disponibili, Storico oggetto, Importa oggetti ed Esporta oggetti. Non ricevono un codice PR in questo registro perché sono identificate da codici funzionali dedicati.

### B. Acquisti

| Codice | Nome effettivo | Collegamento / implementazione rilevata | Stato rilevato |
|---|---|---|---|
| PR-04 | Nuovo acquisto ordinario | `WRITE-PR-04`, `NewPurchasePage` e moduli PR-04 | Presente nel menu; da collaudare |
| PR-04 VALORA | Nuovo acquisto semplificato da identificazione VALORA | `Pr04ValoraPurchasePage` e `pr04_valora_page.dart`; ingresso interno a VALORA, con modalità dedicata e runtime PR-04 condiviso | Maschera semplificata collegata; CI e build Android/Windows verdi; test end-to-end TEST da eseguire |
| PR-05 | Modifica acquisto | `WRITE-PR-05`, pagina modifica dedicata | Presente nel menu; da collaudare |

Funzioni correlate: Acquisti comparati e Report acquisti.

#### PR-04 VALORA · Nuovo acquisto da identificazione VALORA

PR-04 VALORA è una variante dedicata, avviata dal flusso VALORA e non come voce autonoma del menu principale. Serve a registrare l'acquisto di un oggetto non ancora presente nel catalogo, usando i dati identificativi confermati tramite PR-12 e l'eventuale valutazione ottenuta tramite PR-18.

Flusso previsto:
1. L'utente parte dall'assistente VALORA e fornisce foto, file o descrizione.
2. PR-12 identifica l'oggetto e cerca i metadati; l'utente seleziona e conferma il candidato.
3. PR-18 può stimare il valore di mercato, mostrando anche l'affidabilità e l'eventuale assenza di comparabili attendibili.
4. PR-04 VALORA apre `Pr04ValoraPurchasePage`, una maschera semplificata interna a VALORA, precompilata con metadati confermati e valore PR-18 distinto dal costo reale.
5. L'utente completa i soli dati di acquisto mancanti, controlla il riepilogo e conferma esplicitamente.
6. Il salvataggio passa attraverso le protezioni transazionali della procedura acquisti runtime; nessuna creazione automatica o scrittura diretta da PR-12/PR-18.

**Confine obbligatorio:** PR-04 VALORA non modifica né sostituisce PR-04 ordinaria. Deve riutilizzare i contratti e le protezioni di salvataggio già esistenti, ma avere presentazione e percorso semplificati autonomi. Non duplicare la logica transazionale.

**Stato codice aggiornato il 10/11/2026:** VALORA apre ora `Pr04ValoraPurchasePage` da `valora_service_page.dart`. La maschera dedicata mostra i metadati PR-12 confermati, mantiene distinto il valore di mercato PR-18 dal costo effettivo, richiede data/costo/destinazione e usa il riepilogo con conferma esplicita. La pagina riutilizza la modalità runtime PR-04 già esistente per lock, preview, save e rilettura post-salvataggio; la PR-04 ordinaria conserva la propria presentazione e il proprio percorso. La nuova copertura contrattuale è stata aggiunta a `test/runtime_contract_test.dart`. Stato aggiornato: implementazione collegata; CI run 663 SUCCESS (analisi, test automatici e contratti); build run 1670 SUCCESS (APK Android e applicazione Windows). Audit del codice: confermati precompilazione metadati, distinzione costo/valore, anteprima senza scrittura, conferma esplicita, lock e rilascio, rilettura post-salvataggio. Rimane da eseguire il collaudo manuale end-to-end nell'app collegata all'ambiente TEST, verificando il record effettivamente creato. Non dichiarare la procedura definitivamente chiusa prima di tale prova.


### C. Vendite e inserzioni

| Codice | Nome effettivo | Collegamento / implementazione rilevata | Stato rilevato |
|---|---|---|---|
| PR-06 | Nuova vendita | `WRITE-PR-06`, `NewSalePage` e moduli PR-06 | Presente nel menu; da collaudare |
| PR-07 | Modifica vendita | `WRITE-PR-07` compare nel catalogo/contratto runtime e nel dispatcher generico | Non presente come voce autonoma nell'attuale menu; da verificare |
| PR-08 | Chiudi vendita | `WRITE-PR-08`, pagina dedicata | Presente nel menu; da collaudare |
| PR-09 | Annulla vendita | `WRITE-PR-09`, pagina dedicata | Presente nel menu; da collaudare |
| PR-10 | Scambio | `WRITE-PR-10` compare nel catalogo/contratto runtime | Non presente come voce autonoma nell'attuale menu; da verificare |

**Vincolo architetturale:** PR-06 ordinaria resta il flusso standard di vendita. Il percorso VALORA deve richiamarla attraverso la propria pagina di ingresso, senza duplicare campi, validazioni, anteprima, blocco e salvataggio e senza alterare il pulsante di vendita ordinario.

### D. Ricerca e metadati

| Codice | Nome effettivo | Collegamento / implementazione rilevata | Stato rilevato |
|---|---|---|---|
| PR-12 | Ricerca metadati in lotti | `PR-12-BATCH`, `Pr12BatchPage`, motore `pr-12-engine-test` | Presente nel menu; flusso in sola lettura |

Caratteristiche rilevate nel codice:
- coda degli oggetti con metadati incompleti;
- elaborazione massima di 10 oggetti per lotto;
- selezione manuale o lotto automatico;
- ricerca singola e multipla;
- visualizzazione di risultati, fonti ed errori;
- nessuna scrittura dei metadati nel database da questa pagina.

### E. Motore VALORA e valutazioni

| Codice / voce | Nome effettivo | Collegamento / implementazione rilevata | Stato rilevato |
|---|---|---|---|
| PR-18 | VALORA | Voce menu `LAUNCH-VALORA`, `ValoraServicePage`; funzione di valutazione `pr-18-valuation-test` richiamata nel flusso di identificazione | Presente nel menu e collegata; collaudo end-to-end da verificare |
| PR-19 | Nessuna voce autonoma rilevata | Non identificata nell'attuale `procedure_registry.dart` | Da definire/allineare; non dichiararla implementata |
| PR-20 | Valuta acquisto | Voce descrittiva presente ma `enabled: false`, senza codice API associato | Progettata/non attiva |
| PR-21 | Valutazione complessiva collezione | `LAUNCH-COLLECTION-VALUE`, `CollectionValuePage` e relativa presentazione | Presente nel menu e collegata; collaudo end-to-end da verificare |

**Distinzione funzionale:**
- PR-12 ricerca e restituisce metadati e candidati.
- PR-18 è la procedura di valutazione specialistica del singolo oggetto.
- PR-20 dovrà valutare la convenienza di un acquisto e non va confusa con la valutazione patrimoniale.
- PR-21 riguarda il valore complessivo della collezione e lo storico delle fotografie patrimoniali.

**Ingresso PR-06 VALORA:** `Pr06ValoraPage` è un ingresso guidato alla `NewSalePage` standard, con oggetto e prezzo iniziale precompilati. Non è una nuova procedura di vendita indipendente e non deve sostituire PR-06.

### F. Report e consultazioni

| Funzione | Codice UI/runtime rilevato | Stato rilevato |
|---|---|---|
| Report acquisti | `REPORT-PURCHASES` | Presente |
| Report vendite attive | `REPORT-ACTIVE-LISTINGS` | Presente |
| Report vendite | `REPORT-SALES` | Presente |
| Flussi di cassa | `REPORT-CASH` | Presente |
| Report per franchise/tema | `REPORT-COLLECTION-THEME` | Presente |
| Report mattutino | Nessun codice, voce disabilitata | Non attivo |

I report non vengono numerati come PR: sono consultazioni/report e usano codici funzionali dedicati.

## 3. Altre funzioni di menu rilevate

| Area | Funzione | Codice UI | Stato |
|---|---|---|---|
| Ricerche | Ricerca oggetti | `READ-EXPLORE-RECORDS` | Presente |
| Ricerche | Registro fonti | `SOURCE-REGISTRY` | Presente |
| Ricerche | Piattaforme di vendita utente | `USER-SALES-PLATFORMS` | Presente |
| Controllo | Stato runtime | `RUNTIME-HEALTH` | Presente |
| Controllo | Catalogo API | `RUNTIME-CATALOG` | Presente |
| Controllo | Crea categoria collezione | `CREATE-COLLECTION-CATEGORY` | Presente |
| Controllo | Modifica categoria collezione | `EDIT-COLLECTION-CATEGORY` | Presente |

## 4. Correzioni rispetto al registro preliminare

1. PR-03 è **Chiudi oggetto**, non Consultazione oggetti.
2. PR-07 è **Modifica vendita** nel contratto runtime, ma non è una voce autonoma nell'attuale menu.
3. PR-10 è **Scambio** nel contratto runtime, ma non è una voce autonoma nell'attuale menu.
4. PR-18 è la voce menu **VALORA**.
5. PR-19 non risulta registrata come procedura autonoma nel menu attuale.
6. PR-20 è soltanto una voce disabilitata, senza API collegata.
7. PR-21 è **Valutazione complessiva collezione**.
8. PR-06 VALORA è un ingresso dedicato che riutilizza PR-06 ordinaria, non una seconda implementazione della vendita.
9. Consultazioni e report non devono essere inventati come codici PR.

## 5. Regole obbligatorie di sviluppo

- Non modificare il database di produzione durante sviluppo e collaudo.
- Usare l'ambiente TEST autorizzato.
- Non sostituire o duplicare procedure già esistenti: riutilizzare i servizi condivisi.
- Separare pagina, presentazione, stato, logica e accesso ai dati quando si scompone una procedura.
- Conservare fotocamera, galleria, file allegati e callback già funzionanti durante la scomposizione di VALORA.
- Ogni scrittura deve rispettare preview, review, conferma esplicita, save e rilettura di verifica.
- Non considerare una run verde come prova sufficiente di completamento funzionale.
- Non dichiarare una procedura completata senza test automatici, test funzionali, verifica del salvataggio e regressioni sulle procedure collegate.

## 6. Scheda obbligatoria per ogni procedura

Per ogni procedura mantenere questi campi:
- codice e nome ufficiale;
- area/menu;
- pagina di ingresso;
- file UI/presentazione;
- file stato e logica;
- API/Edge Function/runtime utilizzati;
- dipendenze e procedure richiamate;
- ambiente di test;
- run CI e relativo esito;
- test funzionali eseguiti;
- regressioni verificate;
- stato finale e data dell'ultima verifica.

## 7. Registro avanzamento

| Codice | Stato codice | Test automatici | Test funzionali | Regressioni | Ultima run | Stato finale |
|---|---|---|---|---|---|---|
| PR-01 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-02 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-03 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-04 | Presente; da collaudare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-04 VALORA | Pagina dedicata collegata da VALORA; runtime PR-04 condiviso | CI 663 SUCCESS | Manuale end-to-end TEST da eseguire | Regressione PR-04 ordinaria da provare nell'app | Build 1670 SUCCESS (Android/Windows) | Aperta, collaudo manuale pendente |
| PR-05 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-06 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-07 | Mapping runtime; UI da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-08 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-09 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-10 | Mapping runtime; UI da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-12 | Presente, sola lettura | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-18 | Presente e collegata | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
| PR-19 | Non registrata | N/A | N/A | N/A | N/A | Da definire |
| PR-20 | Disabilitata | N/A | N/A | N/A | N/A | Da sviluppare |
| PR-21 | Presente e collegata | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |

## 8. Regola di aggiornamento del registro

Ogni modifica al codice che aggiunge, rimuove, rinomina, divide, accorpa o collega una procedura deve aggiornare questo documento nello stesso intervento. Prima di iniziare un nuovo blocco di sviluppo, verificare il registro e indicare chiaramente la procedura interessata e le sue dipendenze.


## 9. Scomposizione tecnica progressiva di VALORA

La scomposizione è in corso. I moduli seguenti sono stati estratti dal precedente blocco monolitico di `ValoraServicePage`; la pagina conserva il coordinamento dello stato e i collegamenti, mentre le responsabilità specifiche sono delegate alle estensioni dedicate.

| Modulo | Responsabilità estratta | Stato |
|---|---|---|
| `valora_photo_input_presentation.dart` | Fotocamera, galleria, selezione multipla, allegati immagine, rimozione e presentazione della sezione foto/file | Estratto; callback originali mantenuti |
| `valora_photo_search_controller.dart` | Analisi bytes immagine tramite PR-12, avvio ricerca, conferma candidato e ricerca estesa con esclusione di URL/query già esaminati | Estratto |
| `valora_catalog_intake_controller.dart` | Ingresso da candidato confermato, preparazione metadati, richiesta PR-18 e passaggio alla maschera PR-04 VALORA | Estratto |
| `valora_known_object_valuation_controller.dart` | Valutazione PR-18 di oggetti già presenti, salvataggio valutazione/storico e scelta tra sola valutazione e passaggio a PR-06 VALORA | Estratto |
| `valora_service_page.dart` | Coordinamento pagina, stato, caricamento oggetti e avvio vendita | Ancora da scomporre |
| `valora_service_presentation.dart` | Presentazione generale dell'assistente VALORA e ricerca nella collezione | Separazione UI già presente; ulteriori componenti da valutare |

### Regole di separazione mantenute

- PR-04 ordinaria e PR-06 ordinaria non vengono sostituite o riscritte.
- PR-04 VALORA e PR-06 VALORA restano ingressi dedicati che riutilizzano i rispettivi runtime standard.
- La fotocamera, la galleria, i file allegati e i callback esistenti restano disponibili.
- PR-12 identifica e propone candidati; PR-18 valuta; la creazione passa soltanto dalla conferma esplicita in PR-04 VALORA.
- La vendita di un oggetto già in collezione resta un flusso distinto dalla valutazione.
- Non vengono introdotte scritture nel database di produzione.

### Verifiche della scomposizione

Sono stati aggiunti contratti automatici per verificare la registrazione dei nuovi moduli, il mantenimento dei callback e la collocazione delle responsabilità estratte. Le prime run hanno segnalato riferimenti di test rimasti nei file precedenti dopo lo spostamento dei metodi; tali riferimenti sono stati riallineati ai nuovi moduli nel commit `dff5366d46a1166abeb6c194b6fe65f99ecffa85`.

**Stato CI/build:** run CI 684 e build 1691, riferite al commit `dff5366d46a1166abeb6c194b6fe65f99ecffa85`, in attesa di esecuzione al momento dell'aggiornamento. Non dichiarare verdi né chiudere questa fase finché le run non terminano con successo.

### Prossimi blocchi della scomposizione

1. Separare il caricamento e la lettura degli oggetti dal coordinatore della pagina.
2. Separare il flusso di avvio vendita degli oggetti già presenti, senza toccare PR-06 standard.
3. Ridurre `valora_service_page.dart` al coordinamento e allo stato essenziale.
4. Verificare i collegamenti UI e i test di regressione di PR-04 VALORA, PR-06 VALORA, PR-12 e PR-18.
