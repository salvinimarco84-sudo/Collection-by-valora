# Decisione tecnica - Identità Android e deep link
## BL-01 / CORE - Decisione D-002

**Stato:** CONFERMATA DALL'UTENTE  
**Data conferma:** 16 novembre 2026  
**Ambito:** prima versione Android  
**Ambiente backend:** Supabase TEST2.0 esclusivamente

## 1. Decisione approvata

Sono confermati i seguenti valori:

- Android `applicationId`: `com.demonsoftwarehouse.valora`
- Deep link scheme: `com.demonsoftwarehouse.valora`
- Callback di autenticazione: `com.demonsoftwarehouse.valora://auth-callback`
- Strategia prima release: custom URL scheme Android.

La conferma riguarda questi identificativi e la scelta del custom scheme per la prima release. Non autorizza modifiche a produzione, TEST1, merge o deploy verso `main`.

## 2. Motivazione e limiti

La prima versione è esclusivamente Android e non è stato indicato un dominio web ufficiale da usare per Android App Links.

Il custom URL scheme consente al link email di riaprire l'app installata, è supportato da Android e da `supabase_flutter`, e non richiede un file `assetlinks.json` su un dominio.

**Limite:** un custom scheme non offre la verifica del dominio garantita dagli Android App Links. Se in futuro sarà disponibile un dominio ufficiale controllato dal progetto, si potrà valutare il passaggio ad Android App Links HTTPS come miglioramento separato.

## 3. Flussi email

Lo stesso callback sarà usato per:
- conferma email;
- recupero password.

L'app dovrà distinguere i flussi tramite i parametri/codice gestiti dal client Supabase e mostrare la maschera appropriata:
- conferma email: esito verifica e ritorno alla schermata di accesso, se non esiste una sessione valida;
- recupero password: maschera Nuova password.

I token e le credenziali non devono essere inseriti nei log. I parametri ricevuti devono essere gestiti dal client Supabase SDK secondo il flusso supportato dalla versione scelta.

## 4. Passi tecnici successivi

1. Impostare `applicationId` nel progetto Android.
2. Registrare nel manifest Android il filtro VIEW/BROWSABLE per scheme e host.
3. Verificare la ricezione del link con app installata.
4. Aggiungere `com.demonsoftwarehouse.valora://auth-callback` alla allowlist Redirect URLs di Supabase TEST2.0.
5. Passare il redirect esatto a `signUp` e `resetPasswordForEmail`.
6. Verificare i template email e il comportamento di conferma/reset.
7. Collaudare link validi, scaduti, già usati e non validi.

Le attività di implementazione e configurazione non sono dichiarate completate da questa decisione. Ogni modifica backend sarà limitata al progetto Supabase TEST2.0 (`hqiisivoistpejvilbeu`). La Site URL TEST2.0 (`http://localhost:3000`) non va modificata senza una necessità specifica.

## 5. Riferimenti tecnici

- Supabase Native Mobile Deep Linking: https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter
- Supabase Flutter signUp: https://supabase.com/docs/reference/dart/auth-signup
- Supabase Redirect URLs: https://supabase.com/docs/guides/auth/redirect-urls
- supabase_flutter: https://pub.dev/documentation/supabase_flutter/latest/index.html

## 6. Registro

- Decisione D-002: CONFERMATA.
- applicationId e callback: approvati.
- Implementazione Android: NON ANCORA ESEGUITA.
- Redirect Supabase TEST2.0: NON ANCORA CONFIGURATO.
- Test deep link e flussi email: NON ANCORA ESEGUITI.
- Produzione, TEST1 e branch `main`: non modificati.
