# Allineamento interfaccia ↔ catalogo API ufficiale

Snapshot in sola lettura del progetto Supabase TEST `eeiekkflpnkummxtvljy`, tabella `collection.runtime_catalogo_api`, rilevato il 13/10/2026.

**Importante:** tutte le 43 API risultano `API_IMPLEMENTATA_DA_COLLAUDARE`. Il mapping identifica solo il contratto candidato per la voce UI, non certifica il runtime né autorizza a invocarlo. Per operazioni senza corrispondenza esatta, non è stato inventato un codice.

| Voce UI | API candidata | Stato mapping |
|---|---|---|
| Nuovo oggetto | `WRITE-PR-01` | Corrispondenza candidata, da validare col contratto input |
| Modifica oggetto | `WRITE-PR-02` | Corrispondenza candidata, da validare col contratto input |
| Visualizza scheda | `READ-OBJECT-MASTER` | Corrispondenza candidata, da validare col contratto input |
| Ricerca oggetti | `READ-EXPLORE-RECORDS` | Corrispondenza candidata, da validare col contratto input |
| Elenco catalogo | `READ-OBJECTS-AVAILABLE` | Corrispondenza candidata, da validare col contratto input |
| Valore di mercato | `READ-VALUATION-PREPARE` | Corrispondenza candidata, da validare col contratto input |
| Nuovo acquisto | `WRITE-PR-04` | Corrispondenza candidata, da validare col contratto input |
| Modifica acquisto | `WRITE-PR-05` | Corrispondenza candidata, da validare col contratto input |
| Elenco acquisti | `REPORT-PURCHASES` | Corrispondenza candidata, da validare col contratto input |
| Report acquisti | `REPORT-PURCHASES` | Corrispondenza candidata, da validare col contratto input |
| Acquisti comparati | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Nuova inserzione | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Modifica inserzione | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Chiudi inserzione | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Nuova vendita | `WRITE-PR-06` | Corrispondenza candidata, da validare col contratto input |
| Vendita multipla Vinted | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Inserzioni attive | `REPORT-ACTIVE-LISTINGS` | Corrispondenza candidata, da validare col contratto input |
| Report vendite | `REPORT-SALES` | Corrispondenza candidata, da validare col contratto input |
| Vendite comparate | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Nuovo movimento extra | Nessuna corrispondenza certa | Da allineare prima di attivare la voce; `REPORT-CASH` è sola lettura e non è adatta a una scrittura |
| Giroconto | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Mostra saldi | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Flussi di cassa | `REPORT-CASH` | Corrispondenza candidata, da validare col contratto input |
| Report spese | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Valuta oggetto | `READ-VALUATION-PREPARE` | Corrispondenza candidata, da validare col contratto input |
| Valuta più oggetti | `READ-VALUATION-PREPARE` | Corrispondenza candidata, da validare col contratto input |
| Opportunità di acquisto | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Report opportunità | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Report mattutino | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Report vendite | `REPORT-SALES` | Corrispondenza candidata, da validare col contratto input |
| Report acquisti | `REPORT-PURCHASES` | Corrispondenza candidata, da validare col contratto input |
| Report spese | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Vendite | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Vendite comparate | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Acquisti | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Acquisti comparati | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Ricerca oggetti | `READ-EXPLORE-RECORDS` | Corrispondenza candidata, da validare col contratto input |
| Ricerca #DEMONOFLU | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Gestione procedure | `RUNTIME-CATALOG` | Corrispondenza candidata, da validare col contratto input |
| Stato database | `RUNTIME-HEALTH` | Corrispondenza candidata, da validare col contratto input |
| Collaudo runtime | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |
| Pulizia file | Nessuna corrispondenza certa | Da allineare prima di attivare la voce |

## Contratti di scrittura identificati

| API | Procedura catalogata | Descrizione ufficiale | Batch |
|---|---|---|---|
| `EXIT-DATE-OUT` | `CMD-DATA-OUT` | Ricerca e aggiornamento assistito della data di prima commercializzazione | No |
| `EXIT-PRICE-OUT` | `CMD-PRICE-OUT` | Ricerca e aggiornamento assistito del prezzo ufficiale di lancio | No |
| `WRITE-COLLECTION-MERGE` | `PR04-ACCORPA-COLLEZ` | Accorpamento atomico di più oggetti in un nuovo oggetto | Sì |
| `WRITE-PLATFORM-MANAGEMENT` | `GESTIONE PIATTAFORME` | Inserimento e modifica piattaforme con conferma batch | Sì |
| `WRITE-PR-01` | `PR-01` | Nuovo oggetto | Sì |
| `WRITE-PR-02` | `PR-02` | Modifica oggetto | Sì |
| `WRITE-PR-03` | `PR-03` | Chiudi oggetto | Sì |
| `WRITE-PR-04` | `PR-04` | Nuovo acquisto | Sì |
| `WRITE-PR-05` | `PR-05` | Modifica acquisto | Sì |
| `WRITE-PR-06` | `PR-06` | Nuova vendita | Sì |
| `WRITE-PR-07` | `PR-07` | Modifica vendita | Sì |
| `WRITE-PR-08` | `PR-08` | Chiudi vendita | Sì |
| `WRITE-PR-09` | `PR-09` | Annulla vendita | Sì |
| `WRITE-PR-10` | `PR-10` | Scambio | Sì |

## Vincoli applicati

- Nessuna chiamata di scrittura è stata eseguita.
- Nessuna modifica al database TEST o produzione.
- Non usare i codici `PR-04`…`PR-10` come equivalenti automatici alle vecchie procedure ricordate: il mapping deriva esclusivamente dal catalogo runtime letto ora.
- Prima del collegamento UI occorre verificare `contratto_input`, autenticazione/allowlist, blocco esclusivo, preview/review/save, batch e rilettura post-scrittura.
- La UI deve mantenere le voci non mappate disabilitate o chiaramente in stato “da collegare”, non fingere di eseguirle.
