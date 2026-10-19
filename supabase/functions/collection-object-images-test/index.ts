import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BUCKET = "pr01-foto-temporanee";
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ ok: false, error: "Metodo non consentito." }, 405);

  try {
    const auth = req.headers.get("Authorization") || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (!token) return reply({ ok: false, error: "Autenticazione richiesta." }, 401);

    const authClient = createClient(URL, ANON, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userData, error: userError } = await authClient.auth.getUser(token);
    if (userError || !userData.user) return reply({ ok: false, error: "Sessione non valida." }, 401);
    const user = userData.user;
    const admin = createClient(URL, SERVICE, {
      auth: { persistSession: false, autoRefreshToken: false },
      db: { schema: "collection" },
    });

    const { data: allowed, error: allowError } = await admin.from("app_authorized_users")
      .select("user_id").eq("user_id", user.id).eq("attivo", true).maybeSingle();
    if (allowError) throw allowError;
    if (!allowed) return reply({ ok: false, error: "Utente non autorizzato all’ambiente TEST." }, 403);

    const body = await req.json();
    const action = String(body.action || "");
    const objectId = Number(body.codice_oggetto);
    if (!Number.isSafeInteger(objectId) || objectId < 1) {
      return reply({ ok: false, error: "Codice oggetto non valido." }, 400);
    }

    const { data: objectRow, error: objectError } = await admin.from("master_oggetti")
      .select("codice_oggetto").eq("codice_oggetto", objectId).maybeSingle();
    if (objectError) throw objectError;
    if (!objectRow) return reply({ ok: false, error: "Oggetto non trovato nel database TEST." }, 404);

    if (action === "register") {
      const path = String(body.path || "");
      const fileName = String(body.file_name || "").trim();
      const acquisition = String(body.modalita_acquisizione || "");
      const procedure = String(body.procedura_origine || "");
      const expectedPrefix = `${user.id}/${objectId}/`;
      if (!path.startsWith(expectedPrefix) || path.split("/").length !== 3 ||
          !/^[0-9a-f-]+\/[0-9]+\/[A-Za-z0-9._-]+$/i.test(path)) {
        return reply({ ok: false, error: "Percorso immagine non valido per questo utente e oggetto." }, 400);
      }
      if (!fileName || fileName.length > 255) return reply({ ok: false, error: "Nome file non valido." }, 400);
      if (!["FOTOCAMERA", "CARICAMENTO_FILE"].includes(acquisition)) {
        return reply({ ok: false, error: "Modalità di acquisizione non valida." }, 400);
      }
      if (!["PR-01", "PR-02"].includes(procedure)) {
        return reply({ ok: false, error: "Procedura di origine non valida." }, 400);
      }

      const folder = `${user.id}/${objectId}`;
      const { data: files, error: listError } = await createClient(URL, SERVICE, {
        auth: { persistSession: false, autoRefreshToken: false },
      }).storage.from(BUCKET).list(folder, { search: path.split("/").pop(), limit: 100 });
      if (listError) throw listError;
      if (!(files || []).some((file: { name: string }) => file.name === path.split("/").pop())) {
        return reply({ ok: false, error: "File non presente nello spazio immagini TEST." }, 404);
      }

      // L'ultima immagine caricata diventa quella principale; le precedenti restano nello storico.
      await admin.from("immagini_oggetto").update({ immagine_principale: false })
        .eq("codice_oggetto", objectId).eq("immagine_principale", true);
      const { error: insertError } = await admin.from("immagini_oggetto").insert({
        codice_oggetto: objectId,
        riferimento_immagine: fileName,
        tipo_immagine: "FOTO_ESEMPLARE",
        fonte_immagine: "FOTO_UTENTE",
        url_fonte: `storage://${BUCKET}/${path}`,
        immagine_principale: true,
        data_registrazione: new Date().toISOString(),
        note: `Foto utente acquisita tramite ${acquisition === "FOTOCAMERA" ? "fotocamera" : "caricamento file"} in ${procedure} (TEST).`,
        stato_verifica: "CONFERMATA",
        confermata_il: new Date().toISOString(),
        confermata_da: user.id,
        modalita_acquisizione: procedure === "PR-01" ? "ACQUISIZIONE_INIZIALE" : "MODIFICA_OGGETTO",
        procedura_origine: procedure,
      });
      if (insertError) throw insertError;
    } else if (action !== "get") {
      return reply({ ok: false, error: "Azione non riconosciuta." }, 400);
    }

    const { data: images, error: imagesError } = await admin.from("immagini_oggetto")
      .select("codice_immagine,riferimento_immagine,url_fonte,immagine_principale,data_registrazione,procedura_origine")
      .eq("codice_oggetto", objectId)
      .order("immagine_principale", { ascending: false })
      .order("data_registrazione", { ascending: false })
      .limit(1);
    if (imagesError) throw imagesError;
    if (!images || images.length === 0) return reply({ ok: true, signed_url: null, immagine: null });

    const image = images[0];
    const prefix = `storage://${BUCKET}/`;
    if (typeof image.url_fonte !== "string" || !image.url_fonte.startsWith(prefix)) {
      return reply({ ok: true, signed_url: image.url_fonte, immagine: image });
    }
    const path = image.url_fonte.slice(prefix.length);
    const storage = createClient(URL, SERVICE, { auth: { persistSession: false, autoRefreshToken: false } }).storage;
    const { data: signed, error: signedError } = await storage.from(BUCKET).createSignedUrl(path, 3600);
    if (signedError) throw signedError;
    return reply({ ok: true, signed_url: signed.signedUrl, immagine: image });
  } catch (error) {
    return reply({ ok: false, error: error instanceof Error ? error.message : String(error) }, 400);
  }
});
