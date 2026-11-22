# PR AGGIORNA CATALOGHI - Verifica TEST2
Data verifica: 2026-11-22

## Ambiente
- Supabase: COLLECTION by VALORA TEST2.0
- Project ref: hqiisivoistpejvilbeu
- Nessuna modifica alla produzione.
- Nessuna immagine acquisita, modificata o sostituita.

## Fonti candidate
Verifica SQL effettiva su `public.pr_cataloghi_fonti`: 22 fonti candidate complessive, 0 attive.
- LEGO: 1
- TRANSFORMERS: 1
- SAINT SEIYA: 1
- BARBIE: 1
- HOT WHEELS: 1
- FUNKO POP: 1
- ACTION FIGURES: 4
- MODEL KIT: 4
- MODELLISMO STATICO: 3
- STATUE E FIGURE DA COLLEZIONE: 3
- G.I. JOE: 1
- SOUL OF CHOGOKIN: 1

Tutte le fonti restano disattivate e non verificate. Non abilitare fino a verifica di endpoint/API, condizioni d'uso, robots/accesso, stabilità degli identificativi e qualità dei campi.

## Cataloghi e mapping
- Mapping pronto: LEGO, TRANSFORMERS, SAINT SEIYA, BARBIE, FUNKO POP, ACTION FIGURES, G.I. JOE.
- SOUL OF CHOGOKIN è un sottocatalogo di ACTION FIGURES, filtrato tramite linea_serie. Non creare una tabella master separata.
- Master condiviso da creare: HOT WHEELS, MODEL KIT, MODELLISMO STATICO, STATUE E FIGURE DA COLLEZIONE.
- PLAYMOBIL resta escluso finché non viene approvato e creato il relativo master.

## Sicurezza e controllo
Le funzioni di consultazione e decisione delle proposte verificano che l'utente sia attivo e abbia ruolo PROPRIETARIO o AMMINISTRATORE in master_utenti. La registrazione delle proposte è riservata a service_role. Le funzioni SECURITY DEFINER impostano search_path esplicito.
Le tabelle PR con RLS attivo e senza policy sono intenzionalmente chiuse agli accessi diretti anon/authenticated; l'accesso avviene tramite funzioni controllate. Il Security Advisor segnala questi casi come informativi.
Il controllo non distruttivo non inserisce né modifica schede master. L'approvazione di una proposta non scrive ancora sul master: manca il validatore/applicatore specifico, con controllo di concorrenza e audit transazionale.

## Stato reale
Implementato: configurazione, controllo inventariale, cron wrapper Europe/Rome, staging proposte, rimozione ricorsiva delle chiavi immagine, decisione amministrativa, audit per campo, log fonti e paginazione proposte.
Non implementato: adapter reali per interrogare le fonti, parser per catalogo, risoluzione duplicati multi-fonte, validatore/applicatore transazionale, UI di revisione e attivazione fonti dopo verifica.
Il cron esegue il controllo inventariale solo il giorno 1 alle 03:00 Europe/Rome. Non equivale ancora a un aggiornamento automatico dei cataloghi.
