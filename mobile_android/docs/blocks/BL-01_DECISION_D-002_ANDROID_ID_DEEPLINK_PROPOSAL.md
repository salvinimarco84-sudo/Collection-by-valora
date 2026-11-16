# Proposta tecnica - Identità Android e deep link
## BL-01 / CORE - Decisione D-002 (in attesa di conferma)

**Stato:** PROPOSTA, NON APPROVATA  
**Ambito:** prima versione Android  
**Ambiente backend:** Supabase TEST2.0 esclusivamente

## 1. Proposta

Per mantenere coerenti identificativo Android e schema di callback, si propone:

- Android `applicationId`: `com.demonsoftwarehouse.valora`
- Deep link scheme: `com.demonsoftwarehouse.valora`
- Callback di autenticazione: `com.demonsoftwarehouse.valora://auth-callback`

Questi valori sono una proposta tecnica basata sul marchio DEMON SOFTWARE HOUSE / VALORA. Non implicano che esista o sia posseduto un dominio internet corrispondente.

## 2. Perché custom scheme nella prima versione

La prima versione è esclusivamente Android e non è stato indicato un dominio web ufficiale da usare per Android App Links.

Un custom URL scheme:
- consente al link email di riaprire direttamente l'app installata;
- è supportato da Android e da `supabase_flutter`;
- non richiede di pubblicare un file `assetlinks.json` su un dominio;
- può essere registrato come redirect consentito nelle impostazioni Auth di Supabase TEST2.0.

Il reverse-domain scheme è la convenzione raccomandata negli esempi ufficiali Supabase per ridurre il rischio di collisioni con schemi generici.

**Limite:** un custom scheme non offre la verifica del dominio garantita dagli Android App Links. Se in futuro sarà disponibile un dominio ufficiale controllato dal progetto, si potrà valutare il passaggio ad Android App Links HTTPS come miglioramento separato.

## 3. Percorsi email

Si propone di usare lo stesso callback per:
- conferma email;
- recupero password.

L'app distingue il tipo di flusso tramite i parametri/codice gestiti dal client Supabase e mostra la maschera appropriata:
- conferma email -> esito verifica e ritorno alla schermata di accesso, se non esiste una sessione valida;
- recupero password -> maschera Nuova password.

Non si devono inserire token o credenziali nei log. I parametri ricevuti devono essere gestiti dal client Supabase SDK secondo il flusso supportato dalla versione scelta.

## 4. Configurazioni che seguiranno l'approvazione

Solo dopo conferma esplicita:
1. impostare `applicationId` nel progetto Android;
2. registrare nel manifest Android il filtro VIEW/BROWSABLE per scheme e host;
3. verificare la ricezione del link con app installata;
4. aggiungere `com.demonsoftwarehouse.valora://auth-callback` alla allowlist Redirect URLs di Supabase TEST2.0;
5. passare il redirect esatto a `signUp` e `resetPasswordForEmail`;
6. verificare i template email e il comportamento di conferma/reset;
7. collaudare link validi, scaduti, già usati e non validi.

**Non eseguire ancora nessuno di questi cambiamenti.** La Site URL TEST2.0 attualmente rilevata (`http://localhost:3000`) non viene modificata in questa proposta.

## 5. Riferimenti tecnici ufficiali

- Supabase Native Mobile Deep Linking: https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter
- Supabase Flutter signUp: https://supabase.com/docs/reference/dart/auth-signup
- Supabase Redirect URLs: https://supabase.com/docs/guides/auth/redirect-urls
- supabase_flutter deep links: https://pub.dev/documentation/supabase_flutter/latest/index.html

## 6. Decisione richiesta

Confermare o correggere:
- [ ] `applicationId = com.demonsoftwarehouse.valora`
- [ ] callback = `com.demonsoftwarehouse.valora://auth-callback`
- [ ] custom scheme per la prima release Android; eventuali Android App Links HTTPS saranno valutati quando esisterà un dominio ufficiale.

Finché la decisione non è confermata, applicationId, manifest Android e redirect Supabase restano invariati.
