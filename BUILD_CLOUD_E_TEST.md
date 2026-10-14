# Build cloud e test automatici

Questa cartella include un workflow GitHub Actions per provare a compilare l'app Flutter e pubblicare gli artefatti di collaudo.

## Cosa farà il workflow
1. Genera i file di piattaforma Android e Windows a partire dal progetto Flutter.
2. Esegue `flutter pub get`, `flutter analyze` e `flutter test`.
3. Se i controlli passano, genera un APK Android release.
4. Se i controlli passano, genera il pacchetto Windows release.
5. Conserva gli artefatti per 14 giorni nella pagina Actions della repository.

## Importante
- Questo workflow **non è stato eseguito qui** e non prova che il progetto compili.
- Gli eseguibili prodotti sono una build dell'interfaccia di collaudo. La versione Flutter contenuta nel pacchetto non è ancora collegata al runtime Supabase: non eseguire operazioni reali tramite questa build.
- Il workflow non usa credenziali Supabase e non modifica database.
- Per ottenere gli artefatti, caricare il contenuto del progetto nella repository GitHub e avviare il workflow `COLLECTION by VALORA - Build and Test` dalla scheda Actions.
- Gli errori di analisi o test fermeranno il workflow prima della generazione degli eseguibili. Correggere i test prima di chiamare la build affidabile.
- La build Windows richiede il runner `windows-latest` con toolchain Microsoft fornita dall'ambiente GitHub Actions.

## Caricamento repository
Caricare il contenuto della cartella `COLLECTION_by_VALORA_flutter_UI` nella radice della repository (in modo che `lib/`, `pubspec.yaml`, `test/` e `.github/` siano al livello principale). Se si carica la cartella annidata così com'è, il workflow già fornito usa il percorso `COLLECTION_by_VALORA_flutter_UI/`; in tal caso mantenere la cartella e il percorso del workflow coerenti.
