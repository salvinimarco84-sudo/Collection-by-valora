# VALORA guided valuation and listing flow

## Purpose

Replace the current arbitrary object dropdown and preparation-only experience with a guided workflow that starts from a known collection object or an externally identified object, completes a valuation, and then offers the correct next action.

This specification is intentionally limited to the TEST application workflow. It does not authorize production database changes or automatic writes.

## 1. Entry methods

The VALORA screen must offer three equivalent ways to identify an object:

1. **Description search**: case-insensitive partial matching against the user's own collection. Return every matching record, not an arbitrary first 500. Paginate until the result set is exhausted. Exclude archived/test records and objects whose status is SOLD, LOST, DESTROYED, EXITED, or MERGED (using the application's canonical stored values).
2. **Camera**: capture one or more photos, ask the recognition service to identify the item, then search the user's collection for possible matches.
3. **Files**: select one or more existing images from the device, run the same recognition-and-match flow as camera input.

All entry methods converge on one candidate list. Each candidate should show its image when available, description, object code, and enough metadata to distinguish variants. The user must explicitly confirm the exact record before valuation begins.

## 2. No collection match

If no collection match is confirmed, VALORA continues with external identification and market valuation. It must not create a collection record automatically.

At the end of the valuation, ask whether the user wants to acquire and add the item. On confirmation, launch **PR-04 NUOVO ACQUISTO**, prefilled with verified identification data, available images, and valuation context. The user reviews and completes purchase price, date, category, destination, condition, completeness, and other required fields. PR-04 remains the sole owner of purchase persistence.

## 3. Existing collection item

After valuation of a confirmed collection record, show the market estimate and a distinct recommended selling price. The recommended price is editable and is only a suggestion.

Ask whether the user wants to put the item up for sale. If declined, finish without changing the object. If accepted, launch **PR-06 NUOVA VENDITA**, prefilled with the object code and suggested price. Preserve the existing PR-06 validation, preview, confirmation, locking, transaction, and post-save verification behavior.

## 4. Platform-specific listing drafts

Within the sale flow, use the user's selected sales channels. If one or more online marketplaces are selected, ask:

> Vuoi che VALORA crei delle bozze di inserzione per le piattaforme selezionate?

If accepted, create one independent draft per selected marketplace. For example, eBay and Vinted produce two distinct drafts, each following that platform's own fields, category conventions, title/description style, condition parameters, and applicable listing constraints.

Drafts must be linked to the same object and sale operation, but remain independent: editing one platform's title, description, price, or category must not mutate another platform's draft. Reuse only verified object metadata and user-provided condition/completeness; never invent item attributes. Use the valuation's recommended price as the initial suggested price, while allowing platform-specific edits.

Draft creation is not publication. The user reviews and approves each draft. Do not claim that a listing has been published unless a supported marketplace integration confirms publication. Where no publishing integration exists, provide a ready-to-copy/export draft.

## 5. Safety and data integrity

- Keep the TEST Supabase project as the only database environment for implementation and testing.
- Do not modify the production Supabase project or production data.
- Do not bypass PR-04 or PR-06 with direct writes from the VALORA screen.
- Do not create collection records, purchase records, sale records, or marketplace listings without explicit user confirmation in the relevant procedure.
- Do not silently truncate collection search results.
- Preserve current runtime contracts and existing PR-04/PR-06 transactional safeguards.
- Persist platform drafts separately from the object master record and from one another, using an approved TEST schema/API contract before implementation.

## 6. Implementation sequence

1. Replace the current dropdown with the unified search/identification entry experience and paginated partial description search.
2. Integrate camera and multi-image file selection with the recognition/matching service, returning candidates for explicit confirmation.
3. Connect the confirmed collection-object path to the completed valuation result and recommended selling price.
4. Connect the no-match path to PR-04 prefilled purchase flow.
5. Connect the collection path to PR-06 prefilled sale flow.
6. Add per-platform draft generation, storage, review, and export/publication handoff.
7. Add automated tests for matching, pagination, branch decisions, prefill mapping, draft isolation, and no-write-before-confirmation. Run Flutter analyze, tests, Android build, and Windows build before merge.

## 7. Acceptance criteria

- Description search returns all matching eligible collection records across pages.
- Camera and file inputs use the same candidate matching and confirmation behavior.
- Valuation starts only after the user confirms a specific collection record, or explicitly continues with an external/no-match item.
- No-match valuation offers PR-04 only after valuation is complete and the user opts in.
- Existing collection valuation offers PR-06 only after valuation is complete and the user opts in.
- PR-06 receives the recommended price but allows the user to change it.
- Selecting eBay and Vinted yields two independent, platform-adapted drafts.
- No draft is published automatically.
- No direct production or bypass writes are introduced.


### PR-04 VALORA: simplified unknown-object acquisition

The unknown-object path opens a dedicated **PR-04 VALORA** entry page derived from the original PR-04 purchase workflow. It is limited to one object and removes the multi-purchase queue and lot-selection steps, while retaining the original PR-04 preview, lock, final confirmation, transactional save, and post-save verification.

VALORA pre-fills the confirmed identification fields and selected catalog image. The user must complete or confirm the actual purchase date, purchase cost, category when the destination is COLLEZIONE, destination, condition, and completeness. The market estimate is shown only as context and is never copied into the purchase-cost field.

The dedicated page calls the same PR-04 runtime and does not write purchase or object records itself. After PR-04 confirms the purchase, VALORA verifies that exactly one purchase-object link exists and that the linked master object can be reread. Only then, if PR18 returned a valuation result, VALORA invokes the existing PR18 valuation-save action against the newly created object code. A missing or failed valuation save must not cause the already verified purchase to be repeated or reported as unsaved.

The standard PR-04 entry page and its multi-object purchase flow remain unchanged.
