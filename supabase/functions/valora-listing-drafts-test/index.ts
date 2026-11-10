import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: cors });
const text = (value: unknown) => String(value ?? "").trim();
const unique = (values: string[]) => [...new Set(values.map(v => v.trim()).filter(Boolean))];
const safeName = (value: string) => value.replace(/^\[TEST-CBV\]\s*/i, "").trim();

function titleFor(platform: string, facts: Record<string, any>): string {
  const name = text(facts.nome_ufficiale || facts.nome_originale || facts.descrizione_oggetto);
  const parts = unique([
    name,
    text(facts.produttore),
    text(facts.codice_prodotto || facts.codice_identificativo),
    facts.anno_uscita ? String(facts.anno_uscita) : "",
  ]);
  const normalized = parts.join(" ").replace(/\s+/g, " ").trim();
  if (/bricklink/i.test(platform) && /lego/i.test(text(facts.produttore))) {
    return unique(["LEGO", name, text(facts.codice_prodotto || facts.codice_identificativo)]).join(" ");
  }
  if (/subito/i.test(platform)) return unique([name, text(facts.produttore)]).join(" ");
  if (/vinted/i.test(platform)) return name;
  if (/ebay/i.test(platform)) return normalized;
  return normalized;
}

function descriptionFor(platform: string, facts: Record<string, any>): string {
  const rows: string[] = [];
  const productName = text(facts.nome_ufficiale || facts.nome_originale || facts.descrizione_oggetto);
  if (productName) rows.push("Oggetto: " + productName);
  if (text(facts.produttore)) rows.push("Produttore: " + text(facts.produttore));
  if (facts.anno_uscita) rows.push("Anno: " + String(facts.anno_uscita));
  if (text(facts.codice_prodotto || facts.codice_identificativo)) {
    rows.push("Codice prodotto: " + text(facts.codice_prodotto || facts.codice_identificativo));
  }
  if (text(facts.categoria_prodotto || facts.codice_categoria)) {
    rows.push("Categoria catalogo: " + text(facts.categoria_prodotto || facts.codice_categoria));
  }
  if (text(facts.condizione)) rows.push("Condizione registrata: " + text(facts.condizione));
  if (text(facts.completezza)) rows.push("Completezza registrata: " + text(facts.completezza));
  if (text(facts.versione_variante)) rows.push("Variante: " + text(facts.versione_variante));
  if (text(facts.descrizione_ufficiale)) rows.push("Descrizione catalogo: " + text(facts.descrizione_ufficiale));

  const details = rows.join("\n");
  if (/vinted/i.test(platform)) {
    return [productName, details, "Descrizione generata dai dati verificati dell'oggetto. Controlla condizioni, accessori e fotografie prima della pubblicazione."].filter(Boolean).join("\n\n");
  }
  if (/ebay/i.test(platform)) {
    return ["DETTAGLI OGGETTO", details, "CONDIZIONI E COMPLETEZZA", "Verificare che la condizione e il contenuto effettivo della confezione corrispondano all'esemplare fotografato.", "SPEDIZIONE", "Aggiungere modalità e costi di spedizione prima della pubblicazione."].filter(Boolean).join("\n\n");
  }
  if (/subito/i.test(platform)) {
    return [details, "Verificare e completare le informazioni su stato, accessori, difetti e consegna prima della pubblicazione."].filter(Boolean).join("\n\n");
  }
  if (/bricklink/i.test(platform)) {
    return ["DATI ARTICOLO", details, "Verificare categoria, codice catalogo, parti/accessori inclusi e condizione prima della pubblicazione."].filter(Boolean).join("\n\n");
  }
  return [details, "Bozza preparata dai dati disponibili. Integrare eventuali dettagli mancanti e verificare le condizioni reali dell'esemplare."].filter(Boolean).join("\n\n");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Metodo non consentito." }, 405);

  try {
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Autenticazione richiesta." }, 401);

    const authClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: "Bearer " + token } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await authClient.auth.getUser(token);
    if (authError || !authData.user) return json({ error: "Sessione non valida." }, 401);
    const userId = authData.user.id;
    const service = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authorized, error: authorizedError } = await service
      .schema("collection").from("app_authorized_users")
      .select("user_id,attivo").eq("user_id", userId).eq("attivo", true).maybeSingle();
    if (authorizedError || !authorized) return json({ error: "Utente non autorizzato all'ambiente TEST." }, 403);

    const body = await req.json();
    const action = text(body?.action || "create");

    if (action === "create") {
      const saleId = Number(body?.codice_vendita_aperta);
      if (!Number.isSafeInteger(saleId) || saleId <= 0) return json({ error: "Codice vendita aperta non valido." }, 400);

      const { data: sale, error: saleError } = await service.schema("collection")
        .from("master_oggetti_in_vendita")
        .select("codice_vendita_aperta,codice_oggetto,descrizione_oggetto,prezzo_di_vendita,valuta,stato_ciclo_vendita")
        .eq("codice_vendita_aperta", saleId).maybeSingle();
      if (saleError || !sale) return json({ error: "Ciclo di vendita non trovato." }, 404);
      if (sale.stato_ciclo_vendita !== "APERTO") return json({ error: "Il ciclo di vendita non è aperto." }, 409);

      const { data: links, error: linksError } = await service.schema("collection")
        .from("oggetti_in_vendita_piattaforme")
        .select("codice_piattaforma")
        .eq("codice_vendita_aperta", saleId)
        .eq("codice_oggetto", sale.codice_oggetto);
      if (linksError) return json({ error: "Impossibile leggere le piattaforme registrate nella vendita." }, 422);
      const platformIds = [...new Set((links || []).map((row: any) => Number(row.codice_piattaforma)).filter(Number.isSafeInteger))];
      if (!platformIds.length) return json({ error: "La vendita non contiene piattaforme selezionate." }, 422);

      const [{ data: object, error: objectError }, { data: metadata }, { data: images }, { data: platforms }, { data: categoryRows }] = await Promise.all([
        service.schema("collection").from("master_oggetti")
          .select("codice_oggetto,descrizione_oggetto,condizione,completezza,destinazione,stato,produttore,anno_uscita,codice_prodotto,stato_verifica_dati")
          .eq("codice_oggetto", sale.codice_oggetto).maybeSingle(),
        service.schema("collection").from("master_metadati").select("*")
          .eq("codice_oggetto", sale.codice_oggetto).maybeSingle(),
        service.schema("collection").from("immagini_oggetto")
          .select("riferimento_immagine,tipo_immagine,fonte_immagine,url_fonte,immagine_principale,stato_verifica")
          .eq("codice_oggetto", sale.codice_oggetto),
        service.schema("collection").from("piattaforme")
          .select("codice_piattaforma,nome_piattaforma").in("codice_piattaforma", platformIds),
        service.schema("collection").from("oggetto_collezione_categoria")
          .select("codice_categoria,stato_verifica").eq("codice_oggetto", sale.codice_oggetto),
      ]);
      if (objectError || !object) return json({ error: "Dati dell'oggetto non disponibili." }, 422);
      if (object.destinazione !== "RIVENDITA" || object.stato !== "IN VENDITA") {
        return json({ error: "L'oggetto non risulta correttamente in vendita." }, 409);
      }
      const platformById = new Map((platforms || []).map((p: any) => [Number(p.codice_piattaforma), p]));
      const categoryRow = (categoryRows || []).find((row: any) => row.stato_verifica === "VERIFICATO") || categoryRows?.[0];
      const confirmedImages = (images || []).filter((image: any) => image.stato_verifica === "CONFERMATA")
        .map((image: any) => ({
          riferimento_immagine: image.riferimento_immagine,
          tipo_immagine: image.tipo_immagine,
          fonte_immagine: image.fonte_immagine,
          url_fonte: image.url_fonte,
          immagine_principale: image.immagine_principale === true,
        }));
      const facts = {
        ...object,
        ...(metadata || {}),
        codice_oggetto: object.codice_oggetto,
        descrizione_oggetto: object.descrizione_oggetto,
        condizione: object.condizione,
        completezza: object.completezza,
        produttore: metadata?.produttore || object.produttore,
        anno_uscita: metadata?.anno_uscita || object.anno_uscita,
        codice_prodotto: metadata?.codice_identificativo || object.codice_prodotto,
        codice_categoria: metadata?.codice_categoria || categoryRow?.codice_categoria || null,
      };
      const category = text(facts.categoria_prodotto || facts.codice_categoria) || null;
      const warnings: string[] = [];
      if (!metadata || !["VERIFICATO", "CONFERMATO"].includes(text(metadata.stato_verifica).toUpperCase())) {
        warnings.push("Metadati catalogo assenti o non confermati: controllare i dati prima della pubblicazione.");
      }
      warnings.push("Categoria specifica di questo marketplace da selezionare o verificare manualmente.");
      if (!confirmedImages.length) warnings.push("Nessuna fotografia confermata associata all'oggetto.");
      const drafts = [];
      for (const platformId of platformIds) {
        const platformRow: any = platformById.get(platformId);
        if (!platformRow) continue;
        const platformName = safeName(text(platformRow.nome_piattaforma)) || "Marketplace";
        const draftWarnings = [...warnings];
        if (/bricklink/i.test(platformName) && !/lego/i.test(text(facts.produttore))) {
          draftWarnings.push("Verificare che l'oggetto sia compatibile con il catalogo e le regole BrickLink.");
        }
        drafts.push({
          user_id: userId,
          codice_vendita_aperta: saleId,
          codice_oggetto: sale.codice_oggetto,
          codice_piattaforma: platformId,
          nome_piattaforma: platformName,
          titolo: titleFor(platformName, facts),
          descrizione: descriptionFor(platformName, facts),
          categoria: null,
          prezzo: sale.prezzo_di_vendita,
          valuta: sale.valuta || "EUR",
          condizione: object.condizione,
          completezza: object.completezza,
          immagini: confirmedImages,
          dati_fonte: {
            codice_oggetto: sale.codice_oggetto,
            descrizione_oggetto: object.descrizione_oggetto,
            stato_verifica_metadati: metadata?.stato_verifica || null,
            produttore: facts.produttore || null,
            anno_uscita: facts.anno_uscita || null,
            codice_prodotto: facts.codice_prodotto || null,
            categoria_catalogo: category,
          },
          avvisi: draftWarnings,
          stato: "BOZZA",
          aggiornato_il: new Date().toISOString(),
        });
      }
      if (!drafts.length) return json({ error: "Nessuna piattaforma della vendita è stata risolta nel catalogo." }, 422);

      const { data: saved, error: saveError } = await service.schema("collection")
        .from("bozze_inserzioni_valora")
        .upsert(drafts, { onConflict: "user_id,codice_vendita_aperta,codice_piattaforma" })
        .select("*");
      if (saveError) return json({ error: "Bozze non salvate: " + saveError.message }, 422);
      return json({ ambiente: "TEST", stato: "BOZZE_CREATE", codice_vendita_aperta: saleId, bozze: saved || [] });
    }

    if (action === "update") {
      const id = text(body?.id);
      const title = text(body?.titolo);
      const description = text(body?.descrizione);
      const price = Number(body?.prezzo);
      if (!id || !title || !description || !Number.isFinite(price) || price <= 0) {
        return json({ error: "ID, titolo, descrizione e prezzo valido sono obbligatori." }, 400);
      }
      const patch: Record<string, unknown> = {
        titolo: title,
        descrizione: description,
        categoria: text(body?.categoria) || null,
        prezzo: price,
        stato: "REVISIONATA",
        aggiornato_il: new Date().toISOString(),
      };
      const { data: updated, error: updateError } = await service.schema("collection")
        .from("bozze_inserzioni_valora").update(patch)
        .eq("id", id).eq("user_id", userId).select("*").maybeSingle();
      if (updateError || !updated) return json({ error: "Bozza non aggiornata o non appartenente all'utente." }, 422);
      return json({ ambiente: "TEST", stato: "BOZZA_AGGIORNATA", bozza: updated });
    }

    if (action === "list") {
      const saleId = Number(body?.codice_vendita_aperta);
      let query = service.schema("collection").from("bozze_inserzioni_valora")
        .select("*").eq("user_id", userId).order("codice_piattaforma");
      if (Number.isSafeInteger(saleId) && saleId > 0) query = query.eq("codice_vendita_aperta", saleId);
      const { data: drafts, error: listError } = await query;
      if (listError) return json({ error: "Impossibile caricare le bozze." }, 422);
      return json({ ambiente: "TEST", bozze: drafts || [] });
    }

    return json({ error: "Azione non riconosciuta." }, 400);
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error) }, 400);
  }
});
