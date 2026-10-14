# COLLECTION by VALORA · beta multipiattaforma

Versione sorgente `0.3.0+15` (pacchetto aggiornato con pipeline CI e controlli statici estesi). Destinazioni previste: **Android e Windows**. Il client usa esclusivamente il progetto Supabase TEST `eeiekkflpnkummxtvljy` e non contiene credenziali `service_role`. La produzione `bufwceckrmbocctarthj` non viene chiamata.

## Implementato nel sorgente client

- Accesso Supabase Auth e chiamate HTTPS alla Edge Function `collection-procedure-runtime-test`.
- Contratto runtime v10: `session_id` persistente, `request_id` idempotente, `acquire_lock`, heartbeat, rilascio esplicito.
- Coda SQLite FIFO persistente per scritture confermate, con payload immutabile, stato e ultimo errore.
- Recupero della coda tramite `queue_pending` e `sync_operation`; il blocco non viene rilasciato se la coda è ancora presente.
- Interfaccia grafica Flutter con editor di campi nativi guidato dagli schemi, controlli a scelta, date picker, liste modificabili e flusso multi-record per PR-01…PR-10. Accorpamento non esposto come procedura autonoma; resta funzione interna. Include gestione piattaforme, dati di uscita e consultazioni/report.
- Risoluzione comandi esatta: il client non sceglie una procedura con corrispondenza parziale del testo.
- Schermate con riepilogo, conferma dei dati, domanda «Vuoi fare un’altra operazione?», conferma finale e controllo dell’esito restituito dal server.

## Limiti che impediscono di dichiarare la beta pronta

- Il sorgente è stato aggiornato, ma in questo ambiente **non è stato possibile eseguire `flutter analyze`, `flutter test` né compilare un APK/EXE**: Flutter/Dart SDK e Android SDK non sono installati e l'ambiente non può scaricare dipendenze dalla rete. La maschera è stata verificata staticamente, non ancora compilata dal compilatore Dart.
- L'account beta deve essere autorizzato esplicitamente in `collection.app_authorized_users` nel progetto TEST. La verifica precedente rilevava zero account attivi.
- Il test HTTP end-to-end autenticato non è stato eseguito.
- La ricerca Internet automatizzata di data/prezzo di lancio non è ancora integrata. Il client prepara la richiesta e raccoglie i risultati/fonti, ma non deve presentare una fonte come ufficiale senza verifica del dominio produttore.
- Le funzioni SQL che dichiarano `SALVATO_E_VERIFICATO` devono essere testate con casi positivi, negativi, retry e coda offline prima di usare dati operativi.

## Compilazione in ambiente Flutter predisposto

La cartella sorgente non contiene ancora i wrapper generati `android/` e `windows/`: vanno creati con `flutter create --platforms=android,windows .` nell'ambiente di build prima dei test.

Prerequisiti: Flutter SDK 3.x compatibile con Dart >=3.3, Android Studio + Android SDK per Android; Visual Studio con workload **Desktop development with C++** per Windows.

```bash
flutter create --platforms=android,windows .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build windows
```

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`.
Pacchetto Windows: `build/windows/x64/runner/Release/`.

Una build debug non è una release firmata. Prima di distribuire, completare test su dispositivo, firma Android, configurazione Windows e verifica sicurezza.

## Regole di sicurezza operative

- Non collegare questo client alla produzione.
- Non mettere nel client chiavi `service_role`.
- Non generare un nuovo `request_id` per ritentare la stessa operazione.
- Se l'esito di una scrittura è incerto, mantenere la richiesta in coda, non avviare nuove modifiche e riconciliare con lo stesso ID.
- Non rilasciare il blocco se esistono operazioni pendenti.
- SQLite è coda/cache locale, non fonte autorevole; PostgreSQL TEST resta la fonte centrale.

## Build automatizzata su GitHub Actions

È incluso `.github/workflows/build.yml`, che su push a `main`/`master` o avvio manuale esegue su runner separati:

- generazione wrapper Flutter Android/Windows;
- `flutter pub get`, `flutter analyze`, `flutter test`;
- build APK debug Android e build Windows;
- caricamento degli artefatti scaricabili nella pagina del workflow.

Questa pipeline è predisposta ma **non è stata eseguita**: richiede che il progetto venga caricato in un repository GitHub e che il workflow sia avviato. Gli artefatti debug non sono release firmate e non dimostrano il collaudo end-to-end con Supabase.


### Revisione 0.3.0+7

La conferma e la revisione delle procedure relative ai dati di uscita acquisiscono ora prima il blocco esclusivo dell'archivio, richiesto dal runtime. L'acquisizione del blocco non esegue scritture sui dati di catalogo. La correzione è verificata staticamente; il collaudo autenticato resta necessario.


### Revisione 0.3.0+15

La pipeline CI ora esegue anche `scripts/static_contract_check.py` prima di risolvere le dipendenze Flutter, così i contratti statici del repository vengono controllati nel runner remoto insieme ad analisi, test e build. La pipeline non è stata ancora eseguita; la modifica è verificata localmente.


## Beta 0.3.0+15: tutela della coda in caso di autenticazione/risposte transitorie

La gestione degli errori HTTP non elimina più la richiesta locale per risposte 401, 403, 408, 409, 425 o 429. Questi casi possono richiedere un nuovo accesso, una riconciliazione o un tentativo successivo e non devono cancellare automaticamente una scrittura pendente. Il medesimo `request_id` viene conservato per il retry. I rifiuti di validazione deterministici 4xx continuano a poter rimuovere la richiesta respinta.

Questa modifica è verificata staticamente; non è ancora stata eseguita con `flutter test` né con una sessione HTTP autenticata.


## Revisione 0.3.0+15: allineamento documentazione e controlli di rilascio

Corretto il riferimento alla versione in testa al README, che era rimasto indietro rispetto a pubspec.yaml. Questa revisione non modifica il runtime né i dati Supabase. Il controllo statico verifica anche i contratti documentati; build e test Flutter restano da eseguire in CI.
