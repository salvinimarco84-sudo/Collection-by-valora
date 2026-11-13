-- PR-15: allow the outstanding balance to be paid after the item is received.
-- Receipt is a logistics state; payment completion must not overwrite it.
create or replace function collection.pr15_preorder_valida_pagamento()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
declare
  v_prezzo numeric(14,2);
  v_totale numeric(14,2);
  v_stato text;
  v_user uuid;
begin
  select prezzo_concordato, stato, user_id
    into v_prezzo, v_stato, v_user
    from collection.master_preordini
   where codice_preordine = new.codice_preordine
   for update;

  if not found then
    raise exception 'PR-15: preorder non trovato.';
  end if;
  if v_user <> new.user_id then
    raise exception 'PR-15: proprietario pagamento non coerente.';
  end if;
  if v_stato in ('SPEDITO','CONVERTITO','ANNULLATO','RIMBORSATO') then
    raise exception 'PR-15: non è possibile registrare pagamenti in questo stato.';
  end if;

  select coalesce(sum(importo),0)
    into v_totale
    from collection.pagamenti_preordini
   where codice_preordine = new.codice_preordine
     and (tg_op <> 'UPDATE' or codice_pagamento <> new.codice_pagamento);

  if v_totale + new.importo > v_prezzo then
    raise exception 'PR-15: il pagamento supera il saldo residuo.';
  end if;
  return new;
end;
$$;
