# PR AGGIORNA CATALOGHI

**VALORA 2.1 · TEST2 · stato: controllo inventariale attivo, aggiornamento dati in preparazione**

## Perimetro iniziale

1. LEGO
2. TRANSFORMERS
3. SAINT SEIYA
4. BARBIE
5. HOT WHEELS
6. FUNKO POP
7. ACTION FIGURES
8. MODEL KIT
9. MODELLISMO STATICO
10. STATUE E FIGURE DA COLLEZIONE
11. G.I. JOE
12. SOUL OF CHOGOKIN

PLAYMOBIL resta escluso fino alla creazione del suo master. SOUL OF CHOGOKIN è trattato come sotto-catalogo di ACTION FIGURES, non come categoria VALORA separata.

## Regole di integrità

- Le immagini non fanno parte di questa procedura: il payload in ingresso elimina ricorsivamente chiavi immagine/foto/thumbnail/avatar.
- Nessuna cancellazione automatica.
- Nessuna sovrascrittura indiscriminata.
- Ogni proposta deve mantenere fonte, identificativo esterno, chiave d'identità, hash del contenuto e confidenza.
- Le modifiche vengono prima registrate in staging e sottoposte a revisione.
- I conflitti e i duplicati potenziali non vengono applicati automaticamente.
- I master personali non devono essere usati come cataloghi condivisi.
- Fonti ufficiali candidate sono registrate come inattive e non verificate finché accesso, copertura, termini e stabilità non siano stati collaudati.

## Oggetti Supabase

- `pr_cataloghi_configurazione`: mapping master, campi identificativi/protetti, soglia di confidenza.
- `pr_cataloghi_fonti`: fonti, priorità, configurazione di accesso e stato di verifica.
- `pr_cataloghi_esecuzioni`: storico delle esecuzioni.
- `pr_cataloghi_dettaglio`: risultati per catalogo.
- `pr_cataloghi_proposte`: staging dei record candidati.
- `pr_cataloghi_audit_campi`: registro delle decisioni a livello di campo.
- `pr_cataloghi_fonti_log`: log accessi, errori, rate limit e conteggi.

## Funzioni

- `pr_cataloghi_esegui_controllo('MANUALE'|'PROGRAMMATA')`: controllo non distruttivo e report.
- `pr_cataloghi_registra_proposta(...)`: ingresso riservato a `service_role`; rimuove immagini e inserisce proposte, senza scrivere nei master.
- `pr_cataloghi_decidi_proposta(id,'APPROVA'|'RIFIUTA',...)`: decisione amministrativa tracciata. L'approvazione non scrive direttamente nel master.
- `pr_cataloghi_esegui_se_orario_locale()`: esegue il controllo solo il giorno 1 alle 03:00 Europe/Rome.

## Pianificazione

Supabase Cron è configurato con un controllo orario UTC; il wrapper verifica il calendario locale Europe/Rome ed esegue solo il giorno 1 alle 03:00 locali. Questo evita lo slittamento dell'ora dovuto all'ora legale senza richiedere il riavvio del database per cambiare `cron.timezone`.

## Limiti e completamenti necessari

La prima fase non effettua ancora crawling né importazione automatica. Le fonti candidate sono inattive e non verificate. Occorre implementare adattatori per fonte, testare paginazione/rate limit/termini d'uso, normalizzazione e chiavi d'identità, quindi un validatore di applicazione specifico per ogni master. Il passaggio staging → master deve essere abilitato solo dopo test di conflitto, idempotenza, audit e rollback.

Quattro categorie restano in attesa del master catalografico condiviso: HOT WHEELS, MODEL KIT, MODELLISMO STATICO, STATUE E FIGURE DA COLLEZIONE. PLAYMOBIL sarà aggiunto successivamente.


## Collaudo TEST2 del 22/11/2026

- Ultima esecuzione manuale: `c5b86ae3-d7ff-4f52-986d-12cb1c30f1d5`.
- Esito: `COMPLETATA_CON_BLOCCHI`; 12 cataloghi controllati, 8 mapping ispezionabili, 4 master condivisi mancanti.
- Conteggi letti: LEGO 1.906; Transformers 3.301; Saint Seiya 601; Barbie 3.204; Funko Pop 7.336; Action Figures 166; G.I. Joe 3.469; Soul of Chogokin 166 (sottoinsieme filtrato). I conteggi sono fotografia dell'esecuzione e possono variare.
- Fonti candidate registrate: 22; fonti attive: 0; tutte richiedono validazione.
- Cron job attivo: ID 2, esecuzione oraria con wrapper che applica il controllo solo alle 03:00 Europe/Rome del giorno 1.
- Verificato il filtro ricorsivo immagini: chiavi `immagine` e `photo_url` vengono rimosse dal payload.

## Sicurezza e comportamento

La proposta richiede una fonte attiva e associata al catalogo. L'approvazione amministrativa genera audit per campo ma non aggiorna il master: il validatore specifico per catalogo e il controllo di concorrenza devono essere implementati e testati prima di consentire scritture.
