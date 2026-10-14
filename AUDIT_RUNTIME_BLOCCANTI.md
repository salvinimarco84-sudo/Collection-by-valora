# Audit runtime e piano di integrazione - COLLECTION by VALORA v4

Data audit: 13/10/2026
Ambiente esaminato: Supabase TEST `eeiekkflpnkummxtvljy`
Edge Function esaminata in sola lettura: `collection-procedure-runtime-test`, versione 16
Produzione: non consultata e non modificata.

## Esito sintetico

Il runtime esiste ed è attivo nel progetto TEST, ma la sua integrazione con il client non è ancora pronta per essere dichiarata collaudata. Non è stato eseguito alcun test HTTP autenticato end-to-end e non è stata eseguita alcuna scrittura.

## Rilievi bloccanti prima di collegare l'app

1. **Nessun account beta autorizzato.** La tabella `collection.app_authorized_users` risulta vuota. L'Edge Function rifiuta correttamente gli utenti che non sono nell'allowlist. Non aggiungere account senza autorizzazione esplicita.
2. **Versione 16 presenta un'interfaccia HTML servita dalla Edge Function**, oltre a gestire chiamate JSON. Non equivale a un client Flutter integrato.
3. **Contratto HTTP non uniforme.** I percorsi di consultazione/report, sessione, sincronizzazione, dati di uscita e procedure usano forme diverse del body. Il client deve implementare ciascun contratto esattamente e non dedurre la forma dalle sole descrizioni.
4. **Percorso `preview/review/save` non uniforme per tutte le procedure.** Per alcune procedure preview/review viene invocata direttamente una RPC specifica, mentre save passa da `runtime_esegui_procedura_con_blocco`. Le semantiche di preview/review/save devono essere testate e documentate per ciascuna procedura prima dell'uso reale.
5. **Verifica del blocco in più punti.** L'Edge Function controlla la riga `runtime_lock_modifiche` prima del flusso procedure, ma la sicurezza effettiva dipende anche dalle funzioni SQL chiamate. Va verificato che ogni RPC scrittura controlli identità, sessione, stato del blocco, conferma finale e idempotenza dentro la stessa transazione.
6. **CORS permissivo.** L'Edge Function restituisce `Access-Control-Allow-Origin: *`. L'autenticazione resta richiesta, ma in un client distribuito è preferibile restringere le origini web se l'HTML viene mantenuto e non è richiesto l'accesso cross-origin generale.
7. **Risultato di salvataggio.** Il client deve riconoscere un esito positivo solo se la risposta contiene il segnale contrattuale esplicito di scrittura riuscita e se la successiva rilettura conferma i record. Un HTTP 200 da solo non basta.
8. **API tutte da collaudare.** Le 43 voci in `runtime_catalogo_api` sono marcate `API_IMPLEMENTATA_DA_COLLAUDARE`; questo non dimostra che ogni percorso sia funzionale.

## Evidenze verificate in sola lettura

- Edge Function: `collection-procedure-runtime-test`, stato `ACTIVE`, versione 16, `verify_jwt=false`.
- Il codice della funzione implementa controllo manuale del bearer token con `auth.getUser(token)` e verifica server-side della tabella `collection.app_authorized_users`.
- Il catalogo `collection.runtime_catalogo_api` contiene 43 record.
- La tabella `collection.app_authorized_users` ha 0 record.
- Le tabelle master di TEST contengono dati di collaudo; non sono stati inseriti, aggiornati o cancellati record in questo audit.
- La tabella `collection.runtime_lock_modifiche` esiste e contiene una sola riga di controllo del blocco.
- Il client Flutter nel pacchetto di partenza dichiara che non invoca ancora il runtime.

## Sequenza di lavoro sicura

1. Definire e approvare l'account beta da autorizzare nel progetto TEST.
2. Verificare le firme SQL delle RPC chiamate dalla Edge Function e controllare che siano presenti, con argomenti e permessi attesi.
3. Scrivere un client runtime Dart con base URL e chiave pubblicabile TEST configurabili per ambiente; mai includere `service_role` nell'app.
4. Implementare autenticazione, sessione, catalogo/health, consultazioni e report in sola lettura.
5. Testare con un account autorizzato: accesso negato senza allowlist, accesso consentito con allowlist, blocco esclusivo e heartbeat.
6. Implementare il flusso scrittura una procedura alla volta: preview senza scrittura, riepilogo, scelta se aggiungere record, review, conferma definitiva, request UUID per idempotenza, salvataggio e rilettura.
7. Collaudare casi negativi: token scaduto, utente non autorizzato, blocco altrui, payload invalido, doppio invio, errore RPC, rete interrotta e risposta ambigua.
8. Eseguire `flutter analyze`, `flutter test` e build Android/Windows in ambiente con SDK installati.

## Cosa NON è stato fatto

- Nessuna migrazione SQL.
- Nessun deploy della Edge Function.
- Nessuna modifica a Supabase TEST o produzione.
- Nessuna scrittura di record.
- Nessuna compilazione Flutter.
- Nessun test end-to-end autenticato.
