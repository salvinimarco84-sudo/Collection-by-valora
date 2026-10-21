# Specifica operativa: fotografie, PR-01, PR-04 e PR-12

## Obiettivo

Consentire di avviare l'inserimento di un oggetto da una fotografia, usare PR-12 per cercare corrispondenze e compilare una bozza di descrizione e metadati, e offrire facoltativamente un'immagine di catalogo come immagine principale del record. La pubblicazione di inserzioni resta sempre sotto il controllo dell'utente.

## Ruoli delle procedure

### PR-01 - Nuovo oggetto
- Permettere di iniziare con una foto scattata o caricata, senza obbligare a conoscere già la descrizione completa.
- Consentire più immagini quando serve: vista generale, etichetta/codice prodotto, retro e dettagli.
- Avviare il riconoscimento visivo e l'estrazione dei testi solo tramite un servizio di IA effettivamente configurato.
- Passare a PR-12 la descrizione provvisoria, il codice letto, la categoria e gli altri indizi riconosciuti.
- Mostrare i campi proposti e la fonte di ciascun dato. Non salvare metadati incerti senza revisione dell'utente.

### PR-04 - Nuovo acquisto
- Consentire di associare foto agli oggetti inclusi nell'acquisto e, se l'oggetto è nuovo nel catalogo, avviare il medesimo flusso di identificazione.
- Separare i dati dell'acquisto (data, prezzo pagato, venditore e spese) dai metadati identificativi dell'oggetto.
- Non dedurre dalla foto prezzo pagato, completezza reale, condizioni o altri dati che richiedono conferma.
- Mantenere invariati i controlli transazionali esistenti e il salvataggio SQL; nessuna scrittura parziale se il flusso fallisce.

### PR-12 - Ricerca metadati
- Accettare sia record già presenti nel catalogo sia oggetti nuovi identificati tramite foto.
- Cercare su fonti web/cataloghi pertinenti usando descrizione, marchio, codice prodotto, categoria e testo estratto dall'immagine.
- Restituire candidati con titolo, fonte/URL, immagine disponibile e livello di affidabilità motivato.
- Non inventare una corrispondenza quando i riscontri sono insufficienti. In caso di più risultati, chiedere all'utente di scegliere.
- Conservare il comportamento di sola lettura durante la ricerca. I metadati vengono applicati alla bozza solo dopo selezione e conferma.

## Immagine del record

- Dopo una ricerca riuscita, proporre facoltativamente una o più immagini di catalogo pertinenti.
- Mostrare un'anteprima e permettere di scegliere: foto originale, immagine di catalogo o altra foto selezionata.
- Non sostituire mai automaticamente la foto originale.
- Conservare, quando disponibile, l'URL/fonte, la data di acquisizione e il riferimento al prodotto identificato.
- Verificare i diritti e le condizioni d'uso della fonte prima di distribuire o riutilizzare immagini.
- Se l'utente sceglie un'immagine di catalogo come principale, mantenere le foto reali come immagini aggiuntive quando il modello dati lo consente.

## Creazione del testo per le piattaforme

VALORA prepara soltanto una bozza testuale specifica per ciascuna piattaforma selezionata dall'utente. Non pubblica inserzioni, non carica fotografie sulle piattaforme e non sceglie al posto dell'utente le immagini da pubblicare.

Nel momento in cui viene preparato il testo, mostrare consigli contestuali:
1. utilizzare fotografie reali dell'esemplare effettivamente venduto;
2. includere una foto nitida del codice prodotto/etichetta quando presente;
3. mostrare condizioni, difetti, accessori e contenuto effettivo della confezione;
4. distinguere chiaramente eventuali immagini illustrative di catalogo dalle foto reali.

L'utente resta responsabile della revisione del testo, della scelta delle immagini e della pubblicazione.

## Provenienza e affidabilità

Per ogni campo proposto dalla ricerca, ove possibile registrare:
- valore proposto;
- fonte e URL;
- metodo (testo inserito, OCR/lettura immagine, fonte catalogo o altra fonte);
- livello di affidabilità;
- stato: da verificare, confermato o rifiutato.

I dati visibili nella foto vanno distinti dai dati recuperati online e dalle informazioni che solo l'utente può confermare.

## Vincoli tecnici e di sicurezza

- Il progetto usa il database TEST Supabase `eeiekkflpnkummxtvljy`; non eseguire modifiche sul database di produzione `bufwceckrmbocctarthj`.
- PR-12 attuale esegue ricerche di metadati per record incompleti; non considerare già disponibile il riconoscimento visivo end-to-end finché non è implementato e testato.
- La sessione ChatGPT dell'utente non è una credenziale API server-side. Le chiamate a modelli devono usare un provider configurato esplicitamente e segreti conservati sul server.
- Nessuna nuova funzione deve scrivere dati non confermati o aggirare i controlli di conferma e integrità esistenti.
- Non cambiare il contratto delle RPC di scrittura senza averne prima letto e verificato input/output.

## Sequenza di implementazione e test

1. Verificare i flussi attuali di PR-01, PR-04, upload immagini e PR-12, oltre al contratto delle RPC coinvolte.
2. Implementare l'acquisizione foto come punto di partenza e un passaggio esplicito di revisione dei dati riconosciuti.
3. Estendere PR-12 per accettare una ricerca per oggetto nuovo, senza obbligo di record preesistente.
4. Aggiungere la selezione facoltativa dell'immagine di catalogo e la conservazione della provenienza.
5. Aggiungere i consigli fotografici alla schermata che prepara il testo dell'inserzione, senza pubblicazione automatica.
6. Eseguire analisi Flutter e test isolati sul database TEST, verificando che ricerca e anteprima non scrivano dati e che il salvataggio sia esplicito e atomico.

## Criteri minimi di accettazione

- Una foto di un oggetto non presente nel database può produrre candidati PR-12 senza creare un record automaticamente.
- Una foto del codice/etichetta migliora l'identificazione quando il codice è leggibile.
- L'utente può rifiutare tutti i candidati e compilare manualmente.
- L'immagine di catalogo è facoltativa, ha un'anteprima e non elimina la foto originale.
- Le bozze per piattaforma contengono consigli fotografici ma non pubblicano né caricano contenuti.
- I campi incerti e quelli non ricavabili dalla foto restano da confermare.
- I test non toccano il database di produzione.
