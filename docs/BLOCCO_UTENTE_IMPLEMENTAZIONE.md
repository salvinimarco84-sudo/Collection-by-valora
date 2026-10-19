# Blocco UTENTE · piano di implementazione TEST

## Punto di partenza verificato

- Base sorgente: checkpoint `checkpoint/release-164-working`, commit `f4ebb5aeabfe728c5651b1017669979bb61ac977`.
- Branch di lavoro: `feat/blocco-utente`.
- Il client Flutter contiene già accesso email/password, logout e impostazioni grafiche locali.
- Non è ancora presente in `lib/main.dart` una schermata profilo collegata a `collection.master_utente`.
- In Supabase TEST, `collection.master_utente` è vuota e ha RLS attivo. Campi presenti: `codice_utente`, `nome_utente`, `mercato_nazionale_principale`, `valuta_predefinita`, `lingua_interfaccia`, `formato_data`, `data_creazione`, `stato_utente`, `nome_assistente`.
- `mercato_nazionale_principale` referenzia `collection.mercati`, che al controllo risulta vuota. La configurazione iniziale non può quindi offrire mercati reali finché non viene definito e popolato il catalogo TEST.
- L'account Auth autorizzato e il record profilo non sono ancora collegati nel client. Non si deve presumere che il singolo utente sia automaticamente associato alla riga corretta.

## Vincoli non negoziabili

1. Operare esclusivamente sul progetto Supabase TEST `eeiekkflpnkummxtvljy`.
2. Non modificare né interrogare in scrittura la produzione `bufwceckrmbocctarthj`.
3. Non eseguire migrazioni o modifiche alle policy RLS finché non è definito il legame sicuro tra `auth.users.id` e `master_utente`.
4. Non inserire nel client chiavi `service_role`.
5. Non considerare SharedPreferences una fonte autorevole per il profilo: il database deve conservare i dati condivisi fra PC e telefono.

## Dati richiesti nella schermata Profilo

- Nome utente
- Mercato nazionale principale (da catalogo mercati)
- Valuta predefinita (codice ISO 4217, ad esempio EUR)
- Lingua interfaccia
- Formato data
- Nome dell'assistente (facoltativo)
- Stato utente e data di creazione in sola lettura, quando presenti

L'email mostrata deve provenire dalla sessione Supabase Auth e non essere duplicata come campo modificabile del profilo.

## Flusso previsto

1. Dopo il login, controllare se esiste un profilo associato all'utente autenticato.
2. Se manca, mostrare la configurazione iniziale e impedire che l'app dichiari il setup completato.
3. Caricare i mercati dal catalogo TEST; se il catalogo è vuoto, mostrare un messaggio esplicito e non inventare opzioni.
4. Validare i campi prima del salvataggio.
5. Salvare il profilo tramite un percorso autorizzato server-side o policy RLS rigorosamente legate all'utente autenticato.
6. Ricaricare il profilo dal database dopo il salvataggio e applicare lingua, valuta, formato data e mercato alle funzioni pertinenti.
7. Tenere le preferenze grafiche già esistenti separate dal profilo, a meno che non venga deciso esplicitamente di sincronizzarle fra dispositivi.
8. Dopo il primo salvataggio, aprire la configurazione delle piattaforme di vendita come passo successivo, senza modificare i dati dell'archivio oggetti.

## Blocco tecnico da risolvere prima del collegamento DB

La tabella `master_utente` non espone una colonna `user_id` collegata a `auth.users.id`. Con RLS attivo e nessuna riga esistente, il client non può selezionare o aggiornare un profilo in modo affidabile e sicuro senza una strategia esplicita. Le opzioni da valutare sono:

- aggiungere una relazione esplicita `auth_user_id` con vincolo univoco e policy RLS dedicate; oppure
- gestire lettura/creazione/aggiornamento attraverso un'Edge Function autenticata che verifica l'allowlist e lega il profilo all'utente, senza esporre la chiave privilegiata al client.

La scelta va implementata e testata solo in TEST. Non riutilizzare una funzione esistente senza averne verificato il contratto e le autorizzazioni.

## Collaudo di accettazione

- Account non autenticato: nessun accesso al profilo.
- Account autenticato ma non autorizzato: nessun accesso né scrittura.
- Primo accesso autorizzato: viene proposto il setup iniziale, senza creare duplicati.
- Salvataggio valido: viene restituito e riletto lo stesso profilo.
- Campi non validi o mercato inesistente: salvataggio respinto con messaggio leggibile.
- Logout/login e cambio dispositivo: il profilo resta coerente perché riletto dal database.
- Nessuna modifica alle righe di `master_oggetti`, acquisti, vendite o cassa.
- Nessuna chiamata alla produzione.

## Stato di questa revisione

Branch creato dal checkpoint. Questa revisione documenta la ricognizione e i contratti di sicurezza; non ha eseguito scritture sul database né distribuito funzioni. La prossima modifica di codice deve seguire la scelta architetturale sul collegamento account-profilo e il popolamento del catalogo mercati in TEST.
