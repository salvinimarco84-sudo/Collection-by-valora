import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" },
  });
}

function userIdFromToken(req: Request): string | null {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch { return null; }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "Usare POST." }, 405);
  if (!userIdFromToken(req)) return json({ ok: false, error: "Sessione autenticata richiesta." }, 401);

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ ok: false, error: "JSON non valido." }, 400); }
  if (body.conferma_utente !== true) return json({ ok: false, error: "Conferma esplicita richiesta; nessun dato salvato." }, 400);

  const id = Number(body.codice_oggetto);
  const candidate = body.metadati && typeof body.metadati === "object" ? body.metadati as Record<string, unknown> : {};
  const clean = (v: unknown, max = 1000) => String(v ?? "").trim().slice(0, max);
  const officialName = clean(candidate.nome_ufficiale ?? candidate.title, 300);
  const sourceUrl = clean(candidate.url_fonte ?? candidate.url, 2000);
  if (!Number.isSafeInteger(id) || id <= 0) return json({ ok: false, error: "CODICE_OGGETTO non valido." }, 400);
  if (officialName.length < 2) return json({ ok: false, error: "Nome ufficiale mancante: descrizione originale conservata." }, 400);
  let parsedUrl: URL;
  try { parsedUrl = new URL(sourceUrl); } catch { return json({ ok: false, error: "Fonte non valida." }, 400); }
  if (parsedUrl.protocol !== "https:" && parsedUrl.protocol !== "http:") return json({ ok: false, error: "La fonte deve essere HTTP(S)." }, 400);

  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SERVICE_ROLE_KEY") ?? "";
  if (!base || !key) return json({ ok: false, error: "Configurazione backend incompleta; nessun dato salvato." }, 503);
  const headers = { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json", "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=representation,resolution=merge-duplicates" };
  const record = {
    codice_oggetto: id,
    codice_identificativo: clean(candidate.codice_identificativo ?? candidate.codice_prodotto ?? candidate.isbn, 120) || null,
    nome_ufficiale: officialName,
    produttore: clean(candidate.produttore ?? candidate.brand, 200) || null,
    anno_uscita: Number.isInteger(Number(candidate.anno_uscita)) && Number(candidate.anno_uscita) >= 1000 && Number(candidate.anno_uscita) <= 9999 ? Number(candidate.anno_uscita) : null,
    versione_variante: clean(candidate.versione_variante ?? candidate.variante, 300) || null,
    descrizione_ufficiale: clean(candidate.descrizione_ufficiale ?? candidate.snippet, 2000) || null,
    tema: clean(candidate.tema, 120) || null,
    sezione: clean(candidate.sezione, 120) || null,
    sottotema: clean(candidate.sottotema, 120) || null,
    isbn: clean(candidate.isbn, 32) || null,
    editore: clean(candidate.editore, 200) || null,
    url_fonte: sourceUrl,
    url_immagine: clean(candidate.url_immagine ?? candidate.image_url, 2000) || null,
    stato_verifica: "VERIFICATO",
    data_conferma: new Date().toISOString(),
    aggiornato_il: new Date().toISOString(),
  };

  try {
    const metadataUrl = new URL(base + "/rest/v1/master_metadati");
    metadataUrl.searchParams.set("on_conflict", "codice_oggetto");
    const metaResponse = await fetch(metadataUrl, { method: "POST", headers, body: JSON.stringify(record), signal: AbortSignal.timeout(12000) });
    if (!metaResponse.ok) throw new Error("Salvataggio Master Metadati HTTP " + metaResponse.status + ": " + (await metaResponse.text()).slice(0, 300));

    // La descrizione viene sostituita soltanto dopo la conferma esplicita e il salvataggio dei metadati.
    const objectUrl = new URL(base + "/rest/v1/master_oggetti");
    objectUrl.searchParams.set("codice_oggetto", "eq." + id);
    const objectResponse = await fetch(objectUrl, { method: "PATCH", headers: { ...headers, Prefer: "return=representation" }, body: JSON.stringify({ descrizione_oggetto: officialName }), signal: AbortSignal.timeout(12000) });
    if (!objectResponse.ok) throw new Error("Metadati salvati ma aggiornamento descrizione non riuscito (HTTP " + objectResponse.status + "). Ripetere la conferma per riallineare il record.");
    const objects = await objectResponse.json();
    if (!Array.isArray(objects) || objects.length !== 1) throw new Error("Metadati salvati ma record oggetto non trovato in modo univoco.");
    return json({ ok: true, codice_oggetto: id, nome_ufficiale: officialName, descrizione_sostituita: true, master_metadati_salvato: true });
  } catch (error) {
    return json({ ok: false, error: error instanceof Error ? error.message : String(error), descrizione_originale_garantita_se_errore_precedente_al_patch: true }, 502);
  }
});
