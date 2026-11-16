# BL-01 - Autenticazione
## Specifica funzionale e tecnica - Versione 0.1

**Stato:** BOZZA DA APPROVARE  
**App:** COLLECTION by VALORA - Flutter Android  
**Ambiente consentito:** Supabase TEST2.0 (`hqiisivoistpejvilbeu`)  
**Repository:** `salvinimarco84-sudo/Collection-by-valora`  
**Branch:** `feature/flutter-android-test2-fresh`  
**Dipendenze:** CORE (configurazione, navigazione, localizzazione, gestione errori); BL-02 Profilo utente solo tramite evento/contratto concordato.

---

## 1. Scopo e confini

BL-01 è l'unico proprietario dei flussi di identità e sessione dell'utente.

### Incluso
- Registrazione con email e password.
- Conferma dell'indirizzo email.
- Accesso con email e password.
- Uscita dall'account.
- Ripristino password tramite email.
- Impostazione della nuova password dopo il ripristino.
- Cambio password da sessione autenticata.
- Ripristino e osservazione della sessione all'avvio.
- Gestione degli stati autenticativi e degli errori.
- Integrazione con il redirect/deep link Android.

### Escluso
- Modifica dei dati anagrafici e delle preferenze: BL-02.
- Creazione o modifica manuale del profilo: BL-02.
- Catalogo, acquisti, vendite, crediti e valutazioni.
- Login anonimo, telefono e provider social nella prima versione.
- Pannello amministrativo per utenti.

BL-01 non decide quali schermate funzionali l'utente possa usare in base al piano commerciale. Espone identità e stato sessione; autorizzazioni e diritti applicativi sono responsabilità dei rispettivi blocchi/backend.

## 2. Configurazione Supabase TEST2.0 già rilevata

Queste impostazioni risultano verificate in precedenza tramite la console TEST2.0 e vanno ricontrollate prima del collaudo end-to-end:

- Provider Email abilitato.
- Registrazione nuovi utenti abilitata.
- Conferma email obbligatoria abilitata.
- Accesso anonimo disabilitato.
- Provider telefono e social non attivati.
- Password minima 8 caratteri.
- Requisiti password: almeno una minuscola, una maiuscola, un numero e un simbolo.
- Secure email change attivo.
- Secure password change attivo.
- Richiesta password corrente durante l'aggiornamento disattivata per ora.
- Site URL rilevato: `http://localhost:3000`.
- Redirect URLs non risultavano configurati nello screenshot precedente.

**Vincolo:** non modificare ora Site URL o Redirect URLs. Prima si definiscono applicationId e schema deep link Android, poi si aggiorna la allowlist con valori esatti.

## 3. Procedure BL-01

### AUTH-01 - Registrazione
1. L'utente apre la maschera Registrazione.
2. Inserisce email, password e conferma password.
3. L'app verifica formato email, corrispondenza password/conferma e requisiti password configurati.
4. L'app invia la richiesta a Supabase Auth usando esclusivamente il progetto TEST2.0.
5. In caso di esito positivo, l'app mostra l'indicazione di controllare la casella email.
6. L'utente apre il link ricevuto. Il link deve tornare all'app tramite redirect Android autorizzato.
7. L'app riceve e completa la verifica secondo il flusso Supabase scelto e mostra lo stato risultante.
8. L'utente può quindi accedere.

**Regole:** non mostrare mai la password in chiaro; non registrare password o token nei log; non dichiarare account verificato finché Supabase non conferma lo stato.

**Profilo:** il profilo base è creato dal trigger backend `on_auth_user_created_profile` già predisposto in TEST2.0. Il client non deve inserire una seconda riga in `public.profili_utenti`.

### AUTH-02 - Accesso
1. L'utente inserisce email e password.
2. Il sistema valida i campi obbligatori.
3. BL-01 invia le credenziali a Supabase Auth.
4. Se la verifica email è obbligatoria e non completata, l'accesso deve essere trattato secondo la risposta effettiva di Supabase e presentare un messaggio comprensibile.
5. In caso di successo, BL-01 pubblica lo stato autenticato e consegna il controllo alla navigazione CORE.
6. In caso di errore, resta sulla maschera e mostra un messaggio localizzato senza esporre dettagli interni.

### AUTH-03 - Ripristino password
1. Dalla maschera Accesso, l'utente sceglie “Password dimenticata”.
2. Inserisce l'indirizzo email.
3. BL-01 richiede a Supabase l'invio del messaggio di ripristino con redirect Android autorizzato.
4. L'app conferma l'invio senza rivelare se l'indirizzo è registrato.
5. L'utente apre il link email e rientra nell'app.
6. BL-01 verifica che il flusso di recupero sia valido e presenta la maschera Nuova password.
7. L'utente inserisce nuova password e conferma.
8. BL-01 aggiorna la password tramite sessione/flow di recupero valido e mostra conferma.

### AUTH-04 - Cambio password con sessione attiva
1. L'utente autenticato apre la funzione di sicurezza account.
2. BL-01 richiede la nuova password e la conferma.
3. Il requisito di password corrente resta coerente con la configurazione TEST2.0 vigente, attualmente disattivata.
4. BL-01 invia l'aggiornamento a Supabase Auth.
5. Mostra esito positivo o errore localizzato.

