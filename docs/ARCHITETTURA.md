# Architettura beta COLLECTION by VALORA

- **UI:** Flutter per Android e Windows; comandi ufficiali, testo e controlli touch/click.
- **Autenticazione:** Supabase Auth; l'Edge Function verifica token e allowlist server-side.
- **API:** `collection-procedure-runtime-test`, solo progetto TEST `eeiekkflpnkummxtvljy`, contratto v10.
- **Database autorevole:** PostgreSQL/Supabase TEST. Il client non scrive direttamente nelle tabelle master.
- **Esclusività:** lock centrale, session ID stabile, heartbeat; nessun rilascio automatico per timeout.
- **Idempotenza:** request ID persistente per ogni scrittura; i retry riusano lo stesso ID e lo stesso payload.
- **Offline:** SQLite locale per coda FIFO; payload immutabile; al ritorno della rete, il server passa a `IN_RECUPERO`, sincronizza una voce alla volta, verifica l'esito e solo a coda vuota torna ad `ATTIVO`.
- **Rilascio:** solo dopo sincronizzazione completa e verificata.
- **Produzione:** non utilizzata né modificata.

## Stato build

Il sorgente client è aggiornato, ma la compilazione nativa non è stata eseguita in questo ambiente: mancano Flutter/Dart SDK e Android SDK. Il runtime TEST è attivo; la beta non è dichiarata collaudata finché non passano analisi, test, build Android/Windows e prove HTTP autenticate.
