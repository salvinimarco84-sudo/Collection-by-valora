# Architettura coordinata dei motori VALORA

## Numerazione delle procedure

- **PR-12 - Ricerca metadati:** motore centrale condiviso, senza limiti commerciali legati all'abbonamento VALORA.
- **PR-18 - VALORA:** valutazione specialistica del singolo oggetto dopo conferma PR-12.
- **PR-11 - VALUTAZIONE COMPLESSIVA COLLEZIONE:** valutazione in lotti del patrimonio e report storico.
- 
- **PR-20 - VALUTA ACQUISTO:** analisi rapida della convenienza di una specifica offerta, senza creare necessariamente una scheda oggetto nella collezione.

La numerazione è allineata: PR-18 è il motore del singolo oggetto, PR-20 resta VALUTA ACQUISTO e PR-11 gestisce la valutazione complessiva della collezione. Il vecchio endpoint PR-19 è dismesso e risponde con HTTP 410 indicando PR-18 come sostituto.

## Ruoli

- **PR-12 - motore di ricerca centrale:** identifica oggetti, ricerca fonti e corrispondenze, raccoglie metadati e restituisce evidenze con URL e diagnostica. È condiviso e non duplicato; non è di per sé una funzione premium.
- **PR-18 - VALORA:** si avvia esclusivamente dopo la conferma esplicita del candidato identificato da PR-12. Usa PR-12 per recuperare comparabili di mercato, distingue vendite concluse da prezzi richiesti e restituisce valore, fascia e affidabilità. Non scrive direttamente oggetti, acquisti o vendite.
- **PR-11 - VALUTAZIONE COMPLESSIVA COLLEZIONE:** usa PR-12 per valutare il patrimonio complessivo dell'utente a lotti di 10, registrare le rilevazioni periodiche e produrre il report di variazione. Non genera annunci di vendita.
- **PR-20 - VALUTA ACQUISTO:** aiuta a decidere se una proposta d'acquisto è conveniente. Non è una valutazione specialistica dell'oggetto e non richiede che l'oggetto sia già registrato nella collezione.

## Flusso PR-18 - VALORA

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
2. Usa **solo PR-12** per identificazione, metadati, fonti e comparabili. Non invoca il motore valutativo premium di PR-18.
3. Applica la propria logica autonoma di convenienza economica: costo complessivo, ricavo potenziale prudenziale, costi di rivendita e margine potenziale quando supportati dai dati disponibili.
4. Restituisce un esito orientativo, ad esempio **CONVENIENTE**, **DA NEGOZIARE**, **RISCHIOSO** o **DATI INSUFFICIENTI**, con motivazione e fonti.
5. Distingue sempre prezzi richiesti da prezzi di vendita realizzati. Non garantisce margini futuri e non inventa valori quando identificazione o comparabili sono insufficienti.
6. Non crea automaticamente una scheda nella collezione e non genera bozze di vendita VALORA.

## Accesso commerciale

- La ricerca metadati PR-12 non richiede l'abbonamento VALORA e non eredita i limiti commerciali del servizio premium.
- **PR-18 VALORA e PR-11 VALUTAZIONE COMPLESSIVA COLLEZIONE sono inclusi nello stesso abbonamento premium.** L'utente può continuare a utilizzare la struttura di base e gestire la propria collezione secondo le funzionalità non premium previste.
- PR-20 VALUTA ACQUISTO è una funzione distinta che utilizza PR-12 e la propria logica economica; non può invocare PR-18 per aggirare l'abbonamento.
- Il controllo dell'accesso alle funzioni premium deve essere applicato sul server, non soltanto nascondendo pulsanti nell'app.
- Alla scadenza dell'abbonamento si bloccano le nuove operazioni premium, senza cancellare oggetti, valutazioni o annunci salvati. Le regole per consultare o modificare contenuti premium già generati devono essere esplicite.

## Contratti e sicurezza

- Ogni risposta di ricerca deve preservare le fonti e la diagnostica, evitando di promuovere automaticamente un risultato web a metadato confermato.
- Le stime di PR-18 e PR-11 devono indicare mercato, valuta, data di riferimento, comparabili, intervallo, affidabilità e limiti.
- PR-20 produce un'analisi di convenienza e non deve presentarla come valutazione specialistica di VALORA.
- Per PR-11, valori insufficientemente supportati non sovrascrivono il valore corrente dell'oggetto; le rilevazioni devono restare tracciabili.
- Le scritture di storico e aggiornamento dei valori devono essere atomiche e autorizzate sul server.
- I motori vengono implementati e collaudati prima delle form finali; le interfacce chiamano contratti stabili e non duplicano logica di ricerca.
- Ogni modifica viene collaudata su TEST. Nessun rilascio in produzione o modifica della versione stabile senza verifiche.


## Informativa abbonamento nella registrazione (RM9)

Requisito UI da implementare nella schermata/form di registrazione identificata come RM9:
- Inserire in fondo al modulo un pulsante sempre visibile, con etichetta chiara come **ABBONAMENTO E FUNZIONI PREMIUM**.
- Il pulsante apre una pagina o finestra informativa completa, non una dicitura abbreviata, che spiega che **VALORA (PR-18) e VALUTAZIONE COMPLESSIVA COLLEZIONE (PR-11) sono servizi premium soggetti a un abbonamento a pagamento**.
- Chiarire che PR-12 ricerca metadati non è soggetto a questo abbonamento e che VALUTA ACQUISTO (PR-20) è una funzione distinta che non richiama il motore premium VALORA.
- L'informativa deve essere raggiungibile dal modulo senza completare la registrazione e rimanere facilmente accessibile.
- Non confondere l'informativa con l'accettazione contrattuale: eventuali checkbox/consensi e condizioni legali devono essere definiti separatamente.
- Il componente riutilizzabile `lib/widgets/subscription_info.dart` è stato creato sul branch TEST. Offre il pulsante e la finestra informativa completa, ma non è ancora integrato nel form RM9 perché nel codice Flutter esaminato non è stata trovata la schermata di registrazione: è presente `LoginPage`, che non va confusa con RM9. L'integrazione finale resta da fare quando il form corretto viene individuato.

## Stato

Questo documento fissa l'architettura desiderata e la numerazione delle procedure; non dichiara i motori completi. L'endpoint TEST `pr-18-valuation-test` è il motore specialistico del singolo oggetto e dipende da PR-12 dopo conferma utente. `collection-market-value-test` è riallineato a PR-11 per la valutazione complessiva in lotti. PR-20 resta dedicata alla convenienza d'acquisto.
