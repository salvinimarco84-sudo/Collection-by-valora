-- Rinomina PR-21 in PR-11 per la valutazione complessiva della collezione.
-- Mantiene invariati codice API, endpoint, dati storici e comportamento del motore.
update collection.runtime_catalogo_api
set codice_procedura = 'PR-11',
    descrizione = 'Avvia PR-11: valutazione complessiva della collezione in lotti da 10, con storico e confronto con la rilevazione precedente.',
    note = replace(coalesce(note, ''), 'PR-21', 'PR-11'),
    aggiornato_il = now()
where codice_api = 'COLLECTION-MARKET-VALUE';