### AUTH-05 - Uscita
1. L'utente seleziona Esci.
2. BL-01 richiede la chiusura della sessione a Supabase.
3. Dopo conferma dell'esito, pubblica stato non autenticato.
4. CORE riporta alla schermata di accesso.
5. I dati privati in memoria dell'app devono essere invalidati o ricaricati al cambio utente.

### AUTH-06 - Ripristino sessione all'avvio
1. CORE inizializza Supabase con URL e publishable key TEST2 passati tramite configurazione esterna.
2. BL-01 legge lo stato sessione gestito dal client Supabase.
3. Se esiste una sessione valida, pubblica stato autenticato.
4. Se non esiste una sessione, pubblica stato non autenticato.
5. Se il refresh fallisce o il token è invalido, gestisce il ritorno allo stato non autenticato senza loop di navigazione.
6. Le schermate non devono implementare controlli token autonomi.

### AUTH-07 - Cambio stato autenticativo
BL-01 ascolta gli eventi Auth del client Supabase e li trasforma in uno stato applicativo stabile. Gli altri blocchi non devono ascoltare direttamente Supabase Auth o mantenere copie divergenti della sessione.

Stati applicativi minimi:
- `initializing`
- `signedOut`
- `emailConfirmationPending` (stato UI del flusso registrazione, non sostituisce lo stato server)
- `signedIn`
- `passwordRecovery`
- `failure` (errore recuperabile, con messaggio localizzato)

## 4. Maschere di BL-01

| ID | Maschera | Elementi principali | Azioni |
|---|---|---|---|
| AUTH-UI-01 | Accesso | Email, password, mostra/nascondi password | Accedi, vai a registrazione, password dimenticata |
| AUTH-UI-02 | Registrazione | Email, password, conferma password, requisiti password | Crea account, torna ad accesso |
| AUTH-UI-03 | Verifica email | Istruzioni, indirizzo destinatario mascherato | Ho verificato / reinvia email (se abilitato e definito) |
| AUTH-UI-04 | Password dimenticata | Email | Invia link, torna ad accesso |
| AUTH-UI-05 | Nuova password | Nuova password, conferma, requisiti | Salva nuova password |
| AUTH-UI-06 | Sicurezza account | Stato account e cambio password | Cambia password, esci |
| AUTH-UI-07 | Stato sessione | Caricamento, sessione valida, sessione scaduta | Prosegui o torna ad accesso |

Le maschere devono essere dedicate e composte da widget locali al blocco. Non concentrare i flussi in un'unica schermata con condizioni annidate.

## 5. Validazioni

### Email
- Obbligatoria.
- Spazi iniziali/finali rimossi.
- Controllo sintattico client di base; la validazione definitiva è del server.
- Messaggi non devono rivelare se un account esiste.

### Password
Allineare la validazione client alla policy effettiva TEST2.0:
- minimo 8 caratteri;
- almeno una lettera minuscola;
- almeno una lettera maiuscola;
- almeno una cifra;
- almeno un carattere speciale.

La validazione client migliora l'esperienza ma non sostituisce quella server.

### Conferma password
- Obbligatoria in registrazione e reset.
- Deve corrispondere esattamente alla password.
- Non viene inviata come campo separato ad Auth.

## 6. Modelli e dati

### Dati Auth
L'identità canonica è gestita da `auth.users` in Supabase. Il client non crea né modifica direttamente righe in questa tabella.

Dati minimi esposti al client:
- identificativo utente UUID;
- email, se disponibile;
- stato sessione;
- timestamp di scadenza/access token solo se fornito dal client SDK e necessario;
- eventuale stato di verifica email fornito dal modello Auth SDK.

Non replicare password, token di refresh o credenziali in tabelle applicative.

### Profilo base
Tabella esistente su TEST2.0: `public.profili_utenti`.
- `id_utente uuid primary key references auth.users(id) on delete cascade`
- `created_at timestamptz not null default now()`

Il trigger `on_auth_user_created_profile` richiama `private.handle_new_user()` dopo l'inserimento di un utente Auth.

BL-01 non è proprietario della tabella profilo. Il trigger è responsabilità backend; BL-02 ne sarà il proprietario funzionale.

## 7. Contratti e collegamenti

### In ingresso
- CORE chiama il bootstrap BL-01 e osserva lo stato autenticativo.
- Le schermate CORE richiedono a BL-01 le azioni di accesso/uscita senza chiamare Supabase Auth direttamente.

### In uscita
- BL-01 espone uno stato autenticativo osservabile e un identificativo utente.
- CORE usa lo stato per scegliere il ramo di navigazione.
- BL-02 riceve l'identificativo utente autenticato tramite contratto applicativo e legge il proprio profilo attraverso il proprio repository.
- Gli altri blocchi ricevono il contesto utente tramite contratti condivisi, mai attraverso letture dirette di dettagli interni di BL-01.

