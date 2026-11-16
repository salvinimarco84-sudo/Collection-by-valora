# COLLECTION by VALORA
## Documento architetturale - Versione 0.1 (bozza da approvare)

**Stato:** proposta iniziale, non approvata  
**Ambiente:** esclusivamente Supabase TEST2.0  
**Client iniziale:** nuova applicazione Flutter, solo Android  
**Repository:** `salvinimarco84-sudo/Collection-by-valora`  
**Branch di lavoro:** `feature/flutter-android-test2-fresh`

---

## 1. Scopo

Costruire una nuova applicazione VALORA da zero, con moduli separati e responsabilità stabili. Il codice non deve crescere in un unico `main.dart`, né richiedere continui spostamenti o riscritture per introdurre nuove funzioni.

Questo documento definisce le regole architetturali e la prima mappa dei blocchi. Non autorizza modifiche a TEST1, produzione, né merge o deploy.

## 2. Regole non negoziabili

1. **Un blocco, una responsabilità.** Ogni blocco possiede le proprie procedure, maschere, modelli, servizi, collegamenti e test.
2. **Nessuna logica applicativa in `main.dart`.** Il punto di ingresso inizializza soltanto configurazione e applicazione.
3. **Confini espliciti.** Un blocco usa gli altri attraverso contratti/interfacce dichiarati, non importando liberamente dettagli interni.
4. **Nessun accoppiamento circolare.** Le dipendenze devono seguire una direzione definita.
5. **Niente duplicazioni.** Componenti condivisi vivono in un nucleo comune; non vengono copiati nei singoli blocchi.
6. **Test per blocco.** Ogni blocco ha test unitari, test dei flussi e, dove serve, test d'integrazione.
7. **Traduzione contestuale.** Ogni nuova maschera e ogni nuovo testo utente nasce già nelle 8 lingue: italiano, inglese, francese, tedesco, spagnolo, portoghese, cinese mandarino e giapponese.
8. **Sicurezza per ambiente.** Solo TEST2.0; credenziali segrete mai inserite nel client o nel repository.
9. **Consegna controllata.** Un blocco non si considera concluso finché implementazione, test, documentazione e verifica d'integrazione non sono completati.
10. **Nessuna promozione automatica.** Nessun merge, deploy o modifica a produzione senza autorizzazione esplicita.

## 3. Strati applicativi

- **App Shell:** avvio, tema, localizzazione, navigazione di alto livello e gestione degli errori non specifici.
- **Blocchi funzionali:** implementano i casi d'uso di una singola area.
- **Servizi condivisi:** autenticazione di sessione, configurazione, logging, rete, gestione file e componenti UI comuni, solo quando realmente condivisi.
- **Data layer:** repository e accesso ai dati; le schermate non interrogano direttamente il database.
- **Backend:** Supabase TEST2.0 con Auth, PostgreSQL, RLS, funzioni e storage secondo necessità.

Le regole di dominio restano nel blocco proprietario. Il livello condiviso non diventa un contenitore generico di logica applicativa.

## 4. Mappa preliminare dei blocchi

La numerazione è provvisoria. I confini e l'ordine verranno confermati nella revisione.

| Codice | Blocco | Responsabilità principale |
|---|---|---|
| CORE | Nucleo applicativo | Avvio, configurazione, navigazione, tema, lingue e componenti comuni |
| BL-01 | Autenticazione | Registrazione, login, conferma email, recupero e cambio password, sessione |
| BL-02 | Profilo utente | Profilo, preferenze e impostazioni personali |
| BL-03 | Catalogo e collezione | Anagrafica oggetti, schede, immagini, categorie e gestione collezione |
| BL-04 | Acquisti | Registrazione e gestione acquisti, preordini e flussi collegati |
| BL-05 | Vendite e inserzioni | Preparazione e gestione inserzioni, piattaforme e vendite |
| BL-06 | PR-12 - Identificazione e metadati | Ricerca, identificazione, confronto candidati e fonti |
| BL-07 | PR-18 - Valutazione oggetto | Valutazione di un singolo oggetto già identificato/confermato |
| BL-08 | PR-21 - Valutazione collezione | Valutazione complessiva, storico e andamento della collezione |
| BL-09 | Wishlist / Wanted List | Desiderata, immagini e ricerca di oggetti da acquisire |
| BL-10 | Report e analisi | Report operativi, economici e di andamento |
| BL-11 | Crediti e abbonamenti | Piano Free/Premium, crediti AI acquistabili, consumi e autorizzazioni |
| BL-12 | Amministrazione e diagnostica | Funzioni di controllo, audit e diagnostica non accessibili agli utenti ordinari |

### Ambito commerciale iniziale

Le categorie di lancio previste sono: LEGO, Transformers, Funko Pop, fumetti, action figures e model kit. La struttura delle categorie deve essere estendibile senza riscrivere i blocchi funzionali.

Il modello commerciale previsto è Free + abbonamento Premium + crediti AI acquistabili separatamente. Regole, prezzi, limiti e consumi devono essere gestiti in modo centralizzato e verificabile, non sparsi nelle schermate.

