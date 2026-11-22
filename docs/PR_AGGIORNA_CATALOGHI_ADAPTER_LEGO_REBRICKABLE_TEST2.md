# Adapter LEGO Rebrickable - TEST2

## Deployment
- Supabase project: hqiisivoistpejvilbeu (TEST2 only)
- Edge Function: `pr-cataloghi-lego-rebrickable-test2`
- Version: 1
- JWT verification: enabled
- Source record: LEGO Official candidate id `44265414-77b2-4f9e-adae-ec3fcf8348ef` (the adapter is currently wired to this source record only after source activation).

## Behaviour
- Accepts POST only; authenticates the caller and checks active PROPRIETARIO/AMMINISTRATORE in `master_utenti`.
- Requires server secret `REBRICKABLE_API_KEY`. It is not embedded in source code.
- Reads only `GET /api/v3/lego/sets/`, maximum 100 records per request.
- Default is dry-run. Set `dry_run:false` only after source authorization/activation.
- Writes proposals only via `pr_cataloghi_registra_proposta`; never writes to `master_lego_catalogo`.
- Does not transfer image URLs or image fields.
- Maps set number, name, set type, theme identifier, piece count, release year, source URL and source modification date.
- Uses external identity `LEGO:<set_num>`.
- Rebrickable rate limit responses (429) are surfaced without retry loops.

## Request
```json
{ "page": 1, "page_size": 50, "dry_run": true }
```

After adding the secret and validating the source, a controlled staging import can use:
```json
{ "page": 1, "page_size": 50, "dry_run": false }
```

## Current blocker / safety gate
- `REBRICKABLE_API_KEY` has not been supplied/configured in Supabase secrets.
- The source remains inactive in `pr_cataloghi_fonti`.
- Therefore the live source call and proposal writes have not been executed.
- Do not enable bulk import before checking Rebrickable terms, data attribution/licensing, API limits, and VALORA field mapping.
- Approval of a staged proposal still does not apply it to the master; the separate transactional master validator remains unimplemented.

## Security hardening
The RPC privileges were tightened:
- `pr_cataloghi_registra_proposta`: service_role only.
- `pr_cataloghi_esegui_controllo`, `pr_cataloghi_decidi_proposta`, `pr_cataloghi_elenco_proposte`: authenticated/service_role, with admin role checks in the function bodies.
- Anonymous execute was revoked.

## Source documentation
- Rebrickable API v3: https://rebrickable.com/api/v3/docs/
- Rebrickable API and bulk download guidance: https://rebrickable.com/api/
