COLLECTION by VALORA — PACCHETTO RUN 44 / SEZIONE OGGETTO

BASE
Sorgente ricostruito dalla Run 44, commit d1cefe8949edd95ea14f093c468377d52861f10c. Non usare Run 46.

FILE DA CARICARE NELLA RADICE DEL REPOSITORY
- FLAT__lib__main.dart (sorgente Run 44 con tessera OGGETTO e menu dedicato)
- FLAT__pubspec.yaml (dipendenze originali)
- valora_logo.png
- apply_valora_logo.py (mantenere quello già presente nel repository)

WORKFLOW
Il file collection-by-valora-build.yml incluso è la versione corretta da sostituire in .github/workflows/collection-by-valora-build.yml. Il workflow usa i file piatti, controlla che esistano e tenta analisi e build APK.

STATO FUNZIONALE
- Layout Run 44 mantenuto come base.
- Sezione OGGETTO aggiunta con PR-01, PR-02, PR-03, PR-11 e consultazioni.
- PR-01 apre il modulo di bozza già presente, ma il salvataggio rimane disabilitato.
- PR-02, PR-03, PR-11 e le consultazioni sono intenzionalmente disabilitate finché il collegamento runtime TEST non è collaudato end-to-end.
- Nessuna scrittura a Supabase eseguita dal pacchetto. Nessuna modifica alla produzione.

VERIFICA
Sono stati eseguiti controlli statici sul contenuto del pacchetto. Flutter non è disponibile nell'ambiente di preparazione, quindi questa consegna NON dichiara compilazione Android riuscita. Dopo il caricamento, il workflow GitHub deve completare flutter analyze e flutter build apk --release.
