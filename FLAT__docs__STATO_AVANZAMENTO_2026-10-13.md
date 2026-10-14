# COLLECTION by VALORA - Stato avanzamento

Data: 13 ottobre 2026  
Ambiente backend autorizzato: Supabase TEST `eeiekkflpnkummxtvljy`.  
Produzione `bufwceckrmbocctarthj`: non utilizzata.

## Lavoro completato in questa sessione

- Sorgente Flutter `0.3.0+6`, maschera grafica schema-driven, flusso multi-record e input vocale/testuale/touch predisposti.
- Runtime Edge Function TEST attivo, versione 16, contratto API v10.
- Aggiunta pipeline GitHub Actions per build separate Android e Windows, analisi statica Dart e test unitari; la pipeline resta da eseguire in un repository. Allineata la versione del pacchetto e aggiunti controlli su versione, assenza di service-role nel client, retry con request_id e verifica della scrittura.
- Script statico locale: 28 controlli superati, inclusi i controlli su coda prima dell’HTTP, riuso del request_id durante il retry, blocco esclusivo prima della scrittura e divieto di scrittura nelle fasi di anteprima.
- Tabelle base `collection` con RLS: 34/34 abilitate; senza RLS: 0.
- Produzione non modificata.

## Blocchi sostanziali prima del risultato finale

1. **Compilazione non ancora eseguita.** L'ambiente corrente non contiene Flutter/Dart, Android SDK o gli strumenti nativi Windows. Non sono disponibili APK/EXE verificati. La pipeline è stata aggiunta, ma non eseguita.
2. **Beta autenticata non collaudabile.** La tabella `collection.app_authorized_users` non ha utenti attivi. Non sono state create autorizzazioni senza consenso esplicito.
3. **Test end-to-end assenti.** Non è stato eseguito un ciclo autenticato reale di anteprima, conferma, scrittura, rilettura, retry/idempotenza e sincronizzazione offline.
4. **43 contratti runtime** risultano `API_IMPLEMENTATA_DA_COLLAUDARE`. Codice e configurazione non costituiscono prova di funzionamento.
5. **Dati di uscita/valutazioni online:** la ricerca automatizzata di fonti ufficiali e comparabili non è ancora integrata come servizio verificato.

## Gate di rilascio

Non dichiarare la beta pronta finché non siano documentati come superati: `flutter analyze`, `flutter test`, build Android/Windows, accesso autenticato su TEST, test procedure singole/multiple, retry/idempotenza, sincronizzazione offline, rilettura post-scrittura e prova su dispositivi reali.


## Revisione 0.3.0+8
- La pipeline GitHub Actions include ora l'esecuzione di `scripts/static_contract_check.py` prima di `flutter pub get`.
- Versione aggiornata a 0.3.0+8.
- La pipeline remota non è stata avviata: richiede repository GitHub collegato.


## Revisione 0.3.0+9

Corretto il trattamento degli errori HTTP della coda: 401/403 e codici transitori/conflitto 408/409/425/429 non eliminano più automaticamente una scrittura pendente. La richiesta mantiene il suo `request_id` per riconciliazione e retry. Verifica statica soltanto; build e test Flutter ancora da eseguire.


## Revisione 0.3.0+10

Corretto il riferimento iniziale alla versione nel README e aggiunto un controllo statico per impedirne il disallineamento rispetto a `pubspec.yaml`. Non sono state eseguite modifiche al backend o ai dati. La compilazione Flutter e i test end-to-end restano bloccati dall'assenza dell'SDK e di un utente beta autorizzato.


## Revisione 0.3.0+11

- Corretto il mapping dei report: i codici mostrati nella UI (`REPORT-*`) sono ora tradotti nei codici effettivi attesi dal runtime (`*_REPORT`).
- Selezionando un report, gli argomenti iniziali vengono caricati dal contratto corrispondente.
- Aggiunti test e controllo statico dedicati al mapping report.
- Verificato con i contratti letti dal progetto Supabase TEST. Build Flutter ed end-to-end restano da eseguire.


## Revisione 0.3.0+12

- Impostati automaticamente gli argomenti iniziali del report predefinito all'apertura della schermata, evitando l'invio involontario di `{}` al runtime.
- Estesi i test del contratto per i periodi predefiniti dei report.
- Nessuna modifica al database o alla Edge Function. Build Flutter e test end-to-end restano da eseguire.


## Revisione 0.3.0+13

- Corretto l'editor delle fonti ufficiali per richiedere i campi del contratto runtime: titolo, URL, estratto e tipo fonte.
- Il tipo fonte propone esclusivamente `PRODUTTORE_UFFICIALE` o `ARCHIVIO_UFFICIALE_PRODUTTORE`.
- Aggiunti controlli automatici statici e test del contratto relativi alle fonti.
- La ricerca automatica esterna non è inclusa: le fonti vanno inserite e validate manualmente finché non sarà implementato un servizio di ricerca verificato.


## Revisione 0.3.0+14

- Aggiunto uno script CI che configura/verifica i permessi Android per rete e riconoscimento vocale dopo la generazione dei wrapper nativi.
- La pipeline Android esegue la configurazione prima dei controlli e della build.
- La configurazione è verificata staticamente; resta da verificare la richiesta del permesso microfono su un dispositivo Android reale.


## Revisione 0.3.0+15

- Aggiunti nel centro di controllo i pulsanti funzionali `STATO RUNTIME` e `CATALOGO API`, collegati alle azioni `health` e `catalog` della Edge Function TEST.
- Confermata tramite API di gestione Supabase la presenza di una chiave publishable TEST attiva e verificato lo stato attivo dell'utente autorizzato nella allowlist. Nessuna chiave service-role è inclusa nell'app.
- Il controllo HTTP autenticato dalla UI resta da eseguire con una sessione effettiva; la sola presenza dell'allowlist non equivale a collaudo end-to-end.
