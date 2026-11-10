-- Allinea il catalogo runtime TEST alla numerazione approvata:
-- PR-18 = VALORA singolo oggetto; PR-21 = valutazione complessiva collezione.
update collection.runtime_catalogo_api
set codice_procedura = 'PR-21',
    descrizione = 'Avvia PR-21: valutazione complessiva della collezione in lotti da 10, con storico e confronto con la rilevazione precedente.',
    stato_implementazione = 'API_IMPLEMENTATA_DA_COLLAUDARE',
    note = 'Motore TEST operativo in lotti da 10. Usa PR-12 per le evidenze; salva lo storico e aggiorna il valore corrente solo in presenza di vendite concluse utilizzabili. Le stime non supportate non sovrascrivono valori esistenti.',
    aggiornato_il = now()
where codice_api = 'COLLECTION-MARKET-VALUE';

insert into collection.runtime_catalogo_api (
  codice_api, categoria, descrizione, action_runtime, codice_procedura,
  sola_lettura, richiede_autenticazione, richiede_allowlist, richiede_blocco,
  supporta_batch, idempotente, stato_implementazione, contratto_input, note, aggiornato_il
) values (
  'VALORA-OBJECT-VALUATION',
  'CONSULTAZIONE',
  'PR-18 VALORA: valutazione specialistica di un singolo oggetto dopo conferma esplicita del candidato identificato da PR-12.',
  'pr-18-valuation-test',
  'PR-18',
  true, true, true, false, false, false,
  'API_IMPLEMENTATA_DA_COLLAUDARE',
  jsonb_build_object(
    'input', 'metadati del candidato PR-12 confermato',
    'mercato_riferimento', 'mercato e area geografica configurati nel profilo utente',
    'output', jsonb_build_array('valore_mercato','fascia_minima','fascia_massima','affidabilita','comparabili','fonti'),
    'vincoli', jsonb_build_array('nessuna valutazione prima della conferma utente','nessuna scrittura inventario/acquisti/vendite','distinguere vendite concluse e prezzi richiesti','non inventare valori')
  ),
  'Motore TEST singolo oggetto. Dipende da PR-12 per le evidenze di mercato, distingue vendite concluse da prezzi richiesti e non modifica il database inventario.',
  now()
)
on conflict (codice_api) do update set
  categoria = excluded.categoria,
  descrizione = excluded.descrizione,
  action_runtime = excluded.action_runtime,
  codice_procedura = excluded.codice_procedura,
  sola_lettura = excluded.sola_lettura,
  richiede_autenticazione = excluded.richiede_autenticazione,
  richiede_allowlist = excluded.richiede_allowlist,
  richiede_blocco = excluded.richiede_blocco,
  supporta_batch = excluded.supporta_batch,
  idempotente = excluded.idempotente,
  stato_implementazione = excluded.stato_implementazione,
  contratto_input = excluded.contratto_input,
  note = excluded.note,
  aggiornato_il = now();
