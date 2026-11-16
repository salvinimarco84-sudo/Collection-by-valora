# Decisione funzionale BL-01 - Esperienza interamente nell'app
## Registro decisioni - D-001

**Data:** 16 novembre 2026  
**Stato:** CONFERMATA DALL'UTENTE  
**Ambito:** prima versione Android di COLLECTION by VALORA

## Decisione

L'esperienza di autenticazione e recupero account deve essere gestita tramite le maschere native dell'app VALORA. L'utente non deve essere indirizzato a pagine web per completare i flussi interattivi.

I messaggi email restano il canale per inviare i link di verifica e recupero, ma il link deve riaprire VALORA tramite deep link Android. L'app gestisce quindi il completamento del flusso e presenta la maschera appropriata.

## Comportamento applicativo

1. **Prima apertura senza sessione:** CORE mostra la schermata iniziale di autenticazione, con le azioni Accedi e Crea account e il collegamento Password dimenticata.
2. **Registrazione:** BL-01 mostra la maschera di registrazione e invia la richiesta a Supabase TEST2.0.
3. **Conferma email:** l'utente riceve l'email; toccando il link, Android apre VALORA. L'app completa/valida la verifica tramite il flusso Supabase e mostra lo stato risultante. Se la verifica non crea una sessione autenticata, l'utente torna alla maschera di accesso.
4. **Accesso riuscito:** CORE sostituisce il ramo di autenticazione con il menu principale.
5. **Aperture successive:** se Supabase ripristina una sessione valida, CORE apre direttamente il menu principale. La maschera di autenticazione non viene mostrata.
6. **Sessione assente, scaduta o revocata:** CORE mostra la schermata iniziale di autenticazione.
7. **Password dimenticata:** il link email riapre VALORA e porta alla maschera Nuova password. Il cambio viene completato nell'app.
8. **Logout:** BL-01 chiude la sessione; CORE torna alla schermata iniziale di autenticazione.

## Responsabilità

- **BL-01 Autenticazione:** registrazione, login, verifica email, recupero/cambio password, logout, sessione ed eventi Auth.
- **CORE:** bootstrap, ripristino iniziale sessione e selezione del ramo di navigazione:
  - non autenticato -> schermate BL-01;
  - autenticato -> menu principale.
- **Menu principale:** non è accessibile senza sessione autenticata.
- **BL-02 Profilo utente:** resta separato dall'autenticazione e viene caricato dopo l'identificazione dell'utente autenticato, tramite contratto.

## Requisiti tecnici conseguenti

- Configurare un deep link Android dedicato e registrarlo tra i redirect consentiti in Supabase TEST2.0.
- L'applicationId Android e lo schema/host/path del deep link devono essere decisi prima di modificare le URL di redirect Supabase.
- Il link email deve trasportare il flusso in modo sicuro; l'app deve validare lo stato tramite Supabase SDK e non fidarsi di parametri arbitrari.
- I token e i codici di verifica non devono essere scritti nei log.
- I casi di link scaduto, già utilizzato, non valido o aperto su dispositivo senza app devono avere un messaggio e un percorso di recupero chiari.
- La sessione deve essere persistita e ripristinata dal client Supabase SDK; non si implementa una persistenza credenziali parallela.
- Nessuna schermata web esterna deve essere necessaria per completare la procedura utente. L'email rimane necessaria come canale di verifica/recupero.

## Criteri di accettazione UX

- Primo avvio senza sessione -> schermata iniziale Accedi/Crea account.
- Login valido -> menu principale, senza passare da una schermata intermedia di autenticazione.
- Chiusura e riapertura con sessione valida -> menu principale direttamente.
- Logout -> schermata iniziale.
- Link di conferma email -> apre VALORA e completa il flusso in-app.
- Link di recupero password -> apre VALORA e mostra la maschera Nuova password.
- Link non valido/scaduto -> messaggio localizzato e ritorno sicuro al flusso di accesso/richiesta nuovo link.

## Stato delle decisioni collegate

- Esperienza in-app: **CONFERMATA**.
- Email come canale per verifica/recupero: **CONFERMATA**.
- ApplicationId Android: **DA DEFINIRE**.
- Tipo e valori precisi deep link: **DA DEFINIRE**.
- Redirect allowlist TEST2.0: **NON MODIFICATA**.
