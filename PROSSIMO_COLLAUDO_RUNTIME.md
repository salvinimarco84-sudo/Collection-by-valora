# Checklist per attivare le API candidate

Questa versione rende visibile la distinzione fra mapping candidato e voce non allineata. Non chiama il runtime.

## Regole obbligatorie prima di collegare una procedura di scrittura
1. Leggere il contratto `contratto_input` aggiornato dal catalogo runtime.
2. Verificare autenticazione, allowlist e ambiente TEST.
3. Verificare l'acquisizione del blocco esclusivo e il suo rilascio in caso di errore.
4. Preparare la bozza senza scrittura; consentire modifiche e inserimenti multipli dove il contratto dichiara `supporta_batch=true`.
5. Mostrare il riepilogo completo e chiedere conferma esplicita.
6. Salvare solo dopo la conferma finale dell'intero batch.
7. Rileggere dal database ogni record scritto e confrontarlo con il riepilogo confermato.
8. Segnalare chiaramente fallimenti e record non verificati; non mostrare esito positivo se la rilettura fallisce.

## Mapping candidati di questa versione
- `WRITE-PR-01`: Nuovo oggetto
- `WRITE-PR-02`: Modifica oggetto
- `READ-OBJECT-MASTER`: Visualizza scheda
- `READ-EXPLORE-RECORDS`: Ricerca oggetti
- `READ-OBJECTS-AVAILABLE`: Elenco catalogo
- `READ-VALUATION-PREPARE`: preparazione consultiva valutazione, non valutazione di mercato completata
- `WRITE-PR-04`: Nuovo acquisto
- `WRITE-PR-05`: Modifica acquisto
- `REPORT-PURCHASES`: Elenco/Report acquisti, soltanto lettura
- `WRITE-PR-06`: Nuova vendita
- `REPORT-ACTIVE-LISTINGS`: Inserzioni attive, soltanto lettura
- `REPORT-SALES`: Report vendite, soltanto lettura
- `REPORT-CASH`: Flussi di cassa, soltanto lettura
- `RUNTIME-CATALOG`: Gestione/consultazione catalogo runtime
- `RUNTIME-HEALTH`: Stato runtime

## Voci non attivabili
Nuove/modifica/chiusura inserzioni, vendita multipla Vinted, giroconto, saldi, report spese, comparazioni, opportunità, report mattutino, ricerca #DEMONOFLU, pulizia file e collaudo end-to-end non hanno un mapping certo in questo snapshot. Non inventare API sostitutive.

## Stato
Snapshot letto in sola lettura da Supabase TEST il 13/10/2026. Tutte le API sono `API_IMPLEMENTATA_DA_COLLAUDARE`. La compilazione Flutter e l'esecuzione dei widget test devono essere svolte in un ambiente con Flutter SDK; non sono state eseguite qui.
