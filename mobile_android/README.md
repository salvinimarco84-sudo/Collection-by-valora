# COLLECTION by VALORA - Android (TEST2)

Nuovo progetto Flutter indipendente dal vecchio client. In questa fase è previsto esclusivamente Android.

## Ambiente
- Supabase TEST2: project ref `hqiisivoistpejvilbeu`
- API URL: `https://hqiisivoistpejvilbeu.supabase.co`
- Nessun collegamento a TEST1 o produzione.
- Le chiavi vengono passate in fase di esecuzione, mai salvate nel repository.

## Avvio locale
Da questa directory, dopo aver installato Flutter:

```bash
flutter create . --platforms=android --project-name valora_mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://hqiisivoistpejvilbeu.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<TEST2_PUBLISHABLE_KEY>
```

Usare esclusivamente la publishable key di TEST2. Non inserire mai service_role o secret key nell'app.

## Stato del primo blocco
- Shell Flutter nuova e separata.
- Dipendenza Supabase Flutter.
- Schermata iniziale login/registrazione.
- Validazione locale dei requisiti password configurati in TEST2.
- Prime stringhe UI presenti in italiano, inglese, francese, tedesco, spagnolo, portoghese, cinese mandarino e giapponese.

## Da completare prima del collaudo end-to-end
- Generare e verificare lo scaffold Android con Flutter SDK.
- Configurare Android App Links/deep links e redirect email.
- Aggiungere conferma password, recupero password e schermata sessione.
- Testare trigger di creazione profilo e isolamento RLS con account dedicati TEST2.
