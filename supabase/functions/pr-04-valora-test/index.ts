import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const URL = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Metodo non consentito." }, 405);
  try {
    const authorization = req.headers.get("Authorization") ?? "";
    const token = authorization.startsWith("Bearer ") ? authorization.slice(7) : "";
    if (!token) return json({ error: "Autenticazione richiesta." }, 401);

    const authClient = createClient(URL, ANON, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: authError } = await authClient.auth.getUser(token);
    if (authError || !userData.user) return json({ error: "Sessione non valida." }, 401);

    const body = await req.json();
    if (body?.action !== "save") return json({ error: "Azione non riconosciuta." }, 400);
    if (body?.conferma_finale !== true) return json({ error: "Conferma finale obbligatoria." }, 400);
    const requestId = String(body?.request_id ?? "");
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(requestId)) {
      return json({ error: "Identificativo richiesta non valido." }, 400);
    }
    if (!body?.payload || typeof body.payload !== "object" || Array.isArray(body.payload)) {
      return json({ error: "Payload acquisto non valido." }, 400);
    }

    const admin = createClient(URL, SERVICE, {
      auth: { persistSession: false, autoRefreshToken: false },
      db: { schema: "collection" },
    });
    const { data: allowed, error: allowError } = await admin
      .from("app_authorized_users")
      .select("user_id")
      .eq("user_id", userData.user.id)
      .eq("attivo", true)
      .maybeSingle();
    if (allowError) return json({ error: "Verifica autorizzazioni non riuscita." }, 500);
    if (!allowed) return json({ error: "Utente non autorizzato all'ambiente TEST." }, 403);

    const { data, error } = await admin.rpc("pr_04_valora_nuovo_acquisto", {
      p_request_id: requestId,
      p_user_id: userData.user.id,
      p_payload: body.payload,
    });
    if (error) return json({ error: error.message }, 400);
    if (!data || data.stato !== "SALVATO_E_VERIFICATO" ||
        data.oggetto_nuovo_creato !== true || data.quadratura_verificata !== true) {
      return json({ error: "Il database non ha restituito una conferma completa.", result: data }, 409);
    }
    return json({ ok: true, result: data });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error) }, 400);
  }
});
