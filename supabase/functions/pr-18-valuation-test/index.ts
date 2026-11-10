import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Metadata = {
  descrizione: string;
  produttore?: string;
  codice_prodotto?: string;
  anno_uscita?: string | number;
  categoria?: string;
  linea_serie?: string;
  fonte_dati_prodotto?: string;
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function validHttpUrl(value: unknown): string | undefined {
  const candidate = String(value ?? "").trim();
  return /^https?:\/\//i.test(candidate) ? candidate : undefined;
}

function parsePrice(text: string): number | undefined {
  const patterns = [
    /(?:€|eur\s?)(\s?\d{1,4}(?:[.,]\d{1,2})?)/i,
    /(\d{1,4}(?:[.,]\d{1,2})?)\s?(?:€|eur)/i,
  ];
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (!match) continue;
    const value = Number(match[1].replace(/\s/g, "").replace(",", "."));
    if (Number.isFinite(value) && value >= 0.5 && value <= 100000) return value;
  }
  return undefined;
}

function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "Usare POST." }, 405);

  const authorization = req.headers.get("Authorization") ?? "";
  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  if (!authorization.startsWith("Bearer ") || !base || !anonKey) {
    return json({ ok: false, error: "Sessione autenticata TEST non disponibile." }, 401);
  }

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ ok: false, error: "JSON non valido." }, 400); }

  const raw = body.metadati;
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return json({ ok: false, error: "Sono richiesti i metadati del candidato PR12 confermato." }, 400);
  }
  const metadata = raw as Record<string, unknown>;
  const descrizione = String(metadata.descrizione ?? metadata.title ?? "").trim().slice(0, 300);
  const mercato = String(body.mercato_riferimento ?? "ITALIA").trim().toUpperCase();
  if (descrizione.length < 2) return json({ ok: false, error: "Descrizione confermata non valida." }, 400);
  if (!["ITALIA", "EUROPA", "NORD_AMERICA", "SUD_AMERICA", "ASIA", "OCEANIA", "AFRICA", "MONDO"].includes(mercato)) {
    return json({ ok: false, error: "Mercato di riferimento non valido." }, 400);
  }

  const confirmed: Metadata = {
    descrizione,
    ...(metadata.produttore ? { produttore: String(metadata.produttore).slice(0, 160) } : {}),
    ...(metadata.codice_prodotto ? { codice_prodotto: String(metadata.codice_prodotto).slice(0, 120) } : {}),
    ...(metadata.anno_uscita ? { anno_uscita: String(metadata.anno_uscita).slice(0, 10) } : {}),
    ...(metadata.categoria ? { categoria: String(metadata.categoria).slice(0, 100) } : {}),
    ...(metadata.linea_serie ? { linea_serie: String(metadata.linea_serie).slice(0, 160) } : {}),
    ...(validHttpUrl(metadata.fonte_dati_prodotto) ? { fonte_dati_prodotto: validHttpUrl(metadata.fonte_dati_prodotto) } : {}),
  };

  // PR18 usa PR12 come motore di ricerca. La query di mercato è distinta dalla
  // ricerca catalografica iniziale: cerca prezzi/comparabili, senza riutilizzare
  // i risultati identificativi come se fossero vendite concluse.
  const query = [
    confirmed.descrizione,
    confirmed.produttore,
    confirmed.codice_prodotto,
    confirmed.anno_uscita,
    "prezzo vendita venduto",
    mercato,
  ].filter(Boolean).join(" ");

  try {
    const response = await fetch(base + "/functions/v1/pr-12-web-search-test", {
      method: "POST",
      headers: {
        apikey: anonKey,
        Authorization: authorization,
        "Content-Type": "application/json",
      },
      signal: AbortSignal.timeout(45000),
      body: JSON.stringify({
        descrizione: query,
        categoria: confirmed.categoria ?? "",
        tema: confirmed.linea_serie ?? confirmed.produttore ?? "",
        mercato,
      }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload?.ok === false) {
      return json({
        ok: false,
        motore: "PR18",
        dipendenza: "PR12",
        stato: "RICERCA_COMPARABILI_NON_COMPLETATA",
        error: String(payload?.error ?? "PR12 non ha completato la ricerca di mercato."),
        valutazione_numerica_disponibile: false,
      }, 502);
    }

    const results = Array.isArray(payload?.risultati) ? payload.risultati : [];
    const comparables = results.map((item: Record<string, unknown>) => {
      const title = String(item.title ?? "");
      const snippet = String(item.snippet ?? "");
      const price = parsePrice(title + " " + snippet);
      return {
        titolo: title.slice(0, 300),
        url: validHttpUrl(item.url),
        fonte: String(item.motore ?? "PR12"),
        estratto: snippet.slice(0, 500),
        prezzo_rilevato: price ?? null,
        prezzo_confermato: false,
      };
    }).filter((item: Record<string, unknown>) => item.url);

    const priced = comparables.filter((item: Record<string, unknown>) => typeof item.prezzo_rilevato === "number");
    const prices = priced.map((item: Record<string, unknown>) => Number(item.prezzo_rilevato));
    const central = prices.length ? median(prices) : null;
    const sorted = [...prices].sort((a, b) => a - b);
    const low = sorted.length ? sorted[Math.floor((sorted.length - 1) * 0.25)] : null;
    const high = sorted.length ? sorted[Math.ceil((sorted.length - 1) * 0.75)] : null;
    const reliability = prices.length >= 5 ? "MEDIA" : prices.length >= 2 ? "BASSA" : "MOLTO_BASSA";

    return json({
      ok: true,
      motore: "PR18",
      dipendenza: "PR12",
      sequenza: ["PR12_IDENTIFICAZIONE", "CONFERMA_UTENTE", "PR18_VALUTAZIONE_MERCATO"],
      stato: prices.length ? "VALUTAZIONE_COMPLETATA_CON_EVIDENZE_LIMITATE" : "RICERCA_COMPLETATA_SENZA_PREZZI_VERIFICABILI",
      oggetto_confermato: confirmed,
      mercato_riferimento: mercato,
      data_riferimento: new Date().toISOString(),
      numero_risultati_pr12: results.length,
      numero_comparabili_con_prezzo_estratto: prices.length,
      comparabili: comparables.slice(0, 20),
      valore_mercato: central,
      fascia_minima: low,
      fascia_massima: high,
      affidabilita: reliability,
      valutazione_numerica_disponibile: prices.length > 0,
      avvertenze: [
        "I prezzi estratti da titoli o snippet sono indizi, non vendite concluse certificate.",
        "Verificare condizioni, completezza, variante, spedizione e data prima di considerare il comparabile.",
        "Non sono state create o modificate schede inventario, acquisti o vendite.",
      ],
      scrittura_database: false,
      ricerca_esterna_eseguita: true,
    });
  } catch (error) {
    return json({
      ok: false,
      motore: "PR18",
      dipendenza: "PR12",
      stato: "ERRORE_RICERCA",
      error: error instanceof Error ? error.message : String(error),
      valutazione_numerica_disponibile: false,
      scrittura_database: false,
    }, 502);
  }
});
