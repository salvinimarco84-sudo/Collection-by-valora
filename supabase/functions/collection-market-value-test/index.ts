import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

function reply(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: cors });
}
type Obj = Record<string, any>;
function numPrice(text: string): number | null {
  const match = text.match(/(?:€\s*|EUR\s*)(\d{1,6}(?:[.,]\d{1,2})?)|\b(\d{1,6}[.,]\d{2})\s*(?:€|EUR)\b/i);
  if (!match) return null;
  const raw = (match[1] ?? match[2] ?? "").replace(",", ".");
  const value = Number(raw);
  return Number.isFinite(value) && value > 0 && value < 1000000 ? value : null;
}
function evidencePrices(candidates: Obj[]): Array<{ value: number; url: string; title: string; snippet: string }> {
  const out: Array<{ value: number; url: string; title: string; snippet: string }> = [];
  const seen = new Set<string>();
  for (const candidate of candidates) {
    const title = String(candidate.title ?? "");
    const snippet = String(candidate.snippet ?? "");
    const evidence = (title + " " + snippet).toLowerCase();
    if (!/(venduto|vendita conclusa|vendite concluse|sold|sold listing|completed sale|sold for)/i.test(evidence)) continue;
    const value = numPrice(title + " " + snippet);
    const url = String(candidate.url ?? "");
    if (value === null || !url || seen.has(url)) continue;
    seen.add(url);
    out.push({ value, url, title, snippet });
  }
  return out;
}
function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ ok: false, error: "Usare POST." }, 405);

  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const authorization = req.headers.get("Authorization") ?? "";
  if (!base || !anon || !service || !authorization.startsWith("Bearer ")) {
    return reply({ ok: false, error: "Configurazione server o autenticazione non disponibile." }, 500);
  }
  let body: Obj;
  try { body = await req.json(); } catch { return reply({ ok: false, error: "JSON non valido." }, 400); }
  const mode = String(body.modalita_avvio ?? "MANUALE").trim().toUpperCase();
  if (mode !== "MANUALE" && mode !== "PROGRAMMATA") return reply({ ok: false, error: "modalita_avvio deve essere MANUALE o PROGRAMMATA." }, 400);

  // Blocco di sicurezza: la ricerca PR-12 può consumare crediti esterni.
  // La funzione resta disabilitata finché un operatore non abilita esplicitamente la variabile server.
  if (Deno.env.get("VALORA_PAID_RESEARCH_ENABLED") !== "true") {
    return reply({
      ok: false,
      codice: "RICERCA_A_PAGAMENTO_DISABILITATA",
      error: "Valutazione sospesa: le ricerche esterne sono disabilitate in modalità test. Nessun lotto è stato avviato e nessun credito API è stato utilizzato.",
      valutazione_avviata: false,
    }, 503);
  }

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

  const profileResponse = await fetch(
    base + "/rest/v1/master_utente?select=codice_utente,mercato_nazionale_principale,valuta_predefinita,mercati(codice_mercato,livello_mercato,nome_mercato)&auth_user_id=eq." + encodeURIComponent(userId),
    { headers: { ...adminHeaders, "Accept-Profile": "collection" } },
  );
  if (!profileResponse.ok) return reply({ ok: false, error: "Impossibile leggere profilo e mercato di riferimento." }, 502);
  const profiles = await profileResponse.json();
  if (!Array.isArray(profiles) || profiles.length !== 1) return reply({ ok: false, error: "Profilo utente assente o non univoco." }, 409);
  const profile = profiles[0];
  if (!profile.mercato_nazionale_principale || !profile.mercati) return reply({ ok: false, error: "Impostare un mercato di riferimento valido nel profilo." }, 409);

  let runId = Number(body.codice_valutazione ?? 0);
  let run: Obj | null = null;
  let ids: number[] = [];
  let offset = 0;
  let oldEvaluated = 0;
  let oldWithout = 0;

  if (body.esegui_valutazione === true && !runId) {
    const objectsUrl = base + "/rest/v1/master_oggetti?select=codice_oggetto,descrizione_oggetto,stato,quantita,destinazione,archiviato_test,produttore,anno_uscita,codice_prodotto,condizione,completezza&archiviato_test=eq.false&order=codice_oggetto.asc&limit=2000";
    const objectsResponse = await fetch(objectsUrl, { headers: { ...adminHeaders, "Accept-Profile": "collection" } });
    if (!objectsResponse.ok) return reply({ ok: false, error: "Impossibile leggere il perimetro della collezione.", dettaglio: (await objectsResponse.text()).slice(0, 250) }, 502);
    const objects: Obj[] = await objectsResponse.json();
    const excluded = new Set(["VENDUTO", "PERSO", "DISTRUTTO", "USCITO", "ACCORPATO"]);
    const eligible = objects.filter(o => String(o.destinazione ?? "").toUpperCase() === "COLLEZIONE" && !excluded.has(String(o.stato ?? "").toUpperCase()));
    ids = eligible.map(o => Number(o.codice_oggetto)).filter(Number.isFinite);
    const market = profile.mercati;
    const createResponse = await fetch(base + "/rest/v1/valutazioni_mercato", {
      method: "POST",
      headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=representation" },
      body: JSON.stringify({
        data_riferimento: new Date().toISOString().slice(0, 10),
        modalita_avvio: mode,
        stato_esecuzione: "AVVIATA",
        codice_mercato: profile.mercato_nazionale_principale,
        valuta_riferimento: String(profile.valuta_predefinita ?? "EUR").slice(0, 3),
        oggetti_esaminati: 0,
        oggetti_valutati: 0,
        oggetti_senza_stima: 0,
        report_riepilogo: { motore: "PR-18", fonte_ricerca: "PR-12", oggetti_ids: ids, prossimo_offset: 0, batch_size: 10, oggetti_con_stima: 0, oggetti_senza_stima: 0, avviso: "Sono registrate solo stime supportate da almeno due fonti di vendite concluse; i prezzi richiesti non sono considerati vendite concluse." },
      }),
    });
    if (!createResponse.ok) return reply({ ok: false, error: "Impossibile registrare l'avvio PR-18.", dettaglio: (await createResponse.text()).slice(0, 300) }, 502);
    const created = await createResponse.json();
    if (!Array.isArray(created) || !created.length) return reply({ ok: false, error: "PR-18 non ha restituito il codice della nuova valutazione." }, 502);
    run = created[0];
    runId = Number(run.codice_valutazione);
  } else {
    if (!runId) return reply({ ok: false, error: "Per proseguire è necessario il codice_valutazione restituito da PR-18." }, 400);
    const runResponse = await fetch(base + "/rest/v1/valutazioni_mercato?select=codice_valutazione,stato_esecuzione,oggetti_esaminati,oggetti_valutati,oggetti_senza_stima,report_riepilogo&codice_valutazione=eq." + runId, {
      headers: { ...adminHeaders, "Accept-Profile": "collection" },
    });
    if (!runResponse.ok) return reply({ ok: false, error: "Impossibile leggere lo stato della valutazione." }, 502);
    const runs = await runResponse.json();
    if (!Array.isArray(runs) || !runs.length) return reply({ ok: false, error: "Valutazione PR-18 non trovata." }, 404);
    run = runs[0];
    if (run.stato_esecuzione !== "AVVIATA") return reply({ ok: false, error: "La valutazione non è in stato AVVIATA.", stato_esecuzione: run.stato_esecuzione }, 409);
    const report = run.report_riepilogo ?? {};
    ids = Array.isArray(report.oggetti_ids) ? report.oggetti_ids.map(Number).filter(Number.isFinite) : [];
    offset = Number(report.prossimo_offset ?? 0);
    oldEvaluated = Number(report.oggetti_con_stima ?? run.oggetti_valutati ?? 0);
    oldWithout = Number(report.oggetti_senza_stima ?? run.oggetti_senza_stima ?? 0);
  }

  const batchSize = 10;
  let masterValuesUpdated = 0;
  const batchIds = ids.slice(offset, offset + batchSize);
  if (batchIds.length) {
    const objectResponse = await fetch(base + "/rest/v1/master_oggetti?select=codice_oggetto,descrizione_oggetto,produttore,anno_uscita,codice_prodotto,condizione,completezza,quantita&codice_oggetto=in.(" + batchIds.join(",") + ")", {
      headers: { ...adminHeaders, "Accept-Profile": "collection" },
    });
    if (!objectResponse.ok) return reply({ ok: false, codice_valutazione: runId, error: "Impossibile caricare il lotto da valutare.", dettaglio: (await objectResponse.text()).slice(0, 250) }, 502);
    const objectRows: Obj[] = await objectResponse.json();
    const byId = new Map(objectRows.map(o => [Number(o.codice_oggetto), o]));
    const batchObjects = batchIds.map(id => byId.get(id)).filter((o): o is Obj => Boolean(o));
    const searchResponse = await fetch(base + "/functions/v1/pr-12-web-search-corrected-test", {
      method: "POST",
      headers: { apikey: anon, Authorization: authorization, "Content-Type": "application/json" },
      body: JSON.stringify({
        mercato: "Italia",
        oggetti: batchObjects.map(o => ({
          id: String(o.codice_oggetto),
          descrizione: String(o.descrizione_oggetto ?? ""),
          codice_prodotto: o.codice_prodotto ?? "",
          produttore: o.produttore ?? "",
          categoria: "COLLEZIONABILE",
          mercato: "Italia",
        })),
      }),
    });
    if (!searchResponse.ok) return reply({ ok: false, codice_valutazione: runId, error: "Ricerca PR-12 non riuscita per il lotto.", dettaglio: (await searchResponse.text()).slice(0, 300) }, 502);
    const searchPayload = await searchResponse.json();
    const batchResults: Obj[] = Array.isArray(searchPayload.risultati_oggetti) ? searchPayload.risultati_oggetti : [];
    const histories: Obj[] = [];
    let countEstimate = 0;
    let countNoEstimate = 0;
    for (const o of batchObjects) {
      const found = batchResults.find(x => String(x.id) === String(o.codice_oggetto));
      const result = found?.risultato ?? {};
      const candidates: Obj[] = Array.isArray(result.risultati) ? result.risultati : [];
      const evidence = evidencePrices(candidates);
      const prices = evidence.map(x => x.value);
      const enough = evidence.length >= 2;
      if (enough) countEstimate++; else countNoEstimate++;
      histories.push({
        codice_valutazione: runId,
        codice_oggetto: o.codice_oggetto,
        data_riferimento: new Date().toISOString().slice(0, 10),
        valore_mercato: enough ? Math.round(median(prices) * 100) / 100 : null,
        valuta: "EUR",
        stato_stima: enough ? "PROVVISORIA" : "DATI_INSUFFICIENTI",
        numero_comparabili: evidence.length,
        affidabilita: enough ? "BASSA" : "NON_VALUTABILE",
        fonti_utilizzate: evidence.length ? evidence.map(x => ({ url: x.url, titolo: x.title, evidenza: "vendita_conclusa_con_prezzo_esplicito" })) : candidates.slice(0, 5).map(x => ({ url: x.url, titolo: x.title, motivo: "candidato PR-12, prezzo di vendita conclusa non confermato" })),
        query_eseguite: Array.isArray(result.query_eseguite) ? result.query_eseguite : [],
        intervallo_stima_min: enough ? Math.min(...prices) : null,
        intervallo_stima_max: enough ? Math.max(...prices) : null,
        nota_limiti: enough ? "Stima provvisoria basata su almeno due risultati distinti che dichiarano una vendita conclusa; verificare pertinenza, condizione e costi di spedizione." : "PR-12 ha cercato fonti, ma non sono emerse almeno due evidenze distinte e verificabili di vendite concluse con prezzo esplicito. Nessun valore è stato inventato.",
      });
    }
    if (histories.length) {
      const historyResponse = await fetch(base + "/rest/v1/storico_valori_mercato", {
        method: "POST",
        headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=minimal" },
        body: JSON.stringify(histories),
      });
      if (!historyResponse.ok) return reply({ ok: false, codice_valutazione: runId, error: "Impossibile salvare lo storico del lotto.", dettaglio: (await historyResponse.text()).slice(0, 300) }, 502);
    }

    // Il campo corrente viene aggiornato solo quando il lotto produce una stima supportata.
    // Le righe storiche restano immutate; una mancata stima non cancella l'ultimo valore valido.
    for (const history of histories) {
      if (history.valore_mercato === null || history.valore_mercato === undefined) continue;
      const masterUpdate = await fetch(
        base + "/rest/v1/master_oggetti?codice_oggetto=eq." + Number(history.codice_oggetto),
        {
          method: "PATCH",
          headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=representation" },
          body: JSON.stringify({ valore_mercato: history.valore_mercato }),
        },
      );
      if (!masterUpdate.ok) {
        return reply({
          ok: false,
          codice_valutazione: runId,
          error: "Storico salvato, ma aggiornamento di valore_mercato non riuscito per un oggetto.",
          codice_oggetto: history.codice_oggetto,
          dettaglio: (await masterUpdate.text()).slice(0, 300),
          valori_master_modificati: masterValuesUpdated,
        }, 502);
      }
      const updatedRows = await masterUpdate.json();
      if (Array.isArray(updatedRows) && updatedRows.length > 0) masterValuesUpdated++;
    }
    oldEvaluated += countEstimate;
    oldWithout += countNoEstimate;
  }

  const nextOffset = offset + batchIds.length;
  const total = ids.length;
  const more = nextOffset < total;
  const examined = nextOffset;
  const report = {
    motore: "PR-18",
    fonte_ricerca: "PR-12",
    oggetti_ids: ids,
    prossimo_offset: nextOffset,
    batch_size: batchSize,
    oggetti_con_stima: oldEvaluated,
    oggetti_senza_stima: oldWithout,
    avviso: "Sono registrate solo stime supportate da almeno due fonti di vendite concluse; i prezzi richiesti non sono considerati vendite concluse.",
  };
  const state = more ? "AVVIATA" : (oldWithout > 0 ? "COMPLETATA_PARZIALE" : "COMPLETATA");
  const updateResponse = await fetch(base + "/rest/v1/valutazioni_mercato?codice_valutazione=eq." + runId, {
    method: "PATCH",
    headers: { ...adminHeaders, "Accept-Profile": "collection", "Content-Profile": "collection", Prefer: "return=minimal" },
    body: JSON.stringify({
      stato_esecuzione: state,
      oggetti_esaminati: examined,
      oggetti_valutati: oldEvaluated,
      oggetti_senza_stima: oldWithout,
      report_riepilogo: report,
      ...(more ? {} : { completata_il: new Date().toISOString() }),
    }),
  });
  if (!updateResponse.ok) return reply({ ok: false, codice_valutazione: runId, error: "Impossibile aggiornare l'avanzamento PR-18.", dettaglio: (await updateResponse.text()).slice(0, 300) }, 502);

  return reply({
    ok: true,
    procedura: "PR-18",
    nome: "VALORE COLLEZIONE",
    codice_valutazione: runId,
    stato_esecuzione: state,
    mercato_riferimento: profile.mercati.nome_mercato ?? "Italia",
    oggetti_totali: total,
    oggetti_esaminati: examined,
    oggetti_valutati: oldEvaluated,
    oggetti_senza_stima: oldWithout,
    continua: more,
    prossimo_offset: nextOffset,
    dimensione_lotto: batchSize,
    stime_inventate: false,
    valori_master_modificati: masterValuesUpdated ?? 0,
    messaggio: more ? "Lotto registrato. Proseguire con il lotto successivo." : "Valutazione terminata. Sono state registrate soltanto stime supportate da evidenze di vendite concluse; gli altri oggetti restano senza stima.",
  });
});