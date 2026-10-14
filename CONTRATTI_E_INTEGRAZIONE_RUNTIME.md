# Contratti runtime TEST: guida di integrazione

Snapshot del catalogo `collection.runtime_catalogo_api`, progetto TEST `eeiekkflpnkummxtvljy`, 13/10/2026. Il dettaglio completo è in `contratti_runtime_test.json`.

## Regole non negoziabili

1. Tutte le 43 API risultano `API_IMPLEMENTATA_DA_COLLAUDARE`; nessuna è considerata collaudata.
2. Non inviare chiamate di scrittura finché non sono disponibili autenticazione utente autorizzato, contratto del runtime verificato e test su dati di collaudo.
3. Per tutte le procedure di scrittura `WRITE-PR-01`…`WRITE-PR-10`, il contratto dichiara `procedure`, `step` (`preview`, `review`, `save`) e `payload`. Non saltare preview e review; il salvataggio deve essere esplicito.
4. Le procedure che supportano batch devono raccogliere tutti i record della sessione prima della conferma finale. Dopo la conferma, rileggere dal database e confrontare i dati scritti.
5. Le API `READ-*`, `REPORT-*`, `RUNTIME-CATALOG` e `RUNTIME-HEALTH` sono classificate sola lettura nel catalogo, ma devono comunque essere collaudate con l'utente autorizzato.
6. Il runtime richiede autenticazione/allowlist e, dove previsto, lock esclusivo. Nessuna chiave `service_role` deve essere inclusa nell'app Flutter.
7. Non puntare mai alla produzione `bufwceckrmbocctarthj`; usare esclusivamente TEST `eeiekkflpnkummxtvljy` durante il collaudo.

## Contratti principali di consultazione

| API | Campo contratto | Parametri presenti nello snapshot |
|---|---|---|
| `READ-OBJECT-MASTER` | `consultation_code=OBJECT_MASTER` | `arguments.codice_oggetto` |
| `READ-OBJECTS-AVAILABLE` | `consultation_code=OBJECTS_AVAILABLE` | `arguments.cerca`, `limite`, `offset` |
| `READ-OBJECTS-EDITABLE` | `consultation_code=OBJECTS_EDITABLE` | `arguments.cerca`, `limite`, `offset` |
| `READ-OBJECTS-SELLABLE` | `consultation_code=OBJECTS_SELLABLE` | `arguments.limite`, `offset` |
| `READ-VALUATION-PREPARE` | `consultation_code=MARKET_VALUATION_PREPARE` | `arguments.codice_oggetto`, `mercato_riferimento` |
| `REPORT-ACTIVE-LISTINGS` | `report_code=ACTIVE_LISTINGS_REPORT` | `arguments.limite`, `offset` |
| `REPORT-CASH` | `report_code=CASH_MOVEMENTS_REPORT` | `arguments.data_da`, `data_a`, `limite`, `offset` |
| `REPORT-PURCHASES` | `report_code=PURCHASES_REPORT` | `arguments.anno`, `mese`, `data_da`, `data_a`, `limite`, `offset` |
| `REPORT-SALES` | `report_code=SALES_REPORT` | `arguments.anno`, `mese`, `data_da`, `data_a`, `limite`, `offset` |
| `RUNTIME-CATALOG` | `action_runtime=catalog` | Nessun parametro nel catalogo |
| `RUNTIME-HEALTH` | `action_runtime=health` | Nessun parametro nel catalogo |

Questi sono i campi dichiarati nel catalogo, non una garanzia che il runtime li accetti correttamente: serve test HTTP autenticato end-to-end.

## Scritture: envelope catalogato

Esempio di struttura dichiarativa, **non inviare finché il runtime non è stato verificato**:

```json
{
  "procedure": "PR-04",
  "step": "preview",
  "payload": {}
}
```

Il `payload` effettivo non è specificato oltre `{}` nel catalogo per le procedure generiche; deve essere ricavato dal contratto della procedura SQL/runtime, non inventato dalla UI. Ripetere con `step=review` dopo aver presentato il riepilogo, e solo dopo conferma esplicita con `step=save`. La semantica precisa di risposta, errori, idempotenza e rilettura va verificata in collaudo.

## Mappature corrette in questa revisione

- Rimossa la mappatura errata di `Nuovo movimento extra` a `REPORT-CASH`: un report di sola lettura non può rappresentare una scrittura.
- Le voci prive di una API certa restano non associate e non devono attivare chiamate.
- Le corrispondenze UI/API sono candidate, non certificate: le procedure d'acquisto/vendita vanno controllate con il manuale ufficiale prima dell'attivazione.

## Collaudo richiesto prima dell'uso

- [ ] Verificare schema request/response della Edge Function e header autorizzativi.
- [ ] Verificare utente in allowlist e rifiuto di utenti non autorizzati.
- [ ] Testare tutte le consultazioni con input validi, vuoti, fuori limite e record inesistente.
- [ ] Testare preview/review/save su dati TEST dedicati, incluso annullamento prima del save.
- [ ] Verificare batch atomico: un record invalido non deve lasciare scritture parziali, se questa è la semantica prevista.
- [ ] Rileggere ogni record dopo la scrittura e verificare i dati.
- [ ] Verificare lock, timeout, concorrenza, errori di rete e idempotenza.
- [ ] Eseguire test Flutter e build Android/Windows in ambiente con SDK installati.
