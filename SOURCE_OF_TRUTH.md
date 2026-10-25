# Sorgenti ufficiali di COLLECTION by VALORA

## Fonte Flutter

- `FLAT__lib__main.dart` è il sorgente canonico usato dalla pipeline CI.
- La pipeline lo copia in `lib/main.dart` prima dell'analisi e della compilazione.
- `lib/main.dart` viene mantenuto identico al sorgente canonico per sviluppo locale e test.
- `FLAT__pubspec.yaml` è il manifesto usato dalla pipeline e viene mantenuto identico a `pubspec.yaml`.
- Il vecchio `main.dart` nella radice del repository non era usato dalla build e divergeva dall'app corrente; è stato rimosso per evitare modifiche al file sbagliato.

## Verifiche prima della build

La pipeline deve eseguire, nell'ordine:
1. `flutter pub get`
2. `flutter analyze lib/main.dart --no-fatal-infos --no-fatal-warnings`
3. `flutter test`
4. Build Android e Windows

## Regola di stabilizzazione

Le correzioni si sviluppano su un branch dedicato. La versione funzionante di riferimento resta conservata nel branch `backup/stable-main-2026-10-24-run728`. Non modificare direttamente la produzione Supabase durante la stabilizzazione dell'app.
