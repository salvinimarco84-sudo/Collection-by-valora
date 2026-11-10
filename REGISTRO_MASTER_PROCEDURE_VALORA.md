# Registro Master delle Procedure
## COLLECTION by VALORA

- **Versione:** 1.1
- **Ultima verifica del codice:** 10 novembre 2026
- **Repository:** `salvinimarco84-sudo/Collection-by-valora`
- **Branch verificato:** `main`
- **Commit di riferimento:** `81a0a8de1c660fc1b52e19c14c74745a33056c5e`
- **Fonte primaria del menu:** `lib/procedures/procedure_registry.dart`
- **Fonte primaria dei collegamenti UI:** `lib/dashboard/dashboard_home_coordinator.dart`

> Questo registro distingue ciò che è effettivamente presente nel codice, ciò che compare nel catalogo runtime e ciò che è soltanto progettato. La presenza di una voce UI o di un endpoint non equivale a collaudo funzionale superato. Nessun test CI è stato eseguito durante questa verifica.

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
| PR-04 | Nuovo acquisto | `WRITE-PR-04`, pagina acquisto dedicata | Presente nel menu; da collaudare |
| PR-05 | Modifica acquisto | `WRITE-PR-05`, pagina modifica dedicata | Presente nel menu; da collaudare |

Funzioni correlate: Acquisti comparati e Report acquisti.

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
| PR-04 | Da verificare | Da verificare | Da verificare | Da verificare | Da registrare | Aperta |
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