## 5. Scheda obbligatoria di ogni blocco

Prima di sviluppare un blocco viene compilata e approvata una scheda dedicata con queste sezioni:

1. **Scopo e confini:** cosa fa e cosa non fa.
2. **Procedure:** elenco numerato delle operazioni, regole, validazioni, esiti ed errori.
3. **Maschere:** elenco delle schermate, campi, azioni, stati e navigazione.
4. **Modelli dati:** entità, campi, vincoli e relazioni di proprietà del blocco.
5. **Servizi e repository:** responsabilità e contratti verso il backend.
6. **Collegamenti in entrata/uscita:** quali blocchi lo chiamano e quali servizi/blocchi usa.
7. **Autorizzazioni e sicurezza:** sessione richiesta, ruoli, RLS e dati sensibili.
8. **Crediti e piano:** eventuale costo in crediti, limiti Free/Premium e gestione degli errori di addebito.
9. **Localizzazione e accessibilità:** tutte le 8 lingue, formati e accessibilità.
10. **Test e criteri di accettazione:** casi positivi, negativi, limiti e regressioni.
11. **Documentazione e versione:** changelog e dipendenze.

Nessun blocco parte con una scheda incompleta.

## 6. Regole preliminari sui collegamenti

- BL-01 fornisce lo stato di autenticazione; non contiene la logica del profilo o del catalogo.
- BL-02 gestisce il profilo; non crea autonomamente credenziali o sessioni.
- BL-03 è il proprietario della scheda dell'oggetto e del suo identificativo interno.
- BL-06 identifica l'oggetto e restituisce candidati, metadati e fonti; non assegna il valore economico definitivo.
- BL-07 riceve un oggetto identificato/confermato e restituisce la valutazione del singolo oggetto.
- BL-08 usa i dati degli oggetti e le valutazioni disponibili per la visione complessiva e lo storico.
- BL-04 e BL-05 gestiscono rispettivamente acquisti e vendite; non duplicano l'anagrafica dell'oggetto.
- BL-11 espone contratti per verificare disponibilità e registrare consumi; i blocchi funzionali non implementano contatori di crediti propri.
- Nessun blocco accede alle tabelle di un altro blocco aggirandone il repository o le policy.

Questi sono confini proposti: i contratti puntuali saranno definiti nelle singole schede.

## 7. Struttura cartelle proposta

```
mobile_android/
  lib/
    main.dart
    app/
      app.dart
      bootstrap/
      navigation/
      theme/
      localization/
    core/
      config/
      errors/
      logging/
      network/
      shared_widgets/
      contracts/
    features/
      authentication/
        data/
        domain/
        presentation/
        tests/
      user_profile/
        data/
        domain/
        presentation/
        tests/
      catalog/
        data/
        domain/
        presentation/
        tests/
      purchases/
        data/
        domain/
        presentation/
        tests/
      sales/
        data/
        domain/
        presentation/
        tests/
      metadata/
        data/
        domain/
        presentation/
        tests/
      object_valuation/
        data/
        domain/
        presentation/
        tests/
      collection_valuation/
        data/
        domain/
        presentation/
        tests/
      wanted_list/
        data/
        domain/
        presentation/
        tests/
      reports/
        data/
        domain/
        presentation/
        tests/
      billing_credits/
        data/
        domain/
        presentation/
        tests/
      administration/
        data/
        domain/
        presentation/
        tests/
  test/
  integration_test/
  docs/
    architecture/
    blocks/
```

Ogni feature può contenere ulteriori sottocartelle, ma solo se giustificate dalla sua complessità. Non si creano cartelle vuote o livelli inutili per rispettare uno schema.

## 8. Regole di sviluppo e rilascio

Per ogni blocco:

1. analisi e scheda funzionale;
2. approvazione della scheda;
3. progettazione di dati e contratti;
4. implementazione isolata;
5. test automatici del blocco;
6. test d'integrazione con i blocchi già approvati;
7. verifica Android;
8. aggiornamento documentazione e registro stato.

Gli stati ammessi sono: **DA DEFINIRE**, **SPECIFICA APPROVATA**, **IN SVILUPPO**, **TEST**, **COMPLETATO**. Un test fallito riporta il blocco in lavorazione; non viene dichiarato completato sulla base della sola compilazione.

## 9. Decisioni ancora da approvare

- Mappa e confini definitivi dei blocchi.
- Nome e responsabilità del nucleo CORE.
- Dipendenze esatte e contratti tra blocchi.
- Identificativo Android definitivo (applicationId).
- Strategia definitiva per navigazione e deep link.
- Schema dati definitivo per ogni feature.
- Regole precise di piani, crediti, prezzi e consumo.

## 10. Primo blocco da specificare

Dopo l'approvazione dell'architettura, il primo blocco funzionale sarà **BL-01 - Autenticazione**. La sua specifica comprenderà registrazione, login, conferma email, recupero password, cambio password, gestione sessione, maschere, redirect Android, collegamento al profilo e test di sicurezza su TEST2.0.

---

**Nota di stato:** questa è una proposta architetturale iniziale. Non dichiara implementati o collaudati i blocchi elencati.
