# Architettura coordinata dei motori VALORA

## Ruoli

- **PR-12 - motore di ricerca centrale:** identifica oggetti, ricerca fonti e corrispondenze, raccoglie metadati e restituisce evidenze con URL e diagnostica. È condiviso, non duplicato.
- **PR-18 - VALORE COLLEZIONE:** usa PR-12 per valutare il patrimonio complessivo dell'utente, registrare le rilevazioni periodiche e produrre il report di variazione. Non genera annunci di vendita.
- **VALORA - valutazione del singolo oggetto e annunci:** usa prima PR-12 per identificare l'oggetto e raccogliere le evidenze, poi il motore valutativo condiviso per stimare il singolo oggetto e genera bozze per le piattaforme di vendita selezionate dall'utente.

## Flusso di VALORA

1. Riceve descrizione e, quando disponibili, fotografie e dettagli dell'oggetto.
2. Richiede a PR-12 ricerca e identificazione.
3. Verifica corrispondenza, mercato di riferimento, condizione, completezza e qualità delle fonti.
4. Stima il valore con intervallo e affidabilità. Distingue prezzi richiesti da prezzi realizzati e non inventa dati mancanti.
5. Prepara bozze di annunci specifiche per le piattaforme selezionate dall'utente. Le bozze sono revisionabili e non vengono pubblicate automaticamente.
6. Restituisce valutazione, fonti, comparabili e bozze al chiamante.

## Accesso commerciale

- La gestione della collezione e PR-18 restano disponibili senza abbonamento VALORA.
- Le funzioni di valutazione del singolo oggetto e generazione degli annunci di VALORA richiedono un abbonamento mensile attivo.
- Il controllo dell'entitlement è server-side. Alla scadenza si bloccano le nuove operazioni premium senza cancellare oggetti, valutazioni o annunci salvati.
- Le regole definitive per consultare/modificare bozze già generate devono essere esplicite; la scadenza non deve mai cancellare dati.

## Contratti e sicurezza

- Ogni risposta di ricerca deve preservare le fonti e la diagnostica, evitando di promuovere automaticamente un risultato web a metadato confermato.
- Le stime devono indicare mercato, valuta, data di riferimento, comparabili, intervallo, affidabilità e limiti.
- Per PR-18, valori insufficientemente supportati non sovrascrivono il valore corrente dell'oggetto; le rilevazioni devono restare tracciabili.
- Le scritture di storico e aggiornamento dei valori devono essere atomiche e autorizzate sul server.
- I motori sono implementati e collaudati prima delle form finali; le interfacce chiamano contratti stabili e non duplicano logica di ricerca o valutazione.
- Ogni modifica viene collaudata su TEST. Nessun rilascio in produzione o modifica della versione stabile senza verifiche.

## Stato

Questo documento fissa l'architettura desiderata, non dichiara i motori completi. L'endpoint TEST `collection-market-value-test` è attualmente un preflight in sola lettura; non è ancora un motore di valutazione di mercato operativo.