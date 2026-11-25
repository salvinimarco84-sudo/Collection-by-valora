# VALORA 2.1 — Categorie dinamiche: adeguamento e collaudo TEST2

Data: 25 novembre 2026  
Ambiente autorizzato: Supabase **COLLECTION by VALORA TEST2.0**  
Project ref: `hqiisivoistpejvilbeu`  
Produzione: **non consultata né modificata**.

## 1. Stato di sicurezza iniziale verificato

- Account amministratore presente in `public.master_utenti`: `AMMINISTRATORE`, `ATTIVO`.
- `private.pr_bootstrap_primo_amministratore()` presente e protetta: nessun privilegio EXECUTE a `authenticated` o `anon`.
- Le procedure operative pubbliche verificano `auth.uid()`; le procedure di progettazione/validazione/attivazione richiedono un account `PROPRIETARIO` o `AMMINISTRATORE` con stato `ATTIVO`.
- Le funzioni privilegiate usano `SET search_path TO ''` e riferimenti schema-qualificati.
- Le procedure necessarie al client non sono state revocate a `authenticated`; `anon` non può eseguirle.

## 2. Componenti presenti

Tabelle:
- `master_richieste_nuove_categorie`
- `master_progettazione_nuove_categorie`
- `master_registro_categorie_dinamiche`
- `master_catalogo_dinamico`
- `master_proprieta_dinamiche`

Procedure:
- `pr_richiedi_nuova_categoria(p_richiesta jsonb)`
- `pr_salva_progettazione_nuova_categoria(p_id_richiesta uuid, p_progetto jsonb)`
- `pr_valida_progettazione_nuova_categoria(p_id_progettazione uuid, p_esito text, p_motivazione text)`
- `pr_attiva_nuova_categoria_dinamica(p_id_progettazione uuid)`

Le procedure PR-05 e PR-06 (`pr05_crea_oggetti`, `pr06_modifica_oggetti`, `pr06_modifica_catalogo_dinamico`) contengono già un percorso dinamico. Il trigger `valora_crea_record_catalogo_dinamico_pr05` crea automaticamente il record in `master_catalogo_dinamico` e valorizza `id_record_catalogo` quando PR-05 inserisce la proprietà dinamica. Le categorie codificate 01–09 e 11–21 mantengono la mappatura dei Master esistenti; il codice 10 resta escluso. Le categorie ulteriori vengono risolte attraverso il registro dinamico.

## 3. Regole funzionali verificate

- La richiesta crea una categoria `PROVVISORIA`, privata del richiedente, con struttura iniziale ricavata dal campione.
- La progettazione definisce separatamente schema Master Catalogo, schema Master Proprietà e regole di validazione.
- L'approvazione ufficializza la categoria esistente, la rende `ATTIVA` e condivisa, senza crearne una seconda.
- Il rifiuto porta la categoria a `SOSPESA` e il registro a `DEPRECATA`; non cancella gli oggetti già creati.
- L'integrazione richiesta mantiene la categoria privata e utilizzabile dal richiedente.
- I trigger `trg_valora_notifica_nuova_categoria` e `trg_valora_notifica_esito_categoria` sono presenti sulla tabella delle richieste.

## 4. Correzioni applicate direttamente su TEST2

### 4.1 Visibilità dopo il rifiuto

Aggiornate le policy SELECT per:
- `master_categorie`: il proprietario può leggere la propria categoria `SOSPESA`;
- `master_registro_categorie_dinamiche`: il proprietario può leggere il proprio registro `DEPRECATA`;
- `master_catalogo_dinamico`: il proprietario può leggere i record associati a categorie `DEPRECATA`.

Le categorie `ATTIVE` restano condivise. Le categorie `PROVVISORIE` e `DEPRECATE/SOSPESE` restano visibili al proprietario e agli amministratori autorizzati secondo le policy.

### 4.2 Risposta coerente all'approvazione

Corretta `pr_valida_progettazione_nuova_categoria`: dopo la chiamata alla procedura di attivazione, il JSON restituisce:
- `stato_richiesta = ATTIVATA`;
- `categoria_attivata = true`;
- messaggio che conferma l'ufficializzazione e la condivisione.

Per il rifiuto restituisce `oggetti_esistenti_conservati = true` e conferma la conservazione e l'accessibilità degli oggetti del richiedente.

### 4.3 Protezione dai duplicati

- Creato l'indice univoco `master_categorie_descrizione_normalizzata_key` su `lower(btrim(descrizione))`, dopo aver verificato che non esistessero duplicati normalizzati.
- Spostato il lock transazionale `valora_dynamic_category_code_sequence` prima del controllo duplicati, così il controllo del nome e l'assegnazione del codice avvengono in una sezione serializzata.
- La verifica intercetta differenze di maiuscole/minuscole e spazi iniziali/finali, oltre alla protezione dell'indice univoco.

## 5. Collaudo transazionale

Eseguiti flussi sintetici in transazione, con claim JWT dell'amministratore impostato nella sessione SQL:

1. richiesta nuova categoria;
2. salvataggio blueprint;
3. creazione oggetto con PR-05;
4. modifica oggetto con PR-06;
5. approvazione e verifica dello stato `ATTIVA`;
6. secondo flusso con creazione oggetto;
7. rifiuto con motivazione;
8. verifica oggetto ancora presente;
9. modifica dell'oggetto dopo il rifiuto;
10. verifica delle notifiche di esito;
11. richiesta duplicata con differenze di maiuscole/minuscole e spazi: seconda richiesta respinta;
12. creazione automatica del record Master Catalogo da PR-05 e collegamento a `id_record_catalogo`;
13. modifica Master Catalogo con PR-06 prima e dopo il rifiuto, con verifica di conservazione.

I blocchi PL/pgSQL hanno completato senza eccezioni e con controlli di asserzione superati. Ogni collaudo è terminato con `ROLLBACK`.

Verifica successiva: zero record di test persistenti in richieste, categorie, progettazioni e oggetti. Il controllo duplicati normalizzato ha superato il test dedicato. Anche il trigger di creazione Master Catalogo e la modifica del record catalogo prima/dopo il rifiuto hanno superato il collaudo transazionale.

## 6. Sicurezza e limiti residui

- Le RPC dinamiche rivolte agli utenti mantengono EXECUTE per `authenticated` e negano `anon`; le azioni amministrative verificano il ruolo nel database. Le segnalazioni Advisor sulle funzioni SECURITY DEFINER richiedono revisione puntuale, non una revoca indiscriminata che interromperebbe le RPC legittime.
- Advisor segnala inoltre 12 tabelle con RLS senza policy in altri ambiti/schema. Non sono state modificate perché fuori dal perimetro di questo collaudo.
- Il collaudo SQL ha usato la sessione amministrativa esistente. Non è stato creato o modificato alcun altro account. Resta da eseguire un test applicativo autenticato con un account utente ordinario per certificare la visibilità owner-only e l'assenza di visibilità per gli altri utenti.
- Il repository Android corrente `salvinimarco84-sudo/Collection-by-valora-flutter` documenta TEST2 (`hqiisivoistpejvilbeu`) tramite `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` passate con `--dart-define`; `lib/main.dart` legge entrambe con `String.fromEnvironment`, senza endpoint hardcoded. Il vecchio repository combinato `Collection-by-valora` contiene invece un README storico che cita il progetto TEST precedente e non va usato come riferimento per il nuovo client Android. La build/run effettiva con la publishable key TEST2 e il collaudo HTTP/Flutter non sono inclusi in questa revisione.

## 7. Vincolo operativo

Continuare esclusivamente su TEST2. Non applicare queste modifiche a produzione. Prima di dichiarare concluso il rilascio applicativo, allineare il client all'ambiente TEST2, effettuare login aggiornato e completare il test end-to-end con un utente ordinario e con l'amministratore.
