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
  const metadata = (body.metadati && typeof body.metadati === "object" ? body.metadati : body) as Record<string, unknown>;
  const descrizione = String(metadata.descrizione ?? metadata.title ?? body.descrizione ?? "").trim().slice(0, 240);
  if (!descrizione || descrizione.length < 2) return reply({ ok: false, error: "Inserire una descrizione di almeno 2 caratteri." }, 400);
  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  if (!base) return reply({ ok: false, error: "SUPABASE_URL non configurato." }, 500);
  // Il salvataggio della sola valutazione aggiorna esclusivamente il valore di mercato
  // e lo storico. Stato e destinazione dell'oggetto non vengono mai modificati.
  if (String(body.azione ?? "").toUpperCase() === "SALVA_VALUTAZIONE") {
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!anon || !service) return reply({ ok: false, error: "Configurazione autorizzazioni non disponibile." }, 500);
    const authResponse = await fetch(base + "/auth/v1/user", { headers: { apikey: anon, Authorization: authorization } });
    if (!authResponse.ok) return reply({ ok: false, error: "Sessione non valida o scaduta." }, 401);
    const authUser = await authResponse.json();
    const userId = String(authUser?.id ?? "");
    if (!userId) return reply({ ok: false, error: "Utente autenticato non identificabile." }, 401);
    const adminHeaders = { apikey: service, Authorization: "Bearer " + service, "Content-Type": "application/json" };
    const allowedResponse = await fetch(base + "/rest/v1/app_authorized_users?select=user_id&user_id=eq." + encodeURIComponent(userId) + "&attivo=eq.true", {
      headers: { ...adminHeaders, "Accept-Profile": "collection" },
    });
    if (!allowedResponse.ok) return reply({ ok: false, error: "Verifica autorizzazione non riuscita." }, 502);
    const allowed = await allowedResponse.json();
    if (!Array.isArray(allowed) || !allowed.length) return reply({ ok: false, error: "Utente non autorizzato all'applicazione." }, 403);
    const objectId = Number(body.codice_oggetto);
    if (!Number.isSafeInteger(objectId) || objectId <= 0) return reply({ ok: false, error: "Codice oggetto non valido." }, 400);
    const valuation = (body.valutazione && typeof body.valutazione === "object" ? body.valutazione : {}) as Record<string, unknown>;
    const rawValue = valuation.valore_mercato;
    const estimate = typeof rawValue === "number" && Number.isFinite(rawValue) && rawValue > 0 ? Math.round(rawValue * 100) / 100 : null;
    const objectResponse = await fetch(base + "/rest/v1/master_oggetti?select=codice_oggetto,stato,destinazione,archiviato_test&codice_oggetto=eq." + objectId + "&archiviato_test=eq.false", {
      headers: { ...adminHeaders, "Accept-Profile": "collection" },
    });
    if (!objectResponse.ok) return reply({ ok: false, error: "Impossibile verificare l'oggetto prima del salvataggio." }, 502);
    const objectRows = await objectResponse.json();
    if (!Array.isArray(objectRows) || objectRows.length !== 1) return reply({ ok: false, error: "Oggetto non trovato o archiviato." }, 404);
    const object = objectRows[0];
    const currentStatus = String(object.stato ?? "").trim().toUpperCase();
    if (["VENDUTO", "SOLD", "PERSO", "LOST", "DISTRUTTO", "DESTROYED", "USCITO", "EXITED", "ACCORPATO", "MERGED"].includes(currentStatus)) {
      return reply({ ok: false, error: "L'oggetto non è più idoneo alla valutazione: " + currentStatus }, 409);
    }
    const profileResponse = await fetch(base + "/rest/v1/master_utente?select=codice_utente,mercato_nazionale_principale,valuta_predefinita,mercati(codice_mercato,nome_mercato)&auth_user_id=eq." + encodeURIComponent(userId), {
      headers: { ...adminHeaders, "Accept-Profile": "collection" },
    });
    if (!profileResponse.ok) return reply({ ok: false, error: "Impossibile leggere il mercato configurato nel profilo." }, 502);
    const profiles = await profileResponse.json();
    if (!Array.isArray(profiles) || profiles.length !== 1 || !profiles[0].mercato_nazionale_principale) {
      return reply({ ok: false, error: "Profilo utente o mercato di riferimento assente." }, 409);
    }
    const profile = profiles[0];
    const marketName = String(profile.mercati?.nome_mercato ?? "");
    const comparables = Array.isArray(valuation.comparabili) ? valuation.comparabili.slice(0, 100) as Candidate[] : [];
    const sold = comparables.filter((item) => String(item.tipo_prezzo ?? "").toUpperCase() === "VENDITA_CONCLUSA");
    const rawReliability = String(valuation.affidabilita ?? "NON_VALUTABILE").toUpperCase();
    const reliability = rawReliability === "ALTA" || rawReliability === "MEDIA" || rawReliability === "BASSA"
      ? rawReliability : rawReliability === "MOLTO_BASSA" ? "BASSA" : "NON_VALUTABILE";
    const today = new Date().toISOString().slice(0, 10);
    const runResponse = await fetch(base + "/rest/v1/valutazioni_mercato", {
      method: "POST",
      headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=representation" },
      body: JSON.stringify({
        data_riferimento: today, modalita_avvio: "MANUALE",
        stato_esecuzione: estimate === null ? "COMPLETATA_PARZIALE" : "COMPLETATA",
        codice_mercato: profile.mercato_nazionale_principale, valuta_riferimento: "EUR",
        oggetti_esaminati: 1, oggetti_valutati: estimate === null ? 0 : 1,
        oggetti_senza_stima: estimate === null ? 1 : 0,
        report_riepilogo: {
          motore: "PR-18", fonte_ricerca: "PR-12", oggetti_ids: [objectId],
          mercato_riferimento: marketName, oggetti_con_stima: estimate === null ? 0 : 1,
          oggetti_senza_stima: estimate === null ? 1 : 0, affidabilita: reliability,
          valore_mercato: estimate, stato_oggetto_prima_del_salvataggio: currentStatus,
          destinazione_prima_del_salvataggio: String(object.destinazione ?? ""),
        },
      }),
    });
    if (!runResponse.ok) return reply({ ok: false, error: "Impossibile creare lo storico della valutazione.", dettaglio: (await runResponse.text()).slice(0, 300) }, 502);
    const runs = await runResponse.json();
    if (!Array.isArray(runs) || runs.length !== 1) return reply({ ok: false, error: "Codice storico valutazione non restituito." }, 502);
    const runId = Number(runs[0].codice_valutazione);
    const history = {
      codice_valutazione: runId, codice_oggetto: objectId, data_riferimento: today,
      valore_mercato: estimate, valuta: "EUR",
      stato_stima: estimate === null ? "DATI_INSUFFICIENTI" : "PROVVISORIA",
      numero_comparabili: sold.length, affidabilita: reliability,
      fonti_utilizzate: comparables.map((item) => ({
        url: String(item.url ?? ""), titolo: String(item.titolo ?? ""),
        tipo_prezzo: String(item.tipo_prezzo ?? "NON_CLASSIFICATO"),
        prezzo_eur: typeof item.prezzo_eur === "number" ? item.prezzo_eur : null,
        usato_per_stima: String(item.tipo_prezzo ?? "").toUpperCase() === "VENDITA_CONCLUSA",
      })),
      query_eseguite: Array.isArray(valuation.query_eseguite) ? valuation.query_eseguite : [],
      intervallo_stima_min: typeof valuation.fascia_minima === "number" ? valuation.fascia_minima : null,
      intervallo_stima_max: typeof valuation.fascia_massima === "number" ? valuation.fascia_massima : null,
      nota_limiti: String(valuation.avvertenza ?? "Valutazione PR-18/PR-12. Stima orientativa, non prezzo garantito di realizzo."),
    };
    const historyResponse = await fetch(base + "/rest/v1/storico_valori_mercato", {
      method: "POST",
      headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=minimal" },
      body: JSON.stringify(history),
    });
    if (!historyResponse.ok) return reply({ ok: false, error: "Storico creato, ma registrazione della rilevazione non riuscita.", dettaglio: (await historyResponse.text()).slice(0, 300) }, 502);
    let masterUpdated = false;
    if (estimate !== null) {
      const filter = "&stato=eq." + encodeURIComponent(String(object.stato)) + "&destinazione=eq." + encodeURIComponent(String(object.destinazione));
      const updateResponse = await fetch(base + "/rest/v1/master_oggetti?codice_oggetto=eq." + objectId + filter, {
        method: "PATCH",
        headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=representation" },
        body: JSON.stringify({ valore_mercato: estimate }),
      });
      if (!updateResponse.ok) return reply({ ok: false, error: "Storico salvato, ma aggiornamento del valore di mercato non riuscito.", dettaglio: (await updateResponse.text()).slice(0, 300) }, 502);
      const updated = await updateResponse.json();
      if (!Array.isArray(updated) || updated.length !== 1) return reply({ ok: false, error: "La valutazione è stata registrata, ma l'oggetto è cambiato durante il salvataggio. Stato e destinazione sono rimasti intatti." }, 409);
      masterUpdated = true;
      if (String(updated[0].stato) !== String(object.stato) || String(updated[0].destinazione) !== String(object.destinazione)) {
        return reply({ ok: false, error: "Verifica post-salvataggio non superata: stato o destinazione inattesi." }, 409);
      }
    }
    return reply({
      ok: true, procedura: "PR-18", codice_valutazione: runId, codice_oggetto: objectId,
      valore_master_aggiornato: masterUpdated, valore_mercato: estimate,
      stato_oggetto: String(object.stato), destinazione: String(object.destinazione), storico_salvato: true,
      messaggio: masterUpdated ? "Valutazione e storico salvati. Stato e destinazione dell'oggetto invariati."
        : "Storico valutazione salvato senza sovrascrivere l'ultimo valore: non è disponibile una stima numerica affidabile.",
    });
  }
  try {
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!anon || !service) return reply({ ok: false, error: "Configurazione autorizzazioni non disponibile." }, 500);
    const authResponse = await fetch(base + "/auth/v1/user", {
      headers: { apikey: anon, Authorization: authorization },
    });
    if (!authResponse.ok) return reply({ ok: false, error: "Sessione non valida o scaduta." }, 401);
    const authUser = await authResponse.json();
    const userId = String(authUser?.id ?? "");
    if (!userId) return reply({ ok: false, error: "Utente autenticato non identificabile." }, 401);
    const adminHeaders = { apikey: service, Authorization: "Bearer " + service, "Content-Type": "application/json" };
    const profileResponse = await fetch(
      base + "/rest/v1/master_utente?select=mercato_nazionale_principale,mercati(codice_mercato,nome_mercato)&auth_user_id=eq." + encodeURIComponent(userId),
      { headers: { ...adminHeaders, "Accept-Profile": "collection" } },
    );
    if (!profileResponse.ok) return reply({ ok: false, error: "Impossibile leggere il mercato configurato nel profilo utente." }, 502);
    const profiles = await profileResponse.json();
    if (!Array.isArray(profiles) || profiles.length !== 1 ||
        !profiles[0].mercato_nazionale_principale || !profiles[0].mercati?.nome_mercato) {
      return reply({ ok: false, error: "Completa il profilo e configura un mercato principale prima di avviare PR-18." }, 409);
    }
    const marketName = String(profiles[0].mercati.nome_mercato).slice(0, 40);
    const response = await fetch(base + "/functions/v1/pr-12-web-search-corrected-test", {
      method: "POST",
      headers: { apikey, Authorization: authorization, "Content-Type": "application/json" },
      signal: AbortSignal.timeout(45000),
      body: JSON.stringify({
        descrizione,
        categoria: String(metadata.categoria ?? "COLLEZIONABILE").slice(0, 40),
        codice_prodotto: String(metadata.codice_prodotto ?? "").slice(0, 100),
        produttore: String(metadata.produttore ?? "").slice(0, 160),
        mercato: marketName,
      }),
    });
    const searched = await response.json().catch(() => ({}));
    if (!response.ok || searched?.ok === false) {
      return reply({ ok: false, procedura: "PR-18", motore: "VALORA", errore_fonte: "PR-12", error: String(searched?.error ?? "Ricerca PR-12 non riuscita."), scrittura_database: false }, 502);
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
    const realizedSales = comparables.filter((x) => x.tipo_prezzo === "VENDITA_CONCLUSA");
    const prices = realizedSales.map((x) => x.prezzo_eur);
    const estimate = prices.length ? Math.round(median(prices) * 100) / 100 : null;
    const low = prices.length ? Math.min(...prices) : null;
    const high = prices.length ? Math.max(...prices) : null;
    const reliability = prices.length >= 5 ? "MEDIA" : prices.length >= 2 ? "BASSA" : prices.length === 1 ? "MOLTO_BASSA" : "NON_VALUTABILE";
    return reply({
      ok: true,
      procedura: "PR-18",
      nome: "PR18 · VALORA · VALUTAZIONE SINGOLO OGGETTO",
      oggetto_confermato: { descrizione, produttore: String(metadata.produttore ?? ""), codice_prodotto: String(metadata.codice_prodotto ?? "") },
      mercato_riferimento: marketName,
      valore_mercato: estimate,
      fascia_minima: low,
      fascia_massima: high,
      numero_comparabili_con_prezzo_estratto: comparables.length,
      numero_vendite_concluse: realizedSales.length,
      valuta: "EUR",
      valore_stimato: estimate,
      intervallo_min: low,
      intervallo_max: high,
      numero_comparabili: comparables.length,
      numero_comparabili_usati_per_stima: realizedSales.length,
      affidabilita: reliability,
      comparabili,
      stato_stima: prices.length >= 5 ? "PROVVISORIA" : prices.length > 0 ? "INDICATIVA" : "DATI_INSUFFICIENTI",
      avvertenza: prices.length
        ? "Stima orientativa basata sui prezzi espliciti trovati da PR-12. Prezzi richiesti/catalogo e vendite concluse sono distinti; non è un prezzo garantito di realizzo."
        : "PR-12 non ha restituito prezzi espliciti utilizzabili. Nessun valore è stato inventato: completa l'oggetto e riprova la valutazione.",
      scrittura_database: false,
      fonte_ricerca: "PR-12",
      dipendenza: "PR12",
      valutazione_numerica_disponibile: estimate !== null,
    });
  } catch (error) {
    return reply({ ok: false, procedura: "PR-18", error: error instanceof Error ? error.message : String(error), scrittura_database: false }, 502);
  }
});