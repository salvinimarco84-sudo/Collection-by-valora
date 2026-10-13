COLLECTION by VALORA — ambiente di sviluppo iniziale
Questo archivio è un kit di avvio dell'ambiente, non una build dell'applicazione completa. Include il manuale operativo v34 recuperato dalla libreria, una struttura Flutter iniziale e una pipeline GitHub Actions per verificare il progetto.
Regole di sicurezza
L'ambiente deve puntare esclusivamente a Supabase TEST.
Non inserire mai chiavi service_role nel client Flutter.
Non includere token, password o segreti nel repository.
Non usare dati reali durante i test automatici.
La produzione resta fuori dal perimetro.
Requisiti locali
Flutter stable
Git
Account GitHub con un repository privato
Progetto Supabase TEST autorizzato
Configurazione
Copia config.example.json in config.json solo in locale e inserisci l'URL e la chiave pubblicabile del progetto TEST. Non committare config.json. Il codice di esempio non esegue scritture sul database: serve a verificare che l'app si avvii e a preparare la pipeline.
GitHub Actions
Il workflow flutter-ci.yml esegue flutter pub get, flutter analyze, flutter test e crea un APK debug. La build Windows viene tentata su runner Windows. I risultati effettivi sono validi solo dopo l'esecuzione del workflow su GitHub.
Limite noto
Questo kit non è il sorgente completo dell'app già sviluppata e non certifica le procedure SQL né l'integrazione runtime. Il sorgente originale non è stato trovato tra i repository GitHub accessibili. Prima del collaudo end-to-end, integrare qui il codice effettivo e le chiamate alle procedure autorizzate.
