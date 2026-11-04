# Regole di consolidamento e protezione del codice

## Baseline protetta
La baseline operativa è **Run 1085**, commit `d86142c9ecb6fa2ea93fb7d8815cb23fd1f76008`.
Run 1076 è soltanto una sorgente storica per recuperi grafici esplicitamente richiesti.
Nessuna modifica deve usare una baseline più vecchia al posto della Run 1085.

## Regole obbligatorie per ogni intervento
1. Partire dalla baseline operativa aggiornata e lavorare su un branch dedicato.
2. Prima di modificare, leggere il file completo e individuare funzioni, classi, callback, query, dipendenze e asset coinvolti.
3. Modificare esclusivamente il perimetro richiesto. Vietati riscritture integrali, sostituzioni "a blocco" e ripristini di file interi per correggere un singolo comportamento.
4. Conservare il codice esistente non coinvolto, anche se non è direttamente collegato alla modifica.
5. Ogni funzione o comportamento corretto deve avere un test di regressione. Le schermate e i flussi critici devono avere contratti verificabili.
6. Prima della build, controllare il diff completo: file modificati, aggiunti, rinominati, eliminati e conteggio righe aggiunte/rimosse. Ogni cancellazione va spiegata.
7. Nessuna rimozione di file della baseline in `lib/`, `assets/`, `sql/` o `supabase/migrations/` senza autorizzazione esplicita e motivazione nell'allowlist.
8. Se una rimozione è davvero necessaria, aggiungere `percorso|motivazione` a `scripts/regression_removals_allowlist.txt` nello stesso commit. L'allowlist è sottoposta a revisione e non è un'autorizzazione automatica dell'utente.
9. Eseguire nell'ordine: controllo protezione baseline, test, analisi Flutter, controlli contrattuali, build Android e Windows.
10. Se un controllo fallisce, fermare la pipeline. Non distribuire e non dichiarare completato.
11. Usare esclusivamente Supabase TEST. Non eseguire migrazioni, scritture o deploy su produzione senza una richiesta esplicita separata.

## Protezioni automatiche
- `scripts/protect_baseline.py` confronta i file protetti di HEAD con la Run 1085.
- La CI esegue il controllo a ogni pull request e blocca cancellazioni non autorizzate.
- I test di contratto proteggono i flussi PR, i report approvati, le azioni sulle schede, gli sfondi e i temi.
- La build non sostituisce i test funzionali: l'esito verde dimostra solo i controlli effettivamente eseguiti.

## Aree da non alterare senza richiesta specifica
- Report Acquisti: approvato, da mantenere invariato.
- Scheda patrimoniale e relativi banner, sezioni e valori.
- Sfondi menu, sfondi patrimoniali, temi e pulsanti trasparenti.
- Procedure, report, immagini, categorie e dati TEST.
