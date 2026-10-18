import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
type SearchResult = { title: string; url: string; snippet: string; source_query: string; motore: string };
function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" } });
}
function decodeEntities(value: string): string {
  return value.replace(/&nbsp;|&#160;|&#xA0;/gi, " ").replace(/&amp;/gi, "&").replace(/&quot;/gi, '"').replace(/&apos;/gi, "'")
    .replace(/&#x27;|&#39;/gi, "'").replace(/&lt;/gi, "<").replace(/&gt;/gi, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)));
}
function cleanText(value: string): string { return decodeEntities(value.replace(/<script[\s\S]*?<\/script>/gi, " ").replace(/<style[\s\S]*?<\/style>/gi, " ").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ")).trim(); }
function codeFrom(description: string): string | undefined { return description.match(/\b\d{4,8}(?:-\d+)?\b/)?.[0]?.split("-")[0]; }
function isLego(category: string, description: string): boolean {
  return category === "LEGO" || /lego|minifig|brickheadz|technic|duplo|bricklink/i.test(description);
}
function sourcesFor(category: string, query: string): string[] {
  if (isLego(category, query)) return ["Brickset", "BrickLink", "Rebrickable", "LEGO.com"];
  if (/transformers|optimus prime|bumblebee|megatron|hasbro/i.test(query)) return ["site:hasbro.com", "site:hasbropulse.com", "site:transformers.com", "site:tfwiki.net"];
  if (/fumett|comic|manga|panini|salda|bonelli/i.test(query) || category === "FUMETTI") return ["site:comics.org", "site:leagueofcomicgeeks.com", "site:panini.it", "site:saldaPress.com"];
  if (/myth cloth|saint seiya|bandai|gundam|dragon ball|action figure|statua/i.test(query) || category === "ACTION_FIGURE") return ["site:tamashiiweb.com", "site:bandai.com", "site:myfigurecollection.net"];
  if (/maisto|die.cast|moto|motorbike|modellino/i.test(query)) return ["site:maisto.com", "site:diecast.org"];
  if (/saint seiya|myth cloth/i.test(query)) return ["site:tamashiiweb.com", "site:myfigurecollection.net"];
  return [];
}
async function fetchText(url: string, timeout = 9000): Promise<string> {
  const response = await fetch(url, {
    headers: { "User-Agent": "Mozilla/5.0 (compatible; VALORA-Collector/1.0)", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "Accept-Language": "en-US,en;q=0.9,it;q=0.7" },
    signal: AbortSignal.timeout(timeout),
  });
  if (!response.ok) throw new Error("HTTP " + response.status + " da " + new URL(url).hostname);
  return await response.text();
}
async function searchDcBatmanHush(description: string): Promise<SearchResult[]> {
  if (!/batman/i.test(description) || !/hush/i.test(description)) return [];
  const pages = [
    "https://www.dc.com/graphic-novels/batman-hush",
    "https://www.dc.com/graphic-novels/batman-hush-new-edition",
    "https://www.dc.com/graphic-novels/batman-hush-dc-essential-edition"
  ];
  const results: SearchResult[] = [];
  for (const url of pages) {
    try {
      const html = await fetchText(url, 7000);
      const title = cleanText(html.match(/<h1\b[^>]*>([\s\S]*?)<\/h1>/i)?.[1] ?? html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "");
      const descriptionTag = html.match(/<meta\b[^>]*name=["']description["'][^>]*content=["']([^"']*)["']/i)?.[1]
        ?? html.match(/<meta\b[^>]*content=["']([^"']*)["'][^>]*name=["']description["']/i)?.[1] ?? "";
      if (/batman/i.test(title) && /hush/i.test(title + " " + descriptionTag)) {
        results.push({ title, url, snippet: cleanText(descriptionTag) || "Scheda ufficiale DC del graphic novel Batman: Hush. Verificare edizione e formato nella pagina.", source_query: description, motore: "DC_CATALOGO_DIRETTO" });
      }
    } catch { /* il sito può limitare richieste automatiche */ }
  }
  return results;
}

async function searchBrickset(code: string): Promise<SearchResult[]> {
  const searchUrl = "https://brickset.com/sets?query=" + encodeURIComponent(code);
  const html = await fetchText(searchUrl, 10000);
  const results: SearchResult[] = [];
  const anchors = html.match(/<a\b[^>]*href=["'][^"']*["'][^>]*>[\s\S]*?<\/a>/gi) ?? [];

  for (const anchor of anchors) {
    const hrefRaw = anchor.match(/\bhref=["']([^"']+)["']/i)?.[1];
    if (!hrefRaw) continue;
    const href = decodeEntities(hrefRaw);
    let parsed: URL;
    try { parsed = new URL(href, "https://brickset.com"); } catch { continue; }

    // Accetta esclusivamente la pagina del set cercato, non link a rating,
    // recensioni, immagini o pagine che contengono il codice nei parametri.
    // Brickset usa sia /sets/60400-1 sia /sets/60400-1/nome-del-set.
    // Accetta lo slug finale ma verifica sempre il codice nel segmento iniziale.
    const pathMatch = parsed.pathname.match(/^\/sets\/(\d{4,8})(?:-(\d+))?(?:\/[^/]+)?\/?$/i);
    if (!pathMatch || pathMatch[1] !== code) continue;

    const title = cleanText(anchor.replace(/<img\b[^>]*>/gi, " "));
    if (!title || title.length < 5 || /^(?:\d+|ratings?|reviews?|images?)$/i.test(title)) continue;

    // Conserva lo slug canonico restituito da Brickset: può contenere il titolo
    // e rappresentare una pagina più precisa del percorso numerico nudo.
    const canonical = parsed.origin + parsed.pathname;
    const key = canonical.replace(/\/$/, "");
    if (results.some(r => r.url === key)) continue;
    results.push({
      title: title.replace(/\s*[|·]\s*Brickset\s*$/i, "").trim(),
      url: canonical,
      snippet: "Candidato trovato nel catalogo Brickset per il codice esatto " + code + ". Aprire la fonte per verificare nome, anno e dettagli.",
      source_query: "Brickset codice esatto " + code,
      motore: "BRICKSET_CATALOGO"
    });
  }

  if (results.length) return results.slice(0, 5);

  // Fallback sulla pagina canonica, controllando che il codice compaia nel titolo.
  const detailUrl = "https://brickset.com/sets/" + code + "-1";
  try {
    const detail = await fetchText(detailUrl, 8000);
    const pageTitle = cleanText(detail.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "");
    const h1 = cleanText(detail.match(/<h1\b[^>]*>([\s\S]*?)<\/h1>/i)?.[1] ?? "");
    const combined = pageTitle + " " + h1;
    if (new RegExp("(^|[^0-9])" + code + "([^0-9]|$)").test(combined)) {
      const heading = h1 || pageTitle;
      // Preferisce il titolo canonico "60400 Go-Karts and Race Drivers"
      // e rimuove il marchio Brickset, senza inventare metadati.
      const title = heading.replace(/\s*[|·]\s*Brickset\s*$/i, "").trim();
      const yearMatch = detail.match(/(?:City|Technic|Friends|Star Wars|Icons|Creator|NINJAGO|Classic|Racing|Space|Marvel|DC|Minecraft|DUPLO|Ideas|Harry Potter)[^\n]{0,100}\b(19\d{2}|20\d{2})\b/i);
      const year = yearMatch?.[1] ?? "";
      return [{
        title: title || "Set LEGO " + code,
        url: detailUrl,
        snippet: year
          ? "Anno rilevato nella pagina Brickset: " + year + ". Verificare i dettagli nella fonte."
          : "Pagina catalogo Brickset per il codice " + code + ". Verificare i dettagli nella fonte.",
        source_query: "Brickset codice esatto " + code,
        motore: "BRICKSET_CATALOGO"
      }];
    }
  } catch { /* fallback generico controllato dal chiamante */ }
  return [];
}

type ConfiguredSource = { codice_fonte?: string; nome_fonte?: string; url_principale?: string; tipo_fonte?: string; ambito_ricerca?: string; produttore?: string; linea_prodotto?: string; famiglia_prodotto?: string; priorita_metadati?: number; stato_affidabilita?: string; riutilizzabile?: boolean };
type FranchiseRule = { franchise?: string; alias_ricerca?: string[]; codice_fonte_preferita?: string; priorita?: number; attiva?: boolean };
function supabaseConfig() {
  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SERVICE_ROLE_KEY") ?? "";
  return { base, key };
}
async function readConfigTable<T>(table: string, select = "*"): Promise<T[]> {
  const { base, key } = supabaseConfig();
  if (!base || !key) throw new Error("Configurazione Supabase interna non disponibile");
  const response = await fetch(base + "/rest/v1/" + table + "?select=" + encodeURIComponent(select), {
    headers: { apikey: key, Authorization: "Bearer " + key, "Accept-Profile": "collection", "Content-Profile": "collection" }, signal: AbortSignal.timeout(5000)
  });
  if (!response.ok) throw new Error("Lettura configurazione " + table + " fallita: HTTP " + response.status);
  const data = await response.json();
  return Array.isArray(data) ? data as T[] : [];
}
function normalizeText(value: unknown): string {
  return String(value ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}
function hostnameFromUrl(value: string): string {
  try { return new URL(value).hostname.replace(/^www\./i, ""); } catch { return ""; }
}
async function loadConfiguredSources(category: string, description: string): Promise<{ sources: ConfiguredSource[]; franchiseRules: FranchiseRule[]; queries: string[]; names: string[]; warnings: string[] }> {
  const warnings: string[] = [];
  let archive: ConfiguredSource[] = [];
  let rules: FranchiseRule[] = [];
  try { archive = await readConfigTable<ConfiguredSource>("archivio_fonti_ricerca", "codice_fonte,nome_fonte,url_principale,tipo_fonte,ambito_ricerca,produttore,linea_prodotto,famiglia_prodotto,priorita_metadati,stato_affidabilita,riutilizzabile"); }
  catch (e) { warnings.push("Archivio fonti: " + (e instanceof Error ? e.message : String(e))); }
  try { rules = await readConfigTable<FranchiseRule>("regole_ricerca_franchise", "franchise,alias_ricerca,codice_fonte_preferita,priorita,attiva"); }
  catch (e) { warnings.push("Regole franchise: " + (e instanceof Error ? e.message : String(e))); }
  const text = normalizeText(description + " " + category);
  const activeRules = rules.filter(r => r.attiva !== false && (r.alias_ricerca ?? []).some(alias => {
    const a = normalizeText(alias).trim(); return a.length >= 3 && text.includes(a);
  })).sort((a,b) => (a.priorita ?? 99) - (b.priorita ?? 99));
  const preferredCodes = new Set(activeRules.map(r => normalizeText(r.codice_fonte_preferita)).filter(Boolean));
  const categoryHints: Record<string,string[]> = {
    LEGO: ["lego", "brickset", "bricklink", "rebrickable"],
    FUMETTI: ["fumett", "comic", "panini", "bonelli", "salda", "manga", "graphic novel", "dc", "marvel", "batman", "spider-man"],
    ACTION_FIGURE: ["figure", "action figure", "myth cloth", "saint seiya", "bandai", "tamashii", "toy", "giocattol", "transformer", "robot", "gundam", "dragon ball", "hokuto", "naruto", "one piece", "star wars"],
    DIECAST: ["diecast", "maisto", "modellino", "motorbike", "moto", "auto", "robotvintage"],
    GIOCATTOLO: ["toy", "giocattol", "transformer", "robot", "figure", "kinder", "vintage", "sorpresine", "astrocollection", "collectingkinder", "toyvault"],
    COLLEZIONABILE: ["collectible", "collectibles", "kinder", "sorpresine", "toy", "giocattol", "saint seiya", "myth cloth", "gundam", "gunpla", "diecast", "maisto", "fumett", "comic", "manga", "robot", "star wars", "transformer"]
  };
  const hints = categoryHints[category] ?? [];
  const matching = archive.filter(s => s.riutilizzabile !== false && s.url_principale && hostnameFromUrl(s.url_principale)).filter(s => {
    const haystack = normalizeText([s.codice_fonte,s.nome_fonte,s.produttore,s.linea_prodotto,s.famiglia_prodotto].join(" "));
    const franchiseMatch = preferredCodes.has(normalizeText(s.codice_fonte)) ||
      activeRules.some(r => normalizeText(s.famiglia_prodotto).includes(normalizeText(r.franchise)) || normalizeText(s.linea_prodotto).includes(normalizeText(r.franchise)));
    // La categoria generica non deve caricare fonti casuali: abbina la descrizione
    // a produttore, linea, famiglia, nome o codice della fonte.
    const categoryMatch = category !== "COLLEZIONABILE" && hints.some(h => haystack.includes(normalizeText(h)));
    const descriptionTokens = normalizeText(description).split(/[^a-z0-9]+/).filter(t => t.length >= 4 && !/^\\d+$/.test(t));
    const descriptionMatch = descriptionTokens.some(token => haystack.includes(token));
    const productMatch = /transformer|optimus prime|bumblebee|megatron/i.test(description) && /transformer|hasbro|optimus|toy/i.test(haystack);
    const makerMatch = /lego/i.test(description) && /lego|brickset|bricklink|rebrickable/i.test(haystack);
    return franchiseMatch || categoryMatch || descriptionMatch || productMatch || makerMatch;
  }).sort((a,b) => (a.priorita_metadati ?? 99) - (b.priorita_metadati ?? 99));
  const unique: ConfiguredSource[] = []; const seen = new Set<string>();
  for (const s of matching) {
    const host = hostnameFromUrl(s.url_principale ?? "");
    if (!host || seen.has(host)) continue;
    seen.add(host); unique.push(s);
  }
  return { sources: unique, franchiseRules: activeRules, queries: unique.slice(0,8).map(s => "site:" + hostnameFromUrl(s.url_principale ?? "") + " " + description), names: unique.map(s => s.nome_fonte ?? s.codice_fonte ?? hostnameFromUrl(s.url_principale ?? "")), warnings };
}

function makeQueries(category: string, description: string): string[] {
  const code = codeFrom(description);
  const queries: string[] = [];
  const cleaned = description.replace(/["']/g, " ").replace(/\s+/g, " ").trim();
  const normalized = normalizeText(cleaned);
  if (code && isLego(category, description)) {
    queries.push('site:brickset.com/sets "' + code + '-1"');
    queries.push('site:bricklink.com/v2/catalog/catalogitem.page "' + code + '-1"');
    queries.push('site:rebrickable.com/sets "' + code + '"');
    queries.push('site:lego.com "' + cleaned + '"');
  } else {
    queries.push('"' + cleaned + '"');
    const targeted = sourcesFor(category, description).filter(s => s.startsWith("site:"));
    for (const site of targeted) queries.push(site + ' "' + cleaned + '"');
    if (/batman|long halloween|lungo halloween|fumett|comic/i.test(normalized)) {
      queries.push('site:comics.org "' + cleaned + '"');
      queries.push('site:leagueofcomicgeeks.com "' + cleaned + '"');
      queries.push('site:dc.com "' + cleaned + '"');
      queries.push('site:panini.it "' + cleaned + '"');
    }
    if (/optimus prime|transformers|bumblebee|megatron/i.test(normalized)) {
      queries.push('site:tfu.info "' + cleaned + '"');
      queries.push('site:transformers-universe.com "' + cleaned + '"');
      queries.push('site:transformerland.com "' + cleaned + '"');
      queries.push('site:hasbro.com "' + cleaned + '"');
    }
    // Fallback less generic, preserving the product/character phrase.
    queries.push('"' + cleaned + '" collectible figure statue comic toy');
  }
  return [...new Set(queries)].slice(0, 8);
}
async function searchDuckDuckGo(query: string): Promise<SearchResult[]> {
  const html = await fetchText("https://html.duckduckgo.com/html/?q=" + encodeURIComponent(query), 8000);
  if (/anomaly-modal|bots use duckduckgo|select all squares/i.test(html)) throw new Error("Google/Bing o API web non hanno restituito risultati leggibili");
  const results: SearchResult[] = [];
  const pattern = /<a\b([^>]*class=["'][^"']*result__a[^"']*["'][^>]*)>([\s\S]*?)<\/a>/gi;
  let m: RegExpExecArray | null;
  while ((m = pattern.exec(html)) !== null && results.length < 8) {
    const href = m[1].match(/href=["']([^"']+)["']/i)?.[1];
    if (!href) continue;
    let resultUrl = decodeEntities(href);
    try { const parsed = new URL(resultUrl, "https://html.duckduckgo.com"); resultUrl = parsed.searchParams.get("uddg") ? decodeURIComponent(parsed.searchParams.get("uddg")!) : parsed.href; } catch { continue; }
    if (!/^https?:\/\//i.test(resultUrl) || /duckduckgo\.com\//i.test(resultUrl)) continue;
    const nearby = html.slice(Math.max(0, m.index - 300), Math.min(html.length, pattern.lastIndex + 1200));
    const snippet = nearby.match(/class=["'][^"']*result__snippet[^"']*["'][^>]*>([\s\S]*?)<\//i)?.[1] ?? "";
    results.push({ title: cleanText(m[2]), url: resultUrl, snippet: cleanText(snippet), source_query: query, motore: "DUCKDUCKGO" });
  }
  return results;
}
async function searchGoogle(query: string): Promise<SearchResult[]> {
  const html = await fetchText("https://www.google.com/search?q=" + encodeURIComponent(query) + "&num=8", 9000);
  if (/unusual traffic|our systems have detected/i.test(html)) throw new Error("Google ha limitato la richiesta automatica");
  const results: SearchResult[] = [];
  const anchors = html.match(/<a\b[^>]*href=["']https?:\/\/[^"'#]+["'][^>]*>[\s\S]*?<\/a>/gi) ?? [];
  for (const anchor of anchors) {
    const href = anchor.match(/href=["'](https?:\/\/[^"'#]+)["']/i)?.[1];
    if (!href) continue;
    let url: URL;
    try { url = new URL(decodeEntities(href)); } catch { continue; }
    if (/google\.com$|googleusercontent\.com$|gstatic\.com$/i.test(url.hostname)) continue;
    const title = cleanText(anchor);
    if (title.length < 4 || results.some(r => r.url === url.href)) continue;
    results.push({ title, url: url.href, snippet: "", source_query: query, motore: "GOOGLE_WEB" });
    if (results.length >= 8) break;
  }
  return results;
}
async function searchBingRss(query: string): Promise<SearchResult[]> {
  const xml = await fetchText("https://www.bing.com/search?q=" + encodeURIComponent(query) + "&format=rss&mkt=en-US&setlang=en-US", 10000);
  if (!/<item[\s>]/i.test(xml)) throw new Error("Bing RSS non ha restituito elementi leggibili");
  const results: SearchResult[] = [];
  const items = xml.match(/<item[\s>][\s\S]*?<\/item>/gi) ?? [];
  for (const item of items.slice(0, 8)) {
    const title = item.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "";
    const link = item.match(/<link[^>]*>([\s\S]*?)<\/link>/i)?.[1] ?? "";
    const desc = item.match(/<description[^>]*>([\s\S]*?)<\/description>/i)?.[1] ?? "";
    const resultUrl = cleanText(link);
    if (title && /^https?:\/\//i.test(resultUrl)) results.push({ title: cleanText(title), url: resultUrl, snippet: cleanText(desc), source_query: query, motore: "BING_RSS" });
  }
  return results;
}
async function searchBrave(query: string): Promise<SearchResult[]> {
  const apiKey = Deno.env.get("BRAVE_SEARCH_API_KEY") ?? "";
  if (!apiKey) throw new Error("BRAVE_SEARCH_API_KEY non configurata");
  const response = await fetch("https://api.search.brave.com/res/v1/web/search?q=" + encodeURIComponent(query) + "&count=8", {
    headers: { "Accept": "application/json", "X-Subscription-Token": apiKey },
    signal: AbortSignal.timeout(9000),
  });
  if (!response.ok) throw new Error("Brave Search API: HTTP " + response.status);
  const data = await response.json();
  const items = Array.isArray(data?.web?.results) ? data.web.results : [];
  return items.slice(0, 8).flatMap((item: any) => {
    const url = String(item.url ?? "");
    const title = cleanText(String(item.title ?? ""));
    if (!/^https?:\/\//i.test(url) || title.length < 3) return [];
    return [{ title, url, snippet: cleanText(String(item.description ?? "")), source_query: query, motore: "BRAVE_SEARCH_API" }];
  });
}
async function searchOne(query: string): Promise<SearchResult[]> {
  const errors: string[] = [];
  // Provider API documentata, se è stata configurata la relativa chiave segreta.
  try {
    const results = await searchBrave(query);
    if (results.length) return results;
    errors.push("Brave Search API: nessun risultato");
  } catch (e) {
    errors.push(e instanceof Error ? e.message : String(e));
  }
  // Fallback web senza dipendere da DuckDuckGo: i parser sono best-effort,
  // la diagnostica distingue chiaramente provider non configurato e risultati vuoti.
  for (const [name, search] of [["Google", searchGoogle], ["Bing RSS", searchBingRss]] as const) {
    try {
      const results = await search(query);
      if (results.length) return results;
      errors.push(name + ": nessun risultato leggibile");
    } catch (e) {
      errors.push(name + ": " + (e instanceof Error ? e.message : String(e)));
    }
  }
  throw new Error(errors.join(" | "));
}

function relevanceTokens(description: string): string[] {
  const normalized = normalizeText(description).replace(/\blungo\b/g, "long").replace(/\bdel\b/g, " ").replace(/[^a-z0-9]+/g, " ");
  const stop = new Set(["il","lo","la","i","gli","le","di","da","a","an","the","and","or","for","set","figure","fumetto","fumetti","collectible","product"]);
  return [...new Set(normalized.split(/\s+/).filter(t => t.length >= 3 && !stop.has(t)))];
}
function relevanceScore(result: SearchResult, category: string, description: string): number {
  const title = normalizeText(result.title);
  const url = normalizeText(result.url);
  const snippet = normalizeText(result.snippet);
  const combined = title + " " + url + " " + snippet;
  const tokens = relevanceTokens(description);
  if (!tokens.length) return 0;
  let titleHits = 0, contentHits = 0, score = 0;
  for (const token of tokens) {
    if (title.includes(token)) { score += 5; titleHits++; }
    else if (snippet.includes(token)) { score += 2; contentHits++; }
    else if (url.includes(token)) score += 1;
  }
  const isTransformers = /transformers|optimus prime|bumblebee|megatron/i.test(description);
  const isComic = /batman|fumett|comic|il lungo halloween|long halloween/i.test(description) || category === "FUMETTI";
  if (isTransformers && /tfu\.info|transformers-universe|transformerland|hasbro|tfwiki|transformers\.com/i.test(url)) score += 6;
  if (isComic && /dc\.com|dcuniverseinfinite|panini\.it|comics\.org|leagueofcomicgeeks|comicvine/i.test(url)) score += 6;
  if (/merriam-webster|dictionary|definition|meaning of|kmsauto|windows office activator/i.test(title + " " + url)) score -= 20;
  if (/information|definition|meaning of/i.test(title) && !/batman|comic|comic book|long halloween/i.test(title + " " + url)) score -= 20;
  // For multi-word searches, require meaningful evidence in the title or snippet,
  // not just an incidental token in the URL.
  if (tokens.length >= 2 && titleHits === 0 && contentHits < 2) score -= 8;
  const code = codeFrom(description);
  // I numeri di anno, ISBN o volume non devono diventare codici prodotto.
  if (isLego(category, description) && code &&
      new RegExp("(^|[^0-9])" + code + "([^0-9]|$)").test(combined)) score += 8;
  return score;
}
function classifyCandidate(result: SearchResult): string {
  const text = normalizeText([result.title, result.url, result.snippet].join(" "));
  if (/merriam-webster|dictionary|definition|meaning of|kmsauto|speedtest|company portal|windows office activator|download pending/i.test(text)) return "NON PERTINENTE";
  if (/comic|comics|graphic novel|panini|isbn|fumett|dc comics|marvel/i.test(text)) return "FUMETTO / VOLUME";
  if (/statue|statua|statuette|bust|busto|polystone|resin statue/i.test(text)) return "STATUA / STATUETTA";
  if (/action figure|articulated figure|posable figure|collectible figure/i.test(text)) return "ACTION FIGURE";
  if (/minifigure|minifig|bricklink|brickset|rebrickable|lego.com/i.test(text)) return "LEGO / MINIFIGURA";
  if (/transformer|optimus prime|hasbro|transformerland|tfu.info/i.test(text)) return "TRANSFORMERS / GIOCATTOLO";
  if (/model kit|gunpla|gundam|plastic model/i.test(text)) return "MODEL KIT";
  if (/maisto|diecast|die-cast|scale model/i.test(text)) return "MODELLINO / DIE-CAST";
  return "ALTRO COLLEZIONABILE";
}
function hasTopicEvidence(result: SearchResult, description: string): boolean {
  const title = normalizeText(result.title);
  const snippet = normalizeText(result.snippet);
  const url = normalizeText(result.url);
  const text = title + " " + snippet + " " + url;
  if (/merriam-webster|dictionary|definition|meaning of|kmsauto|speedtest|company portal|windows office activator|download pending/i.test(text)) return false;
  const q = normalizeText(description);
  if (/optimus\s*prime|transformers|bumblebee|megatron/i.test(q)) {
    return /optimus|transformer|bumblebee|megatron|hasbro/i.test(title + " " + snippet);
  }
  if (/batman|long halloween|lungo halloween|hush/i.test(q)) {
    // Molti cataloghi indicizzano la serie nel percorso URL, mentre il titolo
    // mostrato dal motore può essere abbreviato. Usa anche lo slug, ma richiedi
    // evidenza del franchise/opera e non accettare pagine dizionario o irrilevanti.
    const evidence = title + " " + snippet + " " + url;
    // Hush va controllato prima di Batman: la query contiene entrambe le parole,
    // ma i titoli dei cataloghi possono riportare solo il titolo dell'arco narrativo.
    if (/hush/i.test(q)) {
      const host = hostnameFromUrl(result.url);
      const trustedComicCatalog = /(^|\.)((leagueofcomicgeeks\.com)|(comics\.org)|(comicvine\.gamespot\.com)|(dc\.com)|(fandom\.com))$/i.test(host);
      const comicContext = /comic|comics|graphic|issue|volume|dc comics|batman|hush/i.test(title + " " + snippet + " " + url);
      return /hush|batman/i.test(evidence) || (trustedComicCatalog && comicContext);
    }
    if (/batman/i.test(q)) return /batman/i.test(evidence);
    return /halloween/i.test(evidence);
  }
  const tokens = relevanceTokens(description);
  return tokens.some(token => title.includes(token) || snippet.includes(token));
}
function rankRelevantResults(results: SearchResult[], category: string, description: string): SearchResult[] {
  return results.map((result, index) => ({
    result, index, score: relevanceScore(result, category, description),
    family: classifyCandidate(result)
  }))
    .filter(item => item.family !== "NON PERTINENTE" && hasTopicEvidence(item.result, description))
    .sort((a,b) => b.score - a.score || a.index - b.index)
    .map(item => Object.assign(item.result, {
      tipologia_candidata: item.family,
      pertinenza: item.score
    }));
}function enrichMetadata(results: SearchResult[], category: string, description: string): SearchResult[] {
  const code = codeFrom(description);
  return results.map((result) => {
    const item = result as SearchResult & Record<string, unknown>;
    if (isLego(category, description) && code) {
      const year = (result.snippet + " " + result.title).match(/\b(19\d{2}|20\d{2})\b/)?.[1] ?? "";
      item.produttore = "LEGO";
      item.codice_prodotto = code;
      if (year) item.anno_uscita = Number(year);
    } else {
      // Fuori dai set LEGO non inferire un codice da un numero qualsiasi nella descrizione:
      // potrebbe essere anno, numero di volume o parte di un ISBN.
      item.produttore = null;
      item.codice_prodotto = null;
    }
    return item;
  });
}
function filterForExactCode(results: SearchResult[], category: string, description: string): SearchResult[] {
  // Il filtro numerico stretto è sicuro per i codici set LEGO, non per fumetti,
  // figure e modellini dove lo stesso numero può essere un anno o un volume.
  if (!isLego(category, description)) return results;
  const code = codeFrom(description);
  if (!code) return results;
  const exactCode = new RegExp("(^|[^0-9])" + code + "(-1)?([^0-9]|$)", "i");
  return results.filter(r => exactCode.test(r.title + " " + r.url + " " + r.snippet));
}
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "Usare POST." }, 405);
  try {
    const body = await req.json();
    const description = String(body.descrizione ?? body.query ?? "").trim().slice(0, 240);
    const category = String(body.categoria ?? "").trim().toUpperCase().slice(0, 40);
    if (description.length < 2) return json({ ok: false, error: "Inserire una descrizione di almeno 2 caratteri." }, 400);
    const code = codeFrom(description);
    const configured = await loadConfiguredSources(category, description);
    const staticTargeted = sourcesFor(category, description);
    const targeted = [...new Set([...staticTargeted, ...configured.names])];
    let directResults: SearchResult[] = [];
    try { directResults.push(...await searchDcBatmanHush(description)); } catch (e) { errors.push("Catalogo DC diretto: " + (e instanceof Error ? e.message : String(e))); }
    const errors: string[] = [...configured.warnings];
    if (isLego(category, description) && code) {
      try { directResults = await searchBrickset(code); }
      catch (e) { errors.push("Brickset: " + (e instanceof Error ? e.message : String(e))); }
    }

    const baseQueries = makeQueries(category, description);
    // Le fonti già configurate nel database hanno priorità: prima le query site:
    // specialistiche, poi le query mirate di franchise/categoria, infine il web generico.
    // In precedenza le prime 5 query generiche potevano occupare il limite di 8 e
    // tagliare fuori quasi tutte le fonti del database.
    const configuredQueries = configured.queries.slice(0, 6);
    const targetedBaseQueries = baseQueries.filter(q => q.startsWith("site:"));
    const genericBaseQueries = baseQueries.filter(q => !q.startsWith("site:"));
    const queries = [...new Set([
      ...configuredQueries,
      ...targetedBaseQueries,
      ...genericBaseQueries,
    ])].slice(0, 8);
    let searchResults: SearchResult[] = [];
    const diagnosticaQuery: Array<{ query: string; risultati_grezzi: number; errore?: string }> = [];
    // Fonti specialistiche dal database TEST prima delle query generiche.
    if (!directResults.length) {
      const settled = await Promise.allSettled(queries.map(searchOne));
      for (let i = 0; i < settled.length; i++) {
        const item = settled[i];
        if (item.status === "rejected") { const errorText = item.reason instanceof Error ? item.reason.message : String(item.reason); errors.push(queries[i] + ": " + errorText); diagnosticaQuery.push({ query: queries[i], risultati_grezzi: 0, errore: errorText }); continue; }
        diagnosticaQuery.push({ query: queries[i], risultati_grezzi: item.value.length });
        searchResults.push(...item.value);
      }
    }

    const seen = new Set<string>();
    const all: SearchResult[] = [];
    for (const r of [...directResults, ...searchResults]) {
      const key = r.url.replace(/\/$/, "");
      if (!seen.has(key)) { seen.add(key); all.push(r); }
    }
    const conteggioGrezzi = all.length;
    const dopoCodice = filterForExactCode(all, category, description);
    const conteggioDopoCodice = dopoCodice.length;
    let results = rankRelevantResults(dopoCodice, category, description);
    const conteggioDopoPertinenza = results.length;
    results = enrichMetadata(results, category, description);
    if (isLego(category, description) && code) {
      // Do not show irrelevant generic results for LEGO set-code queries.
      results = results.filter(r => /brickset\.com|bricklink\.com|rebrickable\.com|lego\.com/i.test(r.url));
    }

    if (!results.length) return json({
      ok: true, procedura: "PR-12", modalita: "RICERCA_CATALOGO_E_WEB",
      descrizione: description, categoria: category || "NON_CLASSIFICATA",
      risultati: [], numero_risultati: 0, ricerca_esterna_eseguita: true, metadati_confermati: false,
      avviso: "Nessuna corrispondenza verificabile trovata per il codice esatto. Nessun risultato generico non pertinente è stato mostrato.",
      errori_fonti: errors, fonti_specializzate: targeted,
      diagnostica: { fonti_database_caricate: configured.sources.length, regole_franchise: configured.franchiseRules.length, query: diagnosticaQuery, risultati_grezzi_unici: conteggioGrezzi, dopo_filtro_codice: conteggioDopoCodice, dopo_filtro_pertinenza: conteggioDopoPertinenza },
      fonti_database: configured.sources.map(s => ({ codice_fonte: s.codice_fonte, nome_fonte: s.nome_fonte, url: s.url_principale, tipo_fonte: s.tipo_fonte, stato_affidabilita: s.stato_affidabilita, priorita: s.priorita_metadati })),
      regole_franchise_applicate: configured.franchiseRules.map(r => r.franchise),
      query_eseguite: queries,
      diagnostica: { fonti_database_caricate: configured.sources.length, regole_franchise: configured.franchiseRules.length, query: diagnosticaQuery, risultati_grezzi_unici: conteggioGrezzi, dopo_filtro_codice: conteggioDopoCodice, dopo_filtro_pertinenza: conteggioDopoPertinenza },
    });
    return json({
      ok: true, procedura: "PR-12", modalita: "RICERCA_CATALOGO_E_WEB",
      descrizione: description, categoria: category || "NON_CLASSIFICATA",
      risultati: results.slice(0, 15), numero_risultati: Math.min(results.length, 15),
      ricerca_esterna_eseguita: true, metadati_confermati: false,
      motori_utilizzati: [...new Set(results.map(r => r.motore))],
      avviso: "Risultati candidati da cataloghi/fonti pubbliche. Verificare la corrispondenza prima di compilare i metadati.",
      fonti_specializzate: targeted, errori_fonti: errors,
      fonti_database: configured.sources.map(s => ({ codice_fonte: s.codice_fonte, nome_fonte: s.nome_fonte, url: s.url_principale, tipo_fonte: s.tipo_fonte, stato_affidabilita: s.stato_affidabilita, priorita: s.priorita_metadati })),
      regole_franchise_applicate: configured.franchiseRules.map(r => r.franchise),
      query_eseguite: queries,
    });
  } catch (error) {
    return json({ ok: false, procedura: "PR-12", ricerca_esterna_eseguita: false, error: error instanceof Error ? error.message : String(error) }, 502);
  }
});