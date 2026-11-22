import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const REBRICKABLE_API_KEY = Deno.env.get("REBRICKABLE_API_KEY") ?? "";
const SOURCE_ID = "44265414-77b2-4f9e-adae-ec3fcf8348ef";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return response({ error: "Metodo non consentito" }, 405);
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) return response({ error: "Autenticazione richiesta" }, 401);
    const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SERVICE_ROLE_KEY, Authorization: authHeader },
    });
    if (!userRes.ok) return response({ error: "Sessione non valida" }, 401);
    const user = await userRes.json();
    const adminRes = await fetch(
      `${SUPABASE_URL}/rest/v1/master_utenti?id_utente=eq.${encodeURIComponent(user.id)}&select=ruolo_sistema,stato_utente`,
      { headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` } },
    );
    if (!adminRes.ok) return response({ error: "Verifica ruolo non disponibile" }, 503);
    const adminRows = await adminRes.json();
    if (!adminRows.some((r: any) => ["PROPRIETARIO", "AMMINISTRATORE"].includes(r.ruolo_sistema) && r.stato_utente === "ATTIVO")) {
      return response({ error: "Operazione riservata agli amministratori VALORA" }, 403);
    }
    if (!REBRICKABLE_API_KEY) return response({
      status: "CONFIGURAZIONE_RICHIESTA",
      message: "Manca il secret REBRICKABLE_API_KEY. Nessuna chiamata esterna e nessuna proposta sono state create.",
      required_secret: "REBRICKABLE_API_KEY",
    }, 409);

    const body = await req.json().catch(() => ({}));
    const page = Math.max(1, Math.min(10000, Number(body.page ?? 1)));
    const pageSize = Math.max(1, Math.min(100, Number(body.page_size ?? 50)));
    const dryRun = body.dry_run !== false;
    const apiRes = await fetch(
      `https://rebrickable.com/api/v3/lego/sets/?page=${page}&page_size=${pageSize}&ordering=-year`,
      { headers: { Authorization: `key ${REBRICKABLE_API_KEY}`, Accept: "application/json" } },
    );
    if (apiRes.status === 429) return response({ status: "THROTTLED", message: "Rebrickable ha applicato un limite. Attendere prima di riprovare." }, 429);
    if (!apiRes.ok) return response({ status: "FONTE_NON_DISPONIBILE", upstream_status: apiRes.status }, 502);
    const data = await apiRes.json();
    const rows = Array.isArray(data.results) ? data.results : [];
    const proposals = rows.map((item: any) => ({
      external_id: String(item.set_num ?? ""),
      payload: {
        descrizione_oggetto: String(item.name ?? "").trim(),
        codice_oggetto: String(item.set_num ?? "").trim(),
        tipo_oggetto: "SET",
        tema: item.theme_id == null ? null : String(item.theme_id),
        numero_pezzi: Number.isInteger(item.num_parts) ? item.num_parts : null,
        anno_uscita: Number.isInteger(item.year) ? item.year : null,
        fonte_catalogo: "REBRICKABLE",
        url_fonte: typeof item.set_url === "string" ? item.set_url : null,
        ultimo_aggiornamento_fonte: item.last_modified_dt ?? null,
      },
    })).filter((p: any) => p.external_id && p.payload.descrizione_oggetto);

    if (dryRun) return response({
      status: "ANTEPRIMA_COMPLETATA", catalogo: "LEGO", fonte: "Rebrickable API v3",
      pagina: page, dimensione_pagina: pageSize, totale_fonte: data.count ?? null,
      proposte_analizzate: proposals.length, esempi: proposals.slice(0, 5),
      next_page: data.next ?? null, note: "Dry-run: nessuna proposta salvata. Le chiavi immagine sono escluse.",
    });

    let saved = 0, duplicates = 0;
    const errors: string[] = [];
    for (const p of proposals) {
      const rpc = await fetch(`${SUPABASE_URL}/rest/v1/rpc/pr_cataloghi_registra_proposta`, {
        method: "POST",
        headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          p_codice_catalogo: "LEGO", p_id_fonte: SOURCE_ID,
          p_identificativo_esterno: p.external_id, p_chiave_identita: `LEGO:${p.external_id}`,
          p_payload: p.payload, p_confidenza: 0.97,
        }),
      });
      if (rpc.ok) saved++;
      else {
        const err = await rpc.text();
        if (err.includes("duplicate") || err.includes("unique")) duplicates++;
        else errors.push(`${p.external_id}: ${err.slice(0, 180)}`);
      }
    }
    return response({
      status: errors.length ? "COMPLETATA_CON_ERRORI" : "STAGING_COMPLETATO",
      catalogo: "LEGO", pagina: page, record_letti: rows.length, proposte_inviate: saved,
      duplicati_o_gia_presenti: duplicates, errori: errors.slice(0, 10),
      nota: "Scrittura esclusivamente nello staging. Nessuna scheda master modificata; immagini escluse.",
    });
  } catch (_error) {
    return response({ error: "Errore interno nell'adapter LEGO" }, 500);
  }
});
