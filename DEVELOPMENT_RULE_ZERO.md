# Regola Zero: sviluppo additivo e non distruttivo

Questa regola si applica a ogni modifica di COLLECTION by VALORA.

## Principi obbligatori

1. Conservare tutte le funzionalità esistenti che non sono oggetto esplicito della richiesta.
2. Preferire modifiche minime e localizzate. Non riscrivere schermate, flussi o componenti condivisi per ottenere una modifica circoscritta.
3. Non eliminare, rinominare, disattivare o sostituire funzioni, asset, campi, procedure o comportamenti senza richiesta esplicita.
4. Prima di modificare un file, leggere la versione corrente del ramo di lavoro e confrontare le modifiche recenti. Non ripristinare file interi da un altro ramo quando è sufficiente recuperare una modifica specifica.
5. Prima del commit, esaminare il diff e verificare che ogni file modificato sia necessario alla richiesta.
6. Ogni nuova funzionalità deve avere test di regressione. I test devono proteggere anche i contratti funzionali preesistenti.
7. Eseguire `flutter test` e `flutter analyze` prima delle build di distribuzione.
8. Una build verde dimostra la compilazione, non la correttezza funzionale né l'assenza di regressioni.
9. Raggruppare le modifiche correlate in una build candidata, evitando build ripetute per piccoli passaggi intermedi.
10. Sviluppare e verificare esclusivamente su rami TEST. Non modificare `main`, configurazioni o database di produzione senza autorizzazione esplicita.
11. Se un test fallisce, fermare la consegna, identificare la regressione e correggerla prima di chiedere all'utente di installare un nuovo APK.
12. Conservare un riferimento al commit precedente e usare commit piccoli e reversibili.

## Checklist prima di ogni commit

- [ ] Richiesta e perimetro della modifica identificati.
- [ ] Stato corrente del ramo letto e modifiche recenti confrontate.
- [ ] Nessuna modifica estranea o cancellazione non autorizzata.
- [ ] Diff revisionato file per file.
- [ ] Test di regressione aggiornati.
- [ ] `flutter test` superato.
- [ ] `flutter analyze` superato.
- [ ] Build Android/Windows eseguita solo quando serve una build candidata.
- [ ] Ramo TEST confermato; produzione invariata.

## Comunicazione dello stato

Comunicare separatamente:
- test automatici;
- analisi statica;
- build Android e Windows;
- verifica manuale sul dispositivo.

Non dichiarare una funzionalità verificata solo perché la build è verde.
