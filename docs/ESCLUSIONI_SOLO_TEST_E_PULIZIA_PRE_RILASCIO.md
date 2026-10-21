# Esclusioni TEST e pulizia prima del rilascio

**Promemoria obbligatorio per il rilascio di COLLECTION by VALORA.**  
Ambiente interessato: esclusivamente Supabase TEST `eeiekkflpnkummxtvljy`.

## Record sintetici archiviati

- Sono stati marcati logicamente **971 record sintetici** con `collection.master_oggetti.archiviato_test = true`.
- I record sono stati conservati intenzionalmente perché la cancellazione fisica è bloccata dallo storico e non deve essere aggirata.
- L'app e PR-12 devono escludere questi record da elenchi operativi, analisi e lotti di ricerca.
- Il filtro PR-12 lato app legge gli ID archiviati e fallisce in sicurezza se non riesce a leggerli.
- **Da fare dopo il collaudo completo:** verificare che nessuna funzione, report, ricerca o procedura mostri/usi questi record; quindi definire una procedura di pulizia conforme ai vincoli dello storico. Non cancellare fisicamente lo storico e non eseguire la pulizia in produzione senza piano e verifica separati.

## Comandi e strumenti esclusivamente di collaudo

Prima della beta commerciale:
1. rimuovere o disabilitare nell'interfaccia finale i comandi diagnostici, di collaudo, debug, batch di prova e funzioni marcate TEST;
2. rimuovere etichette e percorsi tecnici destinati soltanto agli sviluppatori, mantenendo solo controlli operativi necessari e autorizzati;
3. controllare che l'app commerciale punti al progetto corretto e non contenga URL, chiavi o chiamate dell'ambiente TEST;
4. eseguire una verifica completa delle dipendenze backend e dei permessi, quindi collaudare le operazioni essenziali prima del rilascio.

## Vincoli non negoziabili

- Non toccare produzione durante questa fase.
- Non considerare l'archiviazione logica equivalente alla rimozione dall'interfaccia: il filtro va verificato anche a runtime.
- Non rimuovere il flag `archiviato_test` finché i record non sono stati gestiti con una procedura approvata e verificata.
- La pulizia dei record sintetici e la rimozione dei comandi di test sono attività di checklist pre-rilascio, non operazioni automatiche di questo commit.
