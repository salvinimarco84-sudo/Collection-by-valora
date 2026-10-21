# PR-12 Engine: architettura TEST

## Scopo

Introdurre un livello di orchestrazione per PR-12 senza sostituire né sovrascrivere la funzione stabile `pr-12-web-search-test`. Il nuovo endpoint `pr-12-engine-test` è aggiuntivo e deve essere provato prima di qualsiasi integrazione UI.

## Fonti e regole

Il motore continua a interrogare la funzione di ricerca già esistente, che legge l'archivio TEST `collection.archivio_fonti_ricerca` e le regole franchise `collection.regole_ricerca_franchise`. Verifica iniziale del progetto TEST: 50 fonti riutilizzabili su 50 e 33 regole attive su 33. Le tabelle di configurazione non vengono modificate.

## Coda multi-oggetto

- Input: `oggetti`, array di 1-10 elementi con `id`, `descrizione`, `categoria` opzionale.
- Lavorazione sequenziale per contenere il carico e rendere visibile il progresso.
- Output Server-Sent Events (SSE), un evento JSON per blocco:
  - `coda_avviata`
  - `oggetto_in_elaborazione`
  - `oggetto_completato` oppure `oggetto_errore`
  - `coda_completata`
- Ogni risultato porta esplicitamente `metadati_confermati: false` e `scrittura_database: false`.
- Il client deve mostrare l'avanzamento e mantenere separati i candidati per ID oggetto.

## Livello IA sostituibile

L'interfaccia logica è `rankCandidates(mode, item, candidates)`: l'IA può soltanto ordinare URL già restituite dalla ricerca e assegnare un livello di confidenza/ragione. Non può creare URL o scrivere metadati nel catalogo.

Modalità previste:
1. `TEST`: ricerca web attuale senza chiamata API LLM. L'abbonamento ChatGPT personale non è una credenziale API e non viene invocato direttamente dal backend.
2. `COMMERCIALE_GESTITA`: chiave backend `VALORA_MANAGED_AI_API_KEY`, modello opzionale `VALORA_MANAGED_AI_MODEL`.
3. `API_A_CONSUMO`: chiave backend `VALORA_METERED_AI_API_KEY`, modello opzionale `VALORA_METERED_AI_MODEL`.

Le chiavi sono esclusivamente segreti server-side e non devono essere incluse nel client Flutter o nei file versionati. Le modalità commerciali restano inattive finché i rispettivi segreti non vengono configurati.

## Sicurezza e non regressione

- Progetto target esclusivo: Supabase `COLLECTION by VALORA TEST` (`eeiekkflpnkummxtvljy`).
- Nessuna migrazione SQL, nessuna scrittura su `collection.master_oggetti`, nessuna modifica ai metadati validi.
- L'endpoint stabile PR-12 v49 resta invariato.
- Non fondere il branch in `main` e non distribuire in produzione senza collaudo esplicito.
- Il client dovrà consumare lo stream SSE con `http.Client.send` e aggiornare la progress bar a ogni evento; `functions.invoke` può bufferizzare la risposta e non deve essere usato per la schermata di progresso senza verifica.
- Collaudo richiesto: 1 oggetto LEGO con codice, 2 oggetti di categorie diverse, un errore di ricerca, modalità IA senza segreto, controllo che non avvengano scritture.

## Stato

Questa specifica e il codice sorgente iniziale vivono nel branch `feature/pr12-engine-test`. Non sono ancora distribuiti né compilati. La nuova funzione deve superare revisione e test prima del deploy nel progetto TEST.
