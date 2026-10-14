# COLLECTION by VALORA · Build Kit v6

Pacchetto pronto per essere caricato come contenuto della root di un repository GitHub.

## Build automatica
Dopo il commit, GitHub Actions avvia il workflow `.github/workflows/collection-by-valora-build.yml`. Se la build riesce, gli artefatti Android APK e Windows saranno disponibili nella scheda Actions della repository.

## Limiti attuali
- Questo pacchetto contiene il sorgente Flutter e la pipeline di compilazione, non APK/EXE già compilati.
- Il workflow non è ancora stato eseguito: la compilazione e i test Flutter devono essere verificati da GitHub Actions.
- L'interfaccia non è ancora collegata al runtime Supabase; non usare dati reali e non considerare collaudate le procedure DB.
- Non eseguire scritture sul database di produzione.

## Caricamento
Caricare il CONTENUTO di questo ZIP nella root del repository GitHub, non il file ZIP come singolo file. Devono comparire subito `pubspec.yaml`, `lib/`, `test/`, `docs/` e `.github/` nella pagina principale della repository.