### Regola di dipendenza
`presentation -> domain -> data` all'interno di BL-01. Le schermate non importano il client Supabase direttamente. L'accesso a Supabase è confinato all'adapter/repository Auth del blocco.

## 8. Sicurezza

- Usare solo URL e publishable key di TEST2.0.
- Passare configurazione via ambiente/build define o meccanismo sicuro equivalente.
- Mai includere service_role o secret key nell'app.
- Mai scrivere password, OTP, access token, refresh token o link di recupero nei log.
- Non memorizzare manualmente password.
- Usare il client SDK ufficiale per persistenza e refresh sessione.
- Richiedere HTTPS per comunicazioni remote.
- RLS resta obbligatoria su ogni tabella applicativa privata.
- Il client non deve poter creare o modificare direttamente profili di altri utenti.
- Gestire correttamente cambio account: cancellare cache/dati in memoria appartenenti all'utente precedente.
- Messaggi utente non devono esporre stack trace, query o dettagli interni.

## 9. Localizzazione e accessibilità

Lingue obbligatorie per tutte le maschere e messaggi:
- Italiano (`it`)
- Inglese (`en`)
- Francese (`fr`)
- Tedesco (`de`)
- Spagnolo (`es`)
- Portoghese (`pt`)
- Cinese mandarino (`zh`)
- Giapponese (`ja`)

Non usare dizionari ad hoc dentro i widget. Le stringhe devono risiedere nel sistema di localizzazione centralizzato CORE, con chiavi tipizzate o equivalenti e test di completezza per tutte le lingue.

Requisiti UI:
- etichette persistenti, non solo placeholder;
- errori associati al campo corretto;
- supporto screen reader e dimensione testo;
- indicatori di caricamento e blocco doppio invio;
- password mostra/nascondi;
- layout Android adattabile a tastiera e schermi differenti.

## 10. Test e criteri di accettazione

### Test unitari
- validazione email;
- validazione password per ogni requisito;
- conferma password corrispondente/non corrispondente;
- mapping degli errori Auth in codici applicativi;
- transizioni di stato;
- gestione eventi sessione.

### Test widget
- rendering corretto di ciascuna maschera;
- navigazione tra accesso, registrazione e recupero;
- campi obbligatori e messaggi;
- pulsanti disabilitati durante invio;
- localizzazione su tutte le 8 lingue;
- accessibilità essenziale.

### Test integrazione TEST2.0
Da eseguire con account email dedicati di test, non con account personali reali:
1. registrazione valida;
2. verifica email da dispositivo Android;
3. accesso prima/dopo verifica, verificando la risposta effettiva della configurazione;
4. verifica presenza di una sola riga profilo generata dal trigger;
5. recupero password via link;
6. cambio password;
7. logout e successivo login;
8. ripristino sessione dopo riavvio;
9. isolamento RLS: utente A non legge/modifica il profilo di utente B;
10. utente anonimo non legge profili;
11. cambio account non mostra dati in cache del precedente utente.

### Criteri per dichiarare BL-01 COMPLETATO
- Tutte le procedure incluse implementate e testate.
- Tutte le maschere dedicate e collegate correttamente.
- Tutte le 8 lingue verificate.
- Deep link Android funzionante con redirect allowlist TEST2.
- Trigger profilo verificato con account reale di test.
- Test RLS superati.
- Build Android e test automatici verdi.
- Documentazione aggiornata.
- Nessun accesso a TEST1 o produzione.

## 11. Dipendenze e prerequisiti bloccanti

Prima di implementare i flussi email end-to-end occorre decidere e registrare:
1. applicationId Android definitivo;
2. schema deep link (custom scheme oppure Android App Links HTTPS);
3. host/path esatti del redirect;
4. configurazione template email Supabase per conferma e recupero;
5. configurazione SMTP di invio e deliverability da usare per i test;
6. politica di reinvio email e relativo intervallo;
7. comportamento UI desiderato dopo conferma email.

Non modificare le URL di redirect Supabase finché questi valori non sono stati approvati.

## 12. Questioni da approvare

- [ ] Approvare le sette maschere proposte.
- [ ] Confermare che la prima versione usa solo email/password.
- [ ] Scegliere applicationId Android.
- [ ] Scegliere strategia deep link: schema personalizzato oppure Android App Links HTTPS.
- [ ] Decidere se includere “ricordami” (la persistenza sessione SDK può essere predefinita senza esporre un'opzione).
- [ ] Decidere se prevedere cancellazione account nell'app o rinviarla a una fase successiva.
- [ ] Confermare la politica di reinvio email.
- [ ] Confermare che il profilo base venga creato esclusivamente dal trigger backend già predisposto.

---

## Registro stato

| Elemento | Stato |
|---|---|
| Specifica BL-01 | BOZZA |
| Implementazione | NON AVVIATA secondo questa specifica |
| Deep link Android | DA DEFINIRE |
| Test account end-to-end | NON ESEGUITI |
| Trigger profilo con account reale | NON VERIFICATO |
| Test RLS multiutente | NON ESEGUITI |

**Questa specifica non attesta che i flussi siano implementati o collaudati. La base UI provvisoria già presente nel branch non è considerata implementazione approvata di BL-01.**
