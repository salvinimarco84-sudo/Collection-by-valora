import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};
function reply(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: cors });
}
type Candidate = Record<string, unknown>;
function priceFrom(text: string): number | null {
  const patterns = [
    /(?:€|EUR)\s*(\d{1,6}(?:[.,]\d{1,2})?)/i,
    /(\d{1,6}(?:[.,]\d{1,2})?)\s*(?:€|EUR)\b/i,
  ];
  for (const pattern of patterns) {
    const m = text.match(pattern);
    if (!m) continue;
    const value = Number(m[1].replace(",", "."));
    if (Number.isFinite(value) && value > 0 && value < 1000000) return Math.round(value * 100) / 100;
  }
  return null;
}
function median(values: number[]): number {
  const v = [...values].sort((a, b) => a - b);
  const mid = Math.floor(v.length / 2);
  return v.length % 2 ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ ok: false, error: "Usare POST." }, 405);
  const authorization = req.headers.get("Authorization") ?? "";
  const apikey = req.headers.get("apikey") ?? "";
  if (!authorization.startsWith("Bearer ") || !apikey) return reply({ ok: false, error: "Sessione autenticata richiesta." }, 401);
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return reply({ ok: false, error: "JSON non valido." }, 400); }
  const descrizione = String(body.descrizione ?? "").trim().slice(0, 240);
  if (descrizione.length < 2) return reply({ ok: false, error: "Inserire una descrizione di almeno 2 caratteri." }, 400);
  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  if (!base) return reply({ ok: false, error: "SUPABASE_URL non configurato." }, 500);
  try {
    const response = await fetch(base + "/functions/v1/pr-12-web-search-corrected-test", {
      method: "POST",
      headers: { apikey, Authorization: authorization, "Content-Type": "application/json" },
      signal: AbortSignal.timeout(45000),
      body: JSON.stringify({
        descrizione,
        categoria: String(body.categoria ?? "COLLEZIONABILE").slice(0, 40),
        codice_prodotto: String(body.codice_prodotto ?? "").slice(0, 100),
        produttore: String(body.produttore ?? "").slice(0, 160),
        mercato: String(body.mercato ?? "Italia").slice(0, 40),
      }),
    });
    const searched = await response.json().catch(() => ({}));
    if (!response.ok || searched?.ok === false) {
      return reply({ ok: false, procedura: "PR-19", motore: "VALORA", errore_fonte: "PR-12", error: String(searched?.error ?? "Ricerca PR-12 non riuscita."), scrittura_database: false }, 502);
    }
    const candidates: Candidate[] = Array.isArray(searched.risultati) ? searched.risultati : [];
    const seen = new Set<string>();
    const comparables = candidates.flatMap((candidate) => {
      const url = String(candidate.url ?? candidate.source_url ?? "").trim();
      const title = String(candidate.title ?? candidate.titolo ?? "").trim();
      const snippet = String(candidate.snippet ?? candidate.description ?? "").trim();
      if (!url || !/^https?:\/\//i.test(url) || seen.has(url)) return [];
      const value = priceFrom(title + " " + snippet);
      if (value === null) return [];
      seen.add(url);
      const combined = (title + " " + snippet).toLowerCase();
      const tipoPrezzo = /(venduto|vendita conclusa|vendite concluse|sold|completed sale|sold for)/i.test(combined)
        ? "VENDITA_CONCLUSA" : "PREZZO_RICHIESTO_O_CATALOGO";
      return [{ titolo: title || "Comparabile senza titolo", url, snippet: snippet.slice(0, 500), prezzo_eur: value, tipo_prezzo: tipoPrezzo }];
    });
    const prices = comparables.map((x) => x.prezzo_eur);
    const estimate = prices.length ? Math.round(median(prices) * 100) / 100 : null;
    const low = prices.length ? Math.min(...prices) : null;
    const high = prices.length ? Math.max(...prices) : null;
    const reliability = prices.length >= 5 ? "MEDIA" : prices.length >= 2 ? "BASSA" : prices.length === 1 ? "MOLTO_BASSA" : "NON_VALUTABILE";
    return reply({
      ok: true,
      procedura: "PR-19",
      nome: "VALORA · VALUTAZIONE SINGOLO OGGETTO",
      oggetto: { descrizione, produttore: String(body.produttore ?? ""), codice_prodotto: String(body.codice_prodotto ?? "") },
      mercato: String(body.mercato ?? "Italia"),
      valuta: "EUR",
      valore_stimato: estimate,
      intervallo_min: low,
      intervallo_max: high,
      numero_comparabili: comparables.length,
      affidabilita: reliability,
      comparabili,
      stato_stima: prices.length >= 5 ? "PROVVISORIA" : prices.length > 0 ? "INDICATIVA" : "DATI_INSUFFICIENTI",
      avvertenza: prices.length
        ? "Stima orientativa basata sui prezzi espliciti trovati da PR-12. Prezzi richiesti/catalogo e vendite concluse sono distinti; non è un prezzo garantito di realizzo."
        : "PR-12 non ha restituito prezzi espliciti utilizzabili. Nessun valore è stato inventato: completa l'oggetto e riprova la valutazione.",
      scrittura_database: false,
      fonte_ricerca: "PR-12",
    });
  } catch (error) {
    return reply({ ok: false, procedura: "PR-19", error: error instanceof Error ? error.message : String(error), scrittura_database: false }, 502);
  }
});