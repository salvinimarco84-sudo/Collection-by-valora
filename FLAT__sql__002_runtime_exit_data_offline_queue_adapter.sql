-- Apply only to Supabase TEST project eeiekkflpnkummxtvljy.
-- Production project bufwceckrmbocctarthj is explicitly out of scope.
create or replace function collection.runtime_applica_dati_uscita_da_coda(
  p_user_id uuid,
  p_session_id uuid,
  p_request_id uuid,
  p_payload jsonb
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, collection
as $function$
declare
  v_lock collection.runtime_lock_modifiche%rowtype;
  v_result jsonb;
begin
  if p_user_id is null
     or not exists (
       select 1 from collection.app_authorized_users
       where user_id = p_user_id and attivo = true
     ) then
    raise exception 'Account non autorizzato alla beta TEST.';
  end if;

  if exists (
    select 1 from collection.runtime_dati_uscita_idempotenza
    where request_id = p_request_id
  ) then
    return collection.runtime_applica_dati_uscita(
      p_user_id, p_session_id, p_request_id, p_payload
    ) || jsonb_build_object('sincronizzazione_da_coda', true);
  end if;

  select * into v_lock
  from collection.runtime_lock_modifiche
  where singleton = true
  for update;

  if not found
     or v_lock.owner_user_id is distinct from p_user_id
     or v_lock.owner_session_id is distinct from p_session_id
     or v_lock.stato <> 'IN_RECUPERO'
     or not v_lock.coda_pendente then
    raise exception 'Sincronizzazione dati di uscita negata: coda o blocco di recupero non validi.';
  end if;

  update collection.runtime_lock_modifiche
  set stato = 'ATTIVO', coda_pendente = false,
      ultimo_heartbeat = now(), aggiornato_il = now()
  where singleton = true;

  v_result := collection.runtime_applica_dati_uscita(
    p_user_id, p_session_id, p_request_id, p_payload
  );

  update collection.runtime_lock_modifiche
  set stato = 'IN_RECUPERO', coda_pendente = true,
      ultimo_heartbeat = now(), aggiornato_il = now()
  where singleton = true;

  return v_result || jsonb_build_object('sincronizzazione_da_coda', true);
end;
$function$;

revoke all on function collection.runtime_applica_dati_uscita_da_coda(uuid,uuid,uuid,jsonb) from public, anon, authenticated;
grant execute on function collection.runtime_applica_dati_uscita_da_coda(uuid,uuid,uuid,jsonb) to service_role;
