-- Backfill prudente della tassonomia COLLEZIONE dai metadati espliciti.
-- Non usa la descrizione dell'oggetto per indovinare la categoria.
begin;

insert into collection.temi_collezione
  (codice_categoria, codice_tema, descrizione, ordine, attivo)
select distinct
  c.codice_categoria,
  upper(regexp_replace(btrim(m.valori->>'tema'), '[^[:alnum:]]+', '_', 'g')),
  btrim(m.valori->>'tema'),
  100,
  true
from collection.metadati_specifici_oggetto m
join collection.master_categorie_collezione c
  on upper(btrim(m.valori->>'categoria')) = upper(btrim(c.descrizione))
  or (upper(btrim(m.valori->>'categoria')) = 'SAINT SEIYA' and c.codice_categoria = 'SAINT_SEIYA')
where nullif(btrim(m.valori->>'tema'), '') is not null
  and upper(btrim(m.valori->>'categoria')) in ('LEGO','SAINT SEIYA','TRANSFORMERS','FUMETTI','GUNDAM','MOTO DIE-CAST')
on conflict (codice_categoria, codice_tema) do nothing;

insert into collection.oggetto_collezione_categoria
  (codice_oggetto, codice_categoria, id_tema, fonte_assegnazione, stato_verifica)
select
  m.codice_oggetto,
  c.codice_categoria,
  t.id_tema,
  'METADATI',
  'DA_VERIFICARE'
from collection.metadati_specifici_oggetto m
join collection.master_oggetti o on o.codice_oggetto = m.codice_oggetto
join collection.master_categorie_collezione c
  on upper(btrim(m.valori->>'categoria')) = upper(btrim(c.descrizione))
  or (upper(btrim(m.valori->>'categoria')) = 'SAINT SEIYA' and c.codice_categoria = 'SAINT_SEIYA')
left join collection.temi_collezione t
  on t.codice_categoria = c.codice_categoria
 and upper(btrim(t.descrizione)) = upper(btrim(m.valori->>'tema'))
where o.destinazione = 'COLLEZIONE'
  and not coalesce(o.archiviato_test, false)
  and upper(btrim(m.valori->>'categoria')) in ('LEGO','SAINT SEIYA','TRANSFORMERS','FUMETTI','GUNDAM','MOTO DIE-CAST')
on conflict (codice_oggetto) do nothing;

commit;
