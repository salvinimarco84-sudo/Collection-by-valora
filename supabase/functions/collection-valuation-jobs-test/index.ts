import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};
const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
const excluded = new Set(["VENDUTO", "PERSO", "DISTRUTTO", "USCITO", "ACCORPATO"]);
const batchSize = 5;

function config() {
  const url = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  if (!url || !anon) throw new Error("Configurazione Supabase incompleta.");
  return { url, anon };
}
async function api(path: string, token: string, init: RequestInit = {}) {
  const c = config();
  const res = await fetch(c.url + "/rest/v1/" + path, {
    ...init,
    headers: {
      apikey: c.anon, Authorization: token, "Content-Type": "application/json",
      Prefer: "return=representation", ...(init.headers ?? {}),
    },
  });
  const raw = await res.text();
  if (!res.ok) throw new Error("Database HTTP " + res.status + ": " + raw.slice(0, 350));
  return raw ? JSON.parse(raw) : null;
}
async function user(req: Request) {
  const token = req.headers.get("Authorization") ?? "";
  if (!/^Bearer\s+\S+/i.test(token)) throw new Error("Accesso autenticato richiesto.");
  const c = config();
  const res = await fetch(c.url + "/auth/v1/user", { headers: { apikey: c.anon, Authorization: token } });
  if (!res.ok) throw new Error("Sessione scaduta o non valida.");
  const data = await res.json();
  if (typeof data.id !== "string") throw new Error("Utente non autenticato.");
  return { id: data.id, token };
}
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return reply({ ok: false, error: "Usare POST." }, 405);
  try {
    const auth = await user(req);
    const body = await req.json();
    const action = String(body.action ?? "").toLowerCase();
    if (action === "start") {
      const market = String(body.market ?? "ITALIA").toUpperCase();
      if (!["ITALIA", "EUROPA", "MONDO"].includes(market)) return reply({ ok: false, error: "Mercato non valido." }, 400);
      const raw = await api("master_oggetti?select=codice_oggetto,descrizione_oggetto,categoria,quantita,stato,archiviato_test,destinazione&destinazione=eq.COLLEZIONE&order=codice_oggetto.asc&limit=10000", auth.token, { headers: { "Accept-Profile": "collection" } });
      const active = (Array.isArray(raw) ? raw : []).filter((r: any) =>
        r.archiviato_test !== true && !excluded.has(String(r.stato ?? "").toUpperCase()) && String(r.descrizione_oggetto ?? "").trim().length > 1
      );
      if (!active.length) return reply({ ok: false, error: "Nessun oggetto attivo trovato in COLLEZIONE." }, 422);
      const created = await api("valuation_jobs", auth.token, { method: "POST", headers: { "Content-Profile": "collection" }, body: JSON.stringify({ requested_by: auth.id, market, status: "queued", total_items: active.length }) });
      const job = created[0];
      for (let i = 0; i < active.length; i += 300) {
        const items = active.slice(i, i + 300).map((r: any) => ({ job_id: job.id, object_code: String(r.codice_oggetto), description: String(r.descrizione_oggetto), category: String(r.categoria ?? ""), quantity: Number(r.quantita ?? 1) || 1, state: "queued" }));
        await api("valuation_job_items", auth.token, { method: "POST", headers: { "Content-Profile": "collection" }, body: JSON.stringify(items) });
      }
      return reply({ ok: true, job_id: job.id, total_items: active.length, status: "queued" });
    }
    const id = String(body.job_id ?? "");
    if (!id) return reply({ ok: false, error: "job_id richiesto." }, 400);
    const jobs = await api("valuation_jobs?select=*&id=eq." + encodeURIComponent(id) + "&requested_by=eq." + encodeURIComponent(auth.id), auth.token, { headers: { "Accept-Profile": "collection" } });
    if (!jobs?.length) return reply({ ok: false, error: "Job non trovato." }, 404);
    const job = jobs[0];
    if (action === "status") {
      const items = await api("valuation_job_items?select=object_code,description,category,quantity,state,source_urls,error,processed_at&job_id=eq." + encodeURIComponent(id) + "&order=id.asc&limit=10000", auth.token, { headers: { "Accept-Profile": "collection" } });
      const count = (state: string) => items.filter((x: any) => x.state === state).length;
      const processed = count("priced") + count("unpriced") + count("failed");
      return reply({ ok: true, job: { ...job, processed_items: processed, priced_items: count("priced"), unpriced_items: count("unpriced"), failed_items: count("failed"), progress_percent: job.total_items ? Math.round(processed * 100 / job.total_items) : 0 }, report: { complete: processed === job.total_items && job.total_items > 0 && count("failed") === 0, items } });
    }
    if (action === "process") {
      const items = await api("valuation_job_items?select=*&job_id=eq." + encodeURIComponent(id) + "&state=eq.queued&order=id.asc&limit=" + batchSize, auth.token, { headers: { "Accept-Profile": "collection" } });
      if (!items.length) return reply({ ok: true, job_id: id, processed_batch: 0, remaining: 0 });
      await api("valuation_jobs?id=eq." + encodeURIComponent(id), auth.token, { method: "PATCH", headers: { "Content-Profile": "collection" }, body: JSON.stringify({ status: "running", started_at: job.started_at ?? new Date().toISOString(), updated_at: new Date().toISOString() }) });
      const c = config();
      const done = [];
      for (const item of items) {
        try {
          const res = await fetch(c.url + "/functions/v1/pr-12-web-search-test", {
            method: "POST", headers: { apikey: c.anon, Authorization: auth.token, "Content-Type": "application/json" },
            signal: AbortSignal.timeout(40000),
            body: JSON.stringify({ descrizione: item.description, categoria: item.category ?? "", mercato: job.market }),
          });
          const payload = await res.json().catch(() => ({}));
          if (!res.ok || payload?.ok === false) throw new Error(String(payload?.error ?? "PR12 HTTP " + res.status));
          const candidates = Array.isArray(payload?.risultati) ? payload.risultati : [];
          const urls = candidates.map((x: any) => x.url).filter((x: unknown) => typeof x === "string" && /^https?:\/\//.test(x)).slice(0, 20);
          // PR12 non espone ancora quotazioni normalizzate. Non si inventano prezzi dai testi.
          const state = "unpriced";
          await api("valuation_job_items?id=eq." + item.id, auth.token, { method: "PATCH", headers: { "Content-Profile": "collection" }, body: JSON.stringify({ state, candidates, source_urls: urls, error: candidates.length ? "PR12 ha trovato fonti, ma non una quotazione strutturata verificabile." : "Nessun candidato verificabile restituito da PR12.", attempts: Number(item.attempts ?? 0) + 1, processed_at: new Date().toISOString(), updated_at: new Date().toISOString() }) });
          done.push({ object_code: item.object_code, state, candidates: candidates.length });
        } catch (e) {
          await api("valuation_job_items?id=eq." + item.id, auth.token, { method: "PATCH", headers: { "Content-Profile": "collection" }, body: JSON.stringify({ state: "failed", error: String(e).slice(0, 400), attempts: Number(item.attempts ?? 0) + 1, updated_at: new Date().toISOString() }) });
          done.push({ object_code: item.object_code, state: "failed" });
        }
      }
      const pending = await api("valuation_job_items?select=id&job_id=eq." + encodeURIComponent(id) + "&state=in.(queued,running)&limit=10000", auth.token, { headers: { "Accept-Profile": "collection" } });
      if (!pending.length) {
        const all = await api("valuation_job_items?select=state&job_id=eq." + encodeURIComponent(id) + "&limit=10000", auth.token, { headers: { "Accept-Profile": "collection" } });
        const hasFailure = all.some((x: any) => x.state === "failed");
        await api("valuation_jobs?id=eq." + encodeURIComponent(id), auth.token, { method: "PATCH", headers: { "Content-Profile": "collection" }, body: JSON.stringify({ status: hasFailure ? "completed_with_gaps" : "completed", completed_at: new Date().toISOString(), updated_at: new Date().toISOString() }) });
      }
      return reply({ ok: true, job_id: id, processed_batch: done.length, remaining: pending.length, results: done });
    }
    return reply({ ok: false, error: "Azione non valida. Usare start, process o status." }, 400);
  } catch (e) {
    return reply({ ok: false, error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
