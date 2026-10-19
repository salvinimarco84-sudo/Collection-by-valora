import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
type SearchResult = { title: string; url: string; snippet: string; source_query: string; motore: string; image_url?: string; lingua?: string; editore?: string; isbn?: string };
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
  query = canonicalSearchText(query);
  // Le linee specifiche hanno precedenza sulle categorie generiche: Saint Seiya,
  // per esempio, è una action figure ma richiede prima i cataloghi Myth Cloth.
  if (/saint seiya|myth cloth|pegasus|cavalieri dello zodiaco/i.test(query)) return [
    "site:tamashiiweb.com/item_brand/saintclothmyth",
    "site:tamashiiweb.com Saint Cloth Myth Pegasus Seiya",
    "site:myfigurecollection.net Saint Seiya Myth Cloth",
    "site:bandai.com Saint Cloth Myth",
    "site:mandarake.co.jp Saint Cloth Myth",
    "site:amiami.com Saint Cloth Myth",
    "site:anime-export.com Saint Cloth Myth"
  ];
  if (/transformers|optimus prime|bumblebee|megatron|hasbro/i.test(query)) return [
    "site:hasbro.com",
    "site:hasbropulse.com",
    "site:transformers.com",
    "site:tfwiki.net",
    "site:tfu.info",
    "site:transformerland.com"
  ];
  if (/fumett|comic|manga|panini|salda|bonelli|batman|hush|spider-man|marvel/i.test(query) || category === "FUMETTI") return [
    "site:panini.it",
    "site:saldapress.com",
    "site:sergiobonelli.it",
    "site:comics.org",
    "site:leagueofcomicgeeks.com",
    "site:dc.com",
    "site:marvel.com",
    "site:ibs.it",
    "site:giuntialpunto.it"
  ];
  if (/maisto|die.?cast|motorbike|modellino|scala 1[:/]|hot wheels|matchbox/i.test(query) || category === "DIECAST") return [
    "site:maisto.com",
    "site:diecast.org",
    "site:thetoysdb.org",
    "site:ebay.it"
  ];
  if (/gundam|gunpla|dragon ball|naruto|one piece|action figure|statua|myfigurecollection|bandai/i.test(query) || category === "ACTION_FIGURE") return [
    "site:tamashiiweb.com",
    "site:bandai.com",
    "site:myfigurecollection.net",
    "site:theafdb.com",
    "site:collectibles.wiki"
  ];
  if (/toy|giocattol|vintage|kinder|sorpresine|robot|gioco da collezione/i.test(query) || category === "GIOCATTOLO" || category === "COLLEZIONABILE") return [
    "site:thetoysdb.org",
    "site:collectibles.wiki",
    "site:theafdb.com",
    "site:ebay.it"
  ];
  if (category === "DVD_BLURAY") return [
    "site:blu-ray.com",
    "site:themoviedb.org",
    "site:imdb.com",
    "site:worldcat.org",
    "site:ibs.it",
    "site:amazon.it"
  ];
  if (category === "CARTE_COLLEZIONABILI") return [
    "site:tcgplayer.com",
    "site:cardmarket.com",
    "site:pricecharting.com",
    "site:collectors.com",
    "site:ebay.it"
  ];
  if (category === "MYTH_CLOTH") return [
    "site:tamashiiweb.com/item_brand/saintclothmyth",
    "site:tamashiiweb.com",
    "site:myfigurecollection.net",
    "site:bandai.com",
    "site:mandarake.co.jp",
    "site:amiami.com"
  ];
  if (isLego(category, query)) return ["LEGO.com", "BrickLink", "Rebrickable"];
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
async function searchKnownCatalogs(category: string, description: string): Promise<SearchResult[]> {
  const canonical = canonicalSearchText(description);
  const results: SearchResult[] = [];
  const catalogDiagnostics: string[] = [];
  const addPage = async (url: string, hostLabel: string, pattern: RegExp) => {
    try {
      const html = await fetchText(url, 6500);
      const title = cleanText(
        html.match(/<meta\b[^>]*property=["']og:title["'][^>]*content=["']([^"']+)["']/i)?.[1] ??
        html.match(/<h1\b[^>]*>([^<]*)<\/h1>/i)?.[1] ??
        html.match(/<title\b[^>]*>([^<]*)<\/title>/i)?.[1] ?? ""
      );
      const image = html.match(/<meta\b[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i)?.[1];
      const text = cleanText(title + " " + html.slice(0, 18000));
      if (!title || title.length < 4) { catalogDiagnostics.push(hostLabel + ": pagina raggiunta ma titolo prodotto assente; candidato scartato"); return; }
      if (!pattern.test(text)) { catalogDiagnostics.push(hostLabel + ": pagina raggiunta, codice non trovato nel contenuto; candidato scartato"); return; }
      if (/catalog result for|page not found|access denied|error|not found/i.test(title)) { catalogDiagnostics.push(hostLabel + ": titolo generico o errore; candidato scartato"); return; }
      results.push({ title, url, snippet: "Titolo letto dalla pagina del catalogo " + hostLabel + "; verificare codice, edizione e variante prima di applicare i metadati.", source_query: canonical, motore: "CATALOGO_DIRETTO", ...(image ? { image_url: decodeEntities(image) } : {}) });
    } catch (e) { catalogDiagnostics.push(hostLabel + ": errore recupero: " + (e instanceof Error ? e.message : String(e)).slice(0, 240)); }
  };
  if (category === "LEGO" || /\blego\b/i.test(canonical)) {
    const match = canonical.match(/\b(\d{4,8})\b/);
    if (match) {
      const code = match[1];
      await Promise.all([
        addPage("https://www.lego.com/en-us/service/buildinginstructions/" + code, "LEGO Instructions", new RegExp("(^|[^0-9])" + code + "([^0-9]|$)")),
        addPage("https://www.bricklink.com/v2/catalog/catalogitem.page?S=" + code + "-1", "BrickLink", new RegExp("(^|[^0-9])" + code + "([^0-9]|$)")),
        addPage("https://rebrickable.com/sets/" + code + "-1/", "Rebrickable", new RegExp("(^|[^0-9])" + code + "([^0-9]|$)")),
      ]);
    }
  }
  if (/saint seiya|myth cloth|pegasus|cavalieri dello zodiaco/i.test(canonical)) {
    await addPage("https://tamashiiweb.com/item_brand/saintclothmyth_series/?character=saint_seiya&ck1=0&ck2=0&ck3=0&ck4=0&ck5=0&number=30&order=high", "Tamashii Web", /saint seiya|saint cloth myth|pegasus/i);
  }
  if (catalogDiagnostics.length) console.warn("PR12_CATALOG_DIAGNOSTICS", JSON.stringify(catalogDiagnostics));
  return results;
}

async function searchItalianBatmanHush(description: string): Promise<SearchResult[]> {
  if (!/batman/i.test(description) || !/hush/i.test(description)) return [];
  // Schede di edizioni italiane identificabili da editore/ISBN, non pagine USA generiche.
  const editions = [
    { url: "https://giuntialpunto.it/products/batman-hush-loeb-jeph-9791221903089", title: "Batman: Hush · DC Pocket Collection", isbn: "9791221903089" },
    { url: "https://giuntialpunto.it/products/hush-batman-loeb-jeph-9788828774686", title: "Hush. Batman · DC Absolute", isbn: "9788828774686" },
    { url: "https://www.ibs.it/batman-hush-libro-jeph-loeb/e/9791221903089", title: "Batman: Hush · DC Pocket Collection", isbn: "9791221903089" },
    { url: "https://www.ibs.it/hush-batman-libro-jeph-loeb/e/9788828774686", title: "Hush. Batman · DC Absolute", isbn: "9788828774686" }
  ];
  const results: SearchResult[] = [];
  for (const edition of editions) {
    try {
      const html = await fetchText(edition.url, 6500);
      const titleRaw = html.match(/<meta\b[^>]*property=["']og:title["'][^>]*content=["']([^"']+)["']/i)?.[1]
        ?? html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? edition.title;
      const image = html.match(/<meta\b[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i)?.[1]
        ?? html.match(/<meta\b[^>]*content=["']([^"']+)["'][^>]*property=["']og:image["']/i)?.[1]
        ?? html.match(/<meta\b[^>]*name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i)?.[1];
      const isbn = edition.isbn;
      if (!/batman|hush/i.test(titleRaw + " " + html.slice(0, 12000))) continue;
      results.push({
        // Titolo editoriale stabile, più utile del titolo SEO del rivenditore.
        title: edition.title,
        url: edition.url,
        snippet: "Edizione italiana Panini Comics. ISBN " + isbn + ". Lingua italiana; verificare formato e copertina nella scheda.",
        source_query: description,
        motore: "CATALOGO_EDIZIONE_ITALIANA",
        ...(image ? { image_url: decodeEntities(image.replace(/&amp;/gi, "&")) } : {}),
        lingua: "Italiano",
        editore: "Panini Comics",
        isbn,
        anno_uscita: isbn === "9791221903089" ? 2024 : 2024
      });
    } catch { /* una scheda può bloccare richieste automatizzate; provare le altre */ }
  }
  // Fallback copertina e data bibliografica tramite Google Books, cercando l'ISBN esatto.
  // Evita di dipendere solo dai meta tag dei rivenditori, che possono bloccare il crawler.
  for (const edition of editions) {
    const existing = results.find(r => r.isbn === edition.isbn);
    if (existing?.image_url) continue;
    try {
      const response = await fetch(
        "https://www.googleapis.com/books/v1/volumes?q=isbn:" + encodeURIComponent(edition.isbn),
        { headers: { "Accept": "application/json" }, signal: AbortSignal.timeout(6500) }
      );
      if (!response.ok) continue;
      const data = await response.json();
      const volume = Array.isArray(data?.items) ? data.items[0]?.volumeInfo : null;
      if (!volume) continue;
      const links = volume.imageLinks ?? {};
      const imageUrl = String(links.thumbnail ?? links.smallThumbnail ?? "").replace(/^http:/i, "https:");
      const publishedDate = String(volume.publishedDate ?? "");
      const year = publishedDate.match(/\\b(19\\d{2}|20\\d{2})\\b/)?.[1];
      const title = String(volume.title ?? edition.title);
      if (existing) {
        if (imageUrl) existing.image_url = imageUrl;
        if (year) (existing as SearchResult & Record<string, unknown>).anno_uscita = Number(year);
        if (volume.publisher) existing.editore = String(volume.publisher);
      } else {
        results.push({
          title: title + " · Google Books",
          url: edition.url,
          snippet: "Edizione italiana identificata tramite ISBN " + edition.isbn + ".",
          source_query: description,
          motore: "GOOGLE_BOOKS_ISBN",
          ...(imageUrl ? { image_url: imageUrl } : {}),
          lingua: "Italiano",
          editore: String(volume.publisher ?? "Panini Comics"),
          isbn: edition.isbn,
          ...(year ? { anno_uscita: Number(year) } : {}),
        });
      }
    } catch { /* se Google Books non risponde, conserva i risultati già trovati */ }
  }
  return results;
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


type ConfiguredSource = { codice_fonte?: string; nome_fonte?: string; url_principale?: string; tipo_fonte?: string; ambito_ricerca?: string; produttore?: string; linea_prodotto?: string; famiglia_prodotto?: string; priorita_metadati?: number; stato_affidabilita?: string; riutilizzabile?: boolean };
type RegistrySource = { id?: string; nome?: string; url_base?: string; ambito?: string; categoria?: string; marchio_editore?: string; franchise?: string; mercato?: string; tipo_fonte?: string; priorita?: number; attendibilita_dichiarata?: string; stato_verifica?: string; attiva?: boolean; origine_configurazione?: string; proprietario_utente?: string; condivisa?: boolean };
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
function authenticatedUserId(req: Request): string | undefined {
  // verify_jwt=true means Supabase's gateway has already validated this bearer token.
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const parts = token.split(".");
  if (parts.length !== 3) return undefined;
  try {
    const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof payload.sub === "string" ? payload.sub : undefined;
  } catch { return undefined; }
}
function normalizeText(value: unknown): string {
  return String(value ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}
// Corregge varianti comuni digitate nelle descrizioni, senza modificare il testo originale salvato.
function canonicalSearchText(value: string): string {
  return value
    .replace(/\bsaint\s+seya\b/gi, "Saint Seiya")
    .replace(/\bsaint\s+seiya\b/gi, "Saint Seiya")
    .replace(/\bmith\s+cloth\b/gi, "Myth Cloth")
    .replace(/\bmythcloth\b/gi, "Myth Cloth")
    .replace(/\bcavalieri\s+dello\s+zodiaco\b/gi, "Saint Seiya");
}
function hostnameFromUrl(value: string): string {
  try { return new URL(value).hostname.replace(/^www\./i, ""); } catch { return ""; }
}
async function loadConfiguredSources(category: string, description: string, userId?: string): Promise<{ sources: ConfiguredSource[]; franchiseRules: FranchiseRule[]; queries: string[]; names: string[]; warnings: string[] }> {
  const warnings: string[] = [];
  let archive: ConfiguredSource[] = [];
  let rules: FranchiseRule[] = [];
  try { archive = await readConfigTable<ConfiguredSource>("archivio_fonti_ricerca", "codice_fonte,nome_fonte,url_principale,tipo_fonte,ambito_ricerca,produttore,linea_prodotto,famiglia_prodotto,priorita_metadati,stato_affidabilita,riutilizzabile"); }
  catch (e) { warnings.push("Archivio fonti precedente: " + (e instanceof Error ? e.message : String(e))); }
  // Il registro espandibile è la fonte di configurazione per nicchie nuove.
  // Le fonti personali vengono lette ma non promosse automaticamente a "verificate".
  try {
    const registry = await readConfigTable<RegistrySource>("registro_fonti", "id,nome,url_base,ambito,categoria,marchio_editore,franchise,mercato,tipo_fonte,priorita,attendibilita_dichiarata,stato_verifica,attiva,origine_configurazione,proprietario_utente,condivisa");
    const normalizedCategory = normalizeText(category);
    const normalizedDescription = normalizeText(description);
    const relevant = registry.filter(s => (s.origine_configurazione === "sistema" || s.condivisa === true || (!!userId && s.proprietario_utente === userId)) && s.attiva !== false && s.url_base && hostnameFromUrl(s.url_base) &&
      !/brickset/i.test([s.nome,s.url_base].join(" ")) &&
      (s.mercato === "globale" || s.mercato === "Italia" || normalizedDescription.includes(normalizeText(s.mercato ?? "__none__")) || normalizedCategory.includes(normalizeText(s.categoria ?? "__none__")) ||
       normalizeText(s.categoria ?? "").includes("universale") || normalizedDescription.includes(normalizeText(s.categoria ?? "__none__"))));
    const mapped: ConfiguredSource[] = relevant.map(s => ({
      codice_fonte: "REGISTRY:" + String(s.id ?? s.nome ?? ""),
      nome_fonte: s.nome,
      url_principale: s.url_base,
      tipo_fonte: s.tipo_fonte,
      ambito_ricerca: [s.ambito,s.mercato,s.stato_verifica].filter(Boolean).join(" · "),
      produttore: s.marchio_editore,
      linea_prodotto: s.franchise,
      famiglia_prodotto: s.categoria,
      priorita_metadati: s.priorita ?? 50,
      stato_affidabilita: s.stato_verifica === "verificata" ? s.attendibilita_dichiarata : "da_verificare",
      riutilizzabile: true,
    }));
    archive = [...archive, ...mapped];
  } catch (e) { warnings.push("Registro fonti estendibile: " + (e instanceof Error ? e.message : String(e))); }
  try { rules = await readConfigTable<FranchiseRule>("regole_ricerca_franchise", "franchise,alias_ricerca,codice_fonte_preferita,priorita,attiva"); }
  catch (e) { warnings.push("Regole franchise: " + (e instanceof Error ? e.message : String(e))); }
  const text = normalizeText(description + " " + category);
  const activeRules = rules.filter(r => r.attiva !== false && (r.alias_ricerca ?? []).some(alias => {
    const a = normalizeText(alias).trim(); return a.length >= 3 && text.includes(a);
  })).sort((a,b) => (a.priorita ?? 99) - (b.priorita ?? 99));
  const preferredCodes = new Set(activeRules.map(r => normalizeText(r.codice_fonte_preferita)).filter(Boolean));
  const categoryHints: Record<string,string[]> = {
    LEGO: ["lego", "bricklink", "rebrickable"],
    FUMETTI: ["fumett", "comic", "panini", "bonelli", "salda", "manga", "graphic novel", "dc", "marvel", "batman", "spider-man"],
    ACTION_FIGURE: ["figure", "action figure", "myth cloth", "saint seiya", "bandai", "tamashii", "toy", "giocattol", "transformer", "robot", "gundam", "dragon ball", "hokuto", "naruto", "one piece", "star wars"],
    DIECAST: ["diecast", "maisto", "modellino", "motorbike", "moto", "auto", "hot wheels", "matchbox", "robotvintage"],
    WATCHES: ["orologi", "orologio", "watch", "swatch", "rolex", "omega", "seiko", "casio", "tissot", "longines", "tag heuer", "cartier"],
    MUSIC: ["vinile", "vinyl", "record", "disco", "music", "discogs", "lp"],
    NUMISMATICS: ["moneta", "numismatic", "coin", "banknote", "banconota", "francobollo", "stamp"],
    TRADING_CARDS: ["trading card", "pokemon", "magic the gathering", "tcg", "sports card", "cardmarket", "tcgplayer"],
    GIOCATTOLO: ["toy", "giocattol", "transformer", "robot", "figure", "kinder", "vintage", "sorpresine", "astrocollection", "collectingkinder", "toyvault"],
    COLLEZIONABILE: ["collectible", "collectibles", "kinder", "sorpresine", "toy", "giocattol", "saint seiya", "myth cloth", "gundam", "gunpla", "diecast", "maisto", "fumett", "comic", "manga", "robot", "star wars", "transformer", "orologi", "orologio", "watch", "swatch", "rolex", "vinile", "vinyl", "numismatic", "coin", "francobollo", "trading card"]
  };
  const hints = categoryHints[category] ?? [];
  const matching = archive.filter(s => s.riutilizzabile !== false && s.url_principale && hostnameFromUrl(s.url_principale) && !/brickset/i.test([s.codice_fonte,s.nome_fonte,s.url_principale].join(" "))).filter(s => {
    // Evita fonti di categorie estranee.
    const host = hostnameFromUrl(s.url_principale ?? "");
    if (category === "LEGO" && !hasCrossCategoryTheme(description) && !/lego\.com|bricklink\.com|rebrickable\.com/i.test(host)) return false;
    if (/saint seiya|myth cloth|pegasus|cavalieri dello zodiaco/i.test(description) &&
        !/tamashiiweb\.com|bandai\.com|myfigurecollection\.net|mandarake\.co\.jp|amiami\.com|anime-export\.com/i.test(host)) return false;
    const haystack = normalizeText([s.codice_fonte,s.nome_fonte,s.produttore,s.linea_prodotto,s.famiglia_prodotto].join(" "));
    const franchiseMatch = preferredCodes.has(normalizeText(s.codice_fonte)) ||
      activeRules.some(r => normalizeText(s.famiglia_prodotto).includes(normalizeText(r.franchise)) || normalizeText(s.linea_prodotto).includes(normalizeText(r.franchise)));
    // La categoria generica non deve caricare fonti casuali: abbina la descrizione
    // a produttore, linea, famiglia, nome o codice della fonte.
    const categoryMatch = category !== "COLLEZIONABILE" && hints.some(h => haystack.includes(normalizeText(h)));
    const descriptionTokens = normalizeText(description).split(/[^a-z0-9]+/).filter(t => t.length >= 4 && !/^\\d+$/.test(t));
    const descriptionMatch = descriptionTokens.some(token => haystack.includes(token));
    const productMatch = /transformer|optimus prime|bumblebee|megatron/i.test(description) && /transformer|hasbro|optimus|toy/i.test(haystack);
    const makerMatch = /lego/i.test(description) && /lego|bricklink|rebrickable/i.test(haystack);
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

function thematicFranchiseQueries(description: string): string[] {
  const q = normalizeText(canonicalSearchText(description));
  const out: string[] = [];
  // Il franchise è un asse di ricerca indipendente dalla categoria merceologica.
  // Esempio: Star Wars può essere LEGO, prop, poster, soundtrack, statua o abbigliamento.
  const themes: Array<{ re: RegExp; queries: string[] }> = [
    { re: /star wars|guerre stellari/i, queries: [
      'site:starwars.com "' + description.replace(/["']/g, " ").trim() + '"',
      'site:starwars.com collectibles Star Wars',
      'site:rebelscum.com Star Wars',
      'site:theforce.net Star Wars collectibles',
      '"'+ description.replace(/["']/g, " ").trim() + '" "Star Wars" collectible'
    ]},
    { re: /marvel|spider.?man|x.?men|avengers|iron man|captain america|thor|deadpool/i, queries: [
      'site:marvel.com "' + description.replace(/["']/g, " ").trim() + '"',
      'site:marvel.com characters collectibles',
      '"' + description.replace(/["']/g, " ").trim() + '" Marvel collectible'
    ]},
    { re: /dc comics|batman|superman|wonder woman|justice league|joker/i, queries: [
      'site:dc.com "' + description.replace(/["']/g, " ").trim() + '"',
      'site:dc.com collectibles Batman Superman',
      '"' + description.replace(/["']/g, " ").trim() + '" DC collectibles'
    ]},
    { re: /transformers|optimus prime|bumblebee|megatron/i, queries: [
      'site:transformers.com "' + description.replace(/["']/g, " ").trim() + '"',
      'site:tfwiki.net "' + description.replace(/["']/g, " ").trim() + '"',
      'site:tfu.info "' + description.replace(/["']/g, " ").trim() + '"'
    ]},
    { re: /harry potter|wizarding world/i, queries: [
      'site:harrypotter.com "' + description.replace(/["']/g, " ").trim() + '"',
      '"' + description.replace(/["']/g, " ").trim() + '" Harry Potter collectible'
    ]},
    { re: /pokemon|pokémon/i, queries: [
      'site:pokemon.com "' + description.replace(/["']/g, " ").trim() + '"',
      'site:tcg.pokemon.com "' + description.replace(/["']/g, " ").trim() + '"',
      '"' + description.replace(/["']/g, " ").trim() + '" Pokémon collectible'
    ]},
    { re: /lord of the rings|the hobbit|signore degli anelli/i, queries: [
      'site:lotr.com "' + description.replace(/["']/g, " ").trim() + '"',
      '"' + description.replace(/["']/g, " ").trim() + '" Lord of the Rings collectible'
    ]},
    { re: /disney|mickey mouse|mickey|pixar/i, queries: [
      'site:thewaltdisneycompany.com "' + description.replace(/["']/g, " ").trim() + '"',
      '"' + description.replace(/["']/g, " ").trim() + '" Disney collectible'
    ]},
  ];
  for (const theme of themes) if (theme.re.test(q)) out.push(...theme.queries);
  return [...new Set(out)];
}
function hasCrossCategoryTheme(description: string): boolean {
  return thematicFranchiseQueries(description).length > 0;
}

function makeQueries(category: string, description: string): string[] {
  const code = codeFrom(description);
  const queries: string[] = [];
  const canonical = canonicalSearchText(description);
  const cleaned = canonical.replace(/["']/g, " ").replace(/\\s+/g, " ").trim();
  const normalized = normalizeText(cleaned);
  if (code && isLego(category, description)) {
    queries.push('site:lego.com "' + cleaned + '"');
    queries.push('site:bricklink.com/v2/catalog/catalogitem.page "' + code + '-1"');
    queries.push('site:rebrickable.com/sets "' + code + '"');
    queries.push('site:rebrickable.com/mocs "' + cleaned + '"');
  } else {
    // Query dedicate alla linea/produttore, non solo alla frase italiana originale.
    if (/saint seiya|myth cloth|pegasus|cavalieri dello zodiaco/i.test(normalized)) {
      queries.push('site:tamashiiweb.com/item_brand/saintclothmyth "' + cleaned + '"');
      queries.push('site:tamashiiweb.com "Saint Cloth Myth" Pegasus Seiya');
      queries.push('site:myfigurecollection.net "Saint Seiya" "Myth Cloth"');
      queries.push('site:bandai.com "Saint Cloth Myth"');
      queries.push('site:mandarake.co.jp "Saint Cloth Myth" Pegasus Seiya');
      queries.push('"Saint Cloth Myth Pegasus Seiya" Bandai');
    }
    if (/transformers|optimus prime|bumblebee|megatron/i.test(normalized)) {
      queries.push('site:hasbro.com "' + cleaned + '"');
      queries.push('site:hasbropulse.com "' + cleaned + '"');
      queries.push('site:tfu.info "' + cleaned + '"');
      queries.push('site:transformerland.com "' + cleaned + '"');
      queries.push('site:tfwiki.net "' + cleaned + '"');
    }
    if (/batman.*(anno\\s*100|year\\s*100)|(anno\\s*100|year\\s*100).*batman/i.test(normalized)) {
      queries.push('site:panini.it Batman "Anno 100"');
      queries.push('site:comics.org Batman "Year 100"');
      queries.push('site:leagueofcomicgeeks.com Batman "Year 100"');
      queries.push('site:dc.com/graphic-novels Batman "Year 100"');
      queries.push('"Batman: Year 100" Paul Pope');
      queries.push('"Batman Anno 100" fumetto edizione italiana');
    }
    if (/fumett|comic|manga|batman|hush|panini|saldapress|bonelli|spider-man|marvel/i.test(normalized) || category === "FUMETTI") {
      queries.push('site:panini.it "' + cleaned + '"');
      queries.push('site:saldapress.com "' + cleaned + '"');
      queries.push('site:sergiobonelli.it "' + cleaned + '"');
      queries.push('site:comics.org "' + cleaned + '"');
      queries.push('site:leagueofcomicgeeks.com "' + cleaned + '"');
      queries.push('site:ibs.it "' + cleaned + '" ISBN');
      queries.push('site:giuntialpunto.it "' + cleaned + '"');
      queries.push('site:dc.com "' + cleaned + '"');
      queries.push('site:marvel.com "' + cleaned + '"');
    }
    if (/maisto|die.?cast|motorbike|modellino|hot wheels|matchbox/i.test(normalized) || category === "DIECAST") {
      queries.push('site:maisto.com "' + cleaned + '"');
      queries.push('site:diecast.org "' + cleaned + '"');
      queries.push('site:thetoysdb.org "' + cleaned + '"');
      queries.push('site:ebay.it "' + cleaned + '" modellino');
    }
    if (/gundam|gunpla|dragon ball|naruto|one piece|action figure|statua|bandai/i.test(normalized) || category === "ACTION_FIGURE") {
      queries.push('site:tamashiiweb.com "' + cleaned + '"');
      queries.push('site:bandai.com "' + cleaned + '"');
      queries.push('site:myfigurecollection.net "' + cleaned + '"');
      queries.push('site:theafdb.com "' + cleaned + '"');
      queries.push('site:collectibles.wiki "' + cleaned + '"');
    }
    if (/toy|giocattol|vintage|kinder|sorpresine|robot/i.test(normalized) || category === "GIOCATTOLO" || category === "COLLEZIONABILE") {
      queries.push('site:thetoysdb.org "' + cleaned + '"');
      queries.push('site:collectibles.wiki "' + cleaned + '"');
      queries.push('site:theafdb.com "' + cleaned + '"');
    }
    const targeted = sourcesFor(category, description).filter(s => s.startsWith("site:"));
    for (const site of targeted) queries.push(site + ' "' + cleaned + '"');
    queries.push('"' + cleaned + '"');
    queries.push(cleaned + ' collectible product manufacturer');
    queries.push(cleaned + ' catalog database');
  }
  return [...new Set(queries)].slice(0, 12);
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
  // Fallback multipli: DuckDuckGo era già implementato ma non veniva mai chiamato.
  // Provarlo insieme a Google e Bing evita che il motore dipenda da parser che qui falliscono.
  for (const [name, search] of [["DuckDuckGo", searchDuckDuckGo], ["Google", searchGoogle], ["Bing RSS", searchBingRss]] as const) {
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
  if (isLego(category, description)) {
    // Ordine richiesto: sito ufficiale, BrickLink, Rebrickable.
    if (/lego\.com/i.test(url)) score += 12;
    else if (/bricklink\.com/i.test(url)) score += 8;
    else if (/rebrickable\.com/i.test(url)) score += 4;
  }
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
  const evidence = title + " " + snippet + " " + url;
  if (/dictionary|definition|speedtest|fast\.com|internet speed|company portal|download pending/i.test(evidence)) return false;
  const q = normalizeText(canonicalSearchText(description));
  if (/gundam|gunpla/i.test(q)) return /gundam|gunpla|bandai hobby/i.test(evidence);
  if (/transformers|optimus prime|bumblebee|megatron|hasbro/i.test(q)) return /transformer|optimus|bumblebee|megatron|hasbro/i.test(evidence);
  if (/lego|minifig|brickheadz|technic|duplo/i.test(q)) return /lego|bricklink|rebrickable|minifig/i.test(evidence);
  if (/saint seiya|myth cloth|pegasus|cavalieri dello zodiaco/i.test(q)) return /saint seiya|saint cloth myth|pegasus seiya|cavalieri dello zodiaco/i.test(evidence);
  if (/walking dead/i.test(q)) return /walking dead|image comics|skybound/i.test(evidence);
  if (/fumett|comic|manga|panini|saldapress|bonelli|batman|marvel|dc comics/i.test(q)) {
    return /comic|fumett|manga|panini|saldapress|bonelli|batman|marvel|dc|walking dead|image comics/i.test(evidence);
  }
  const tokens = q.split(/[^a-z0-9]+/).filter(t => t.length >= 4 && !/^(test|cbv|oggetto|serie|completa|edizione|film|studio|master|grade|version|dello|della|the|from|with|and|for|edition|product|collectible|catalog|database)$/.test(t) && !/^\d+$/.test(t));
  return tokens.some(t => title.includes(t) || snippet.includes(t));
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
    const configured = await loadConfiguredSources(category, description, authenticatedUserId(req));
    const staticTargeted = sourcesFor(category, description);
    const targeted = [...new Set([...staticTargeted, ...configured.names])];
    let directResults: SearchResult[] = [];
    const errors: string[] = [...configured.warnings];
    // Query mirate alla categoria e al franchise.
    const cleanDescription = description.replace(/["']/g, " ").replace(/\s+/g, " ").trim();
    // Le fonti configurate dagli utenti vengono interrogate prima delle query generiche.
    // Limite per lotto per evitare costi/tempi incontrollati; le priorità arrivano dal registro.
    const queries = [...new Set([...configured.queries, ...thematicFranchiseQueries(cleanDescription), ...makeQueries(category, cleanDescription)])].slice(0, 20);
    let searchResults: SearchResult[] = [];
    const diagnosticaQuery: Array<{ query: string; risultati_grezzi: number; errore?: string }> = [];
    // Fonti specialistiche dal database TEST prima delle query generiche.
    {
      // Il crawler DC è una fonte aggiuntiva, non deve bloccare i mercati locali.
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
    // Nessun filtro per dominio: i candidati possono provenire da qualsiasi sito.
    // I controlli sul codice esatto e sulla pertinenza restano attivi.

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