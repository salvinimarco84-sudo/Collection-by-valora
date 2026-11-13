# PR-15 PREORDER · Contratto funzionale e flusso approvato

Stato: modulo applicativo scorporato e database TEST presenti; attivazione subordinata al completamento dei collaudi CI, Android e Windows.

## Obiettivo e confini
PR-15 gestisce esclusivamente oggetti prenotati e non ancora ricevuti. Non è una wishlist né un acquisto già acquisito. Deve avere moduli autonomi per creazione, elenco, dettaglio, pagamenti e chiusura. PR-18 e PR-14 non partecipano. PR-04 ordinaria non viene modificata: è richiamata solo alla conversione, usando il suo normale flusso di salvataggio.

## Flusso
1. ACQUISTI > PR-15 PREORDER > Nuovo preorder / Archivio preorder.
2. Nuovo preorder: descrizione oggetto, categoria, fornitore, data ordine, uscita prevista, prezzo concordato, eventuale acconto, immagine, note e riferimenti. Conferma esplicita.

## Immagini preorder
- Dalla scheda dettaglio è disponibile RICERCA IMMAGINE / CAMBIA IMMAGINE.
- La ricerca apre Google Immagini con la descrizione del preorder; l'utente seleziona il risultato e incolla l'URL HTTPS diretto del file.
- L'app scarica e valida JPEG, PNG o WebP (massimo 10 MB), carica il file nel bucket privato `pr01-foto-temporanee` e registra il collegamento nella tabella condivisa `immagini_oggetto` tramite `collection-object-images-test` con `target_type=preorder`.
- La funzione verifica autenticazione e proprietà del preorder. La ricerca non usa PR-12 né crediti AI.
- La scheda mostra l'immagine principale con URL firmato. Le immagini non vengono duplicate in tabelle specifiche del preorder.
3. La scheda preorder conserva pagamenti con identificatore univoco, data, importo, mezzo e riferimento; mostra totale versato e saldo residuo calcolati. Non deve conteggiare l'oggetto nel patrimonio o nel catalogo disponibile.
4. L'utente aggiorna stato e pagamenti, eventualmente modifica la data prevista o annulla la prenotazione. Rimborsi e storni devono conservare uno storico auditabile.
5. Solo dopo ricezione, il comando CHIUDI PREORDER apre la normale PR-04 precompilata con dati e costo effettivo. L'utente conferma nella PR-04.
6. Soltanto a seguito di salvataggio PR-04 verificato, il preorder passa a CHIUSO_CONVERTITO, memorizza il riferimento all'acquisto e scompare dagli attivi. Se PR-04 viene annullata o fallisce, il preorder resta aperto.
7. Da quel momento l'oggetto è un acquisto ordinario, con modifica, valutazione, vendita e report ordinari. Lo storico del preorder resta consultabile separatamente.

## Stati
PRENOTATO, ACCONTO_VERSATO, IN_ATTESA_USCITA, DISPONIBILE, IN_SPEDIZIONE, RICEVUTO, CHIUSO_CONVERTITO, ANNULLATO, RIMBORSATO.
Gli stati di pagamento sono distinti dallo stato logistico: un preorder può essere saldato pur restando in attesa.

## Invarianti
- Prezzo concordato e costo finale effettivo sono distinti; acconti e saldi sono quote del costo, non costi aggiuntivi.
- Nessuna duplicazione dei movimenti di cassa: la conversione collega le transazioni già registrate e crea solo eventuali movimenti mancanti, con idempotenza.
- Una prenotazione può essere convertita in un solo acquisto: vincolo di unicità e transazione atomica lato backend da progettare e verificare su TEST.
- Nessuna scrittura diretta sul database di produzione durante sviluppo e collaudo.
- La chiusura senza ricezione non crea un acquisto.
- L'accesso ai preorder è isolato per utente secondo le policy del progetto.

## Collaudi minimi prima dell'attivazione
Creazione e lettura su TEST; acconto e saldo; rimborso; modifica; annullamento; mancata conferma PR-04; errore di rete; doppio click di conversione; riconciliazione di cassa; ricezione e singola creazione acquisto; storico e isolamento utenti; CI Flutter e build Android/Windows.
