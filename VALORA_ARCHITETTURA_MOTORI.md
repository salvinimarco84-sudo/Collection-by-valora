# Architettura coordinata dei motori VALORA

## Numerazione delle procedure

- **PR-12 - Ricerca metadati:** motore centrale condiviso, senza limiti commerciali legati all'abbonamento VALORA.
- **PR-18 - VALORE COLLEZIONE:** valutazione complessiva del patrimonio e report storico.
- **PR-19 - VALORA:** valutazione specialistica del singolo oggetto e preparazione delle bozze di inserzione.
- **PR-20 - VALUTA ACQUISTO:** analisi rapida della convenienza di una specifica offerta, senza creare necessariamente una scheda oggetto nella collezione.

La ricerca ha verificato che PR-19 non compare nei risultati di ricerca del repository. La numerazione PR-19 e PR-20 viene fissata qui come assegnazione architetturale da propagare al catalogo procedure/runtime prima dell'attivazione.

## Ruoli

- **PR-12 - motore di ricerca centrale:** identifica oggetti, ricerca fonti e corrispondenze, raccoglie metadati e restituisce evidenze con URL e diagnostica. È condiviso e non duplicato; non è di per sé una funzione premium.
- **PR-18 - VALORE COLLEZIONE:** usa PR-12 per valutare il patrimonio complessivo dell'utente, registrare le rilevazioni periodiche e produrre il report di variazione. Non genera annunci di vendita.
- **PR-19 - VALORA:** usa PR-12 per identificare l'oggetto e raccogliere evidenze, quindi esegue la valutazione specialistica del singolo oggetto e genera bozze per le piattaforme di vendita selezionate dall'utente.
- **PR-20 - VALUTA ACQUISTO:** aiuta a decidere se una proposta d'acquisto è conveniente. Non è una valutazione specialistica dell'oggetto e non richiede che l'oggetto sia già registrato nella collezione.

## Flusso PR-19 - VALORA

1. Riceve descrizione e, quando disponibili, fotografie e dettagli dell'oggetto.
2. Richiede a PR-12 ricerca e identificazione.
3. Verifica corrispondenza, mercato di riferimento, condizione, completezza e qualità delle fonti.
4. Stima il valore con intervallo e affidabilità. Distingue prezzi richiesti da prezzi realizzati e non inventa dati mancanti.
5. Prepara bozze di annunci specifiche per le piattaforme selezionate dall'utente. Le bozze sono revisionabili e non vengono pubblicate automaticamente.
6. Restituisce valutazione, fonti, comparabili e bozze al chiamante.

## Flusso PR-20 - VALUTA ACQUISTO

PR-20 deve accettare più modalità di ingresso:
- foto scattata direttamente all'oggetto, ad esempio al mercatino o a una fiera;
- screenshot di un'inserzione online;
- link a un'inserzione, se accessibile;
- inserimento manuale di descrizione e prezzo richiesto.

Flusso:
1. Acquisisce immagine o dati dell'offerta e prezzo richiesto; può chiedere ulteriori dettagli essenziali, come condizioni, completezza e spese.
2. Usa **solo PR-12** per identificazione, metadati, fonti e comparabili. Non invoca il motore valutativo premium di PR-19.
3. Applica la propria logica autonoma di convenienza economica: costo complessivo, ricavo potenziale prudenziale, costi di rivendita e margine potenziale quando supportati dai dati disponibili.
4. Restituisce un esito orientativo, ad esempio **CONVENIENTE**, **DA NEGOZIARE**, **RISCHIOSO** o **DATI INSUFFICIENTI**, con motivazione e fonti.
5. Distingue sempre prezzi richiesti da prezzi di vendita realizzati. Non garantisce margini futuri e non inventa valori quando identificazione o comparabili sono insufficienti.
6. Non crea automaticamente una scheda nella collezione e non genera bozze di vendita VALORA.

## Accesso commerciale

- La ricerca metadati PR-12 non richiede l'abbonamento VALORA e non eredita i limiti commerciali del servizio premium.
- **PR-19 VALORA e PR-18 VALORE COLLEZIONE sono inclusi nello stesso abbonamento premium.** L'utente può continuare a utilizzare la struttura di base e gestire la propria collezione secondo le funzionalità non premium previste.
- PR-20 VALUTA ACQUISTO è una funzione distinta che utilizza PR-12 e la propria logica economica; non può invocare PR-19 per aggirare l'abbonamento.
- Il controllo dell'accesso alle funzioni premium deve essere applicato sul server, non soltanto nascondendo pulsanti nell'app.
- Alla scadenza dell'abbonamento si bloccano le nuove operazioni premium, senza cancellare oggetti, valutazioni o annunci salvati. Le regole per consultare o modificare contenuti premium già generati devono essere esplicite.

## Contratti e sicurezza

- Ogni risposta di ricerca deve preservare le fonti e la diagnostica, evitando di promuovere automaticamente un risultato web a metadato confermato.
- Le stime di PR-18 e PR-19 devono indicare mercato, valuta, data di riferimento, comparabili, intervallo, affidabilità e limiti.
- PR-20 produce un'analisi di convenienza e non deve presentarla come valutazione specialistica di VALORA.
- Per PR-18, valori insufficientemente supportati non sovrascrivono il valore corrente dell'oggetto; le rilevazioni devono restare tracciabili.
- Le scritture di storico e aggiornamento dei valori devono essere atomiche e autorizzate sul server.
- I motori vengono implementati e collaudati prima delle form finali; le interfacce chiamano contratti stabili e non duplicano logica di ricerca.
- Ogni modifica viene collaudata su TEST. Nessun rilascio in produzione o modifica della versione stabile senza verifiche.


## Informativa abbonamento nella registrazione (RM9)

Requisito UI da implementare nella schermata/form di registrazione identificata come RM9:
- Inserire in fondo al modulo un pulsante sempre visibile, con etichetta chiara come **ABBONAMENTO E FUNZIONI PREMIUM**.
- Il pulsante apre una pagina o finestra informativa completa, non una dicitura abbreviata, che spiega che **VALORA (PR-19) e VALORE COLLEZIONE (PR-18) sono servizi premium soggetti a un abbonamento a pagamento**.
- Chiarire che PR-12 ricerca metadati non è soggetto a questo abbonamento e che VALUTA ACQUISTO (PR-20) è una funzione distinta che non richiama il motore premium VALORA.
- L'informativa deve essere raggiungibile dal modulo senza completare la registrazione e rimanere facilmente accessibile.
- Non confondere l'informativa con l'accettazione contrattuale: eventuali checkbox/consensi e condizioni legali devono essere definiti separatamente.
- Il componente riutilizzabile `lib/widgets/subscription_info.dart` è stato creato sul branch TEST. Offre il pulsante e la finestra informativa completa, ma non è ancora integrato nel form RM9 perché nel codice Flutter esaminato non è stata trovata la schermata di registrazione: è presente `LoginPage`, che non va confusa con RM9. L'integrazione finale resta da fare quando il form corretto viene individuato.

## Stato

Questo documento fissa l'architettura desiderata e la numerazione delle procedure; non dichiara i motori completi. L'endpoint TEST `collection-market-value-test` è attualmente un preflight in sola lettura; non è ancora un motore di valutazione di mercato operativo. La numerazione PR-18/19/20 deve essere allineata nei cataloghi runtime e nelle voci UI prima di attivare le procedure.
