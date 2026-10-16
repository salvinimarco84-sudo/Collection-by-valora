#!/usr/bin/env python3
"""Static guardrails for environments without Flutter/Dart SDK; not a Dart compiler."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
main = (root / 'lib' / 'main.dart').read_text(encoding='utf-8')
pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
readme = (root / 'README.md').read_text(encoding='utf-8')
checks = {
    'runtime TEST project only': 'eeiekkflpnkummxtvljy' in main and 'bufwceckrmbocctarthj' not in main,
    'stable session ID persisted in SQLite': "'session_id'" in main and 'app_meta' in main,
    'idempotency key persisted': 'request_id' in main and 'operation_queue' in main,
    'FIFO queue order': "orderBy: 'created_at ASC'" in main,
    'exclusive lock acquire and heartbeat': "action: 'acquire_lock'" in main and "action: 'heartbeat'" in main,
    'explicit release lock': "action: 'release_lock'" in main,
    'queue recovery endpoint': "action: 'queue_pending'" in main and "action: 'sync_operation'" in main,
    'official commands exact-match only': 'resolveExactCommand' in main and 'normalized.contains' not in main,
    'voice input dependency and handler': 'speech_to_text:' in pubspec and 'toggleVoice' in main,
    'SQLite dependencies': 'sqflite:' in pubspec and 'sqflite_common_ffi:' in pubspec,
    'all PR-01 through PR-10 present': all(f"'{code}'" in main for code in [f'PR-{i:02d}' for i in range(1, 11)]),
    'exit metadata commands present': all(code in main for code in ['CMD-DATA-OUT', 'CMD-PRICE-OUT', 'CMD-DATE-PRICE-OUT']),
    'source does not claim build already done': 'non è stato possibile eseguire `flutter analyze`' in readme,
    'native field-driven procedure mask': 'DynamicPayloadEditor' in main and 'showDatePicker' in main and 'TextField(controller: payload' not in main,
    'no duplicate listening declaration': main.count('bool busy = false, lockHeld = false, listening = false;') == 1 and main.count('bool listening = false;') == 0,
    'multiple operation workflow adds a record': 'appendAnotherOperation' in main and 'Nuovo record aggiunto alla bozza' in main,
    'accorpamento not exposed as standalone procedure': "'PR04-ACCORPA-COLLEZ': 'ACCORPA COLLEZIONI'" not in main,
    'stable widget key refreshes procedure form': "ValueKey('payload-$procedure-$editorRevision')" in main,
    'queue preserves request on auth and transient 4xx': all(token in main for token in ["code != 401", "code != 403", "code != 408", "code != 409", "code != 425", "code != 429", "Preserve the original request_id"]),
    'release version is explicitly defined': 'version: 0.3.0+15' in pubspec,
    'no service-role secret embedded in client source': 'service_role' not in main.lower() and 'SUPABASE_SERVICE_ROLE_KEY' not in main,
    'write requests retain request ID for retries': 'activeRequestId ?? uuid.v4()' in main and 'requestId: requestId' in main,
    'write response requires verified persistence': "result['scrittura_eseguita'] != true" in main,
    'CI tests before building Android and Windows': (root / '.github/workflows/build.yml').exists() and 'flutter test --reporter expanded' in (root / '.github/workflows/build.yml').read_text(encoding='utf-8') and 'flutter build windows' in (root / '.github/workflows/build.yml').read_text(encoding='utf-8'),
    'CI runs static contract checks': 'python scripts/static_contract_check.py' in (root / '.github/workflows/build.yml').read_text(encoding='utf-8'),
    "final save creates queue record before HTTP call": main.index("await store.enqueue(requestId: requestId") < main.index("await runtime.request(action: 'exit_apply', payload: finalPayload, requestId: requestId)"),
    "offline retry preserves original request ID": "request(action: 'sync_operation', procedure: item['procedure_code']! as String, payload: payload, requestId: item['request_id']! as String)" in main,
    'final write requires exclusive lock': 'if (!await ensureLock()) return;' in main and 'await runtime.acquireLock()' in main,
    'exit preview cannot report a write as success': "if (result['scrittura_eseguita'] == true) throw StateError('Il server ha scritto durante la fase di conferma" in main,
    'exit preview acquires exclusive lock before server validation': main.index('Future<void> confirmData()') < main.index('if (!await ensureLock()) return;', main.index('Future<void> confirmData()')) < main.index("runtime.request(action: 'exit_apply'", main.index('Future<void> confirmData()')),
    'exit final review acquires exclusive lock before server validation': main.index('Future<void> proceedToFinal()') < main.index('if (isExitProcedure && !await ensureLock()) return;', main.index('Future<void> proceedToFinal()')) < main.index("runtime.request(action: 'exit_apply'", main.index('Future<void> proceedToFinal()')),
    'report UI codes map to runtime report contracts': all(token in main for token in ['ACTIVE_LISTINGS_REPORT', 'CASH_MOVEMENTS_REPORT', 'HISTORY_REPORT', 'INVENTORY_SUMMARY_REPORT', 'PURCHASES_REPORT', 'SALES_REPORT']) and 'reportRuntimeCodes[reportCode]' in main,
    'official source editor matches runtime contract': all(token in main for token in ["'estratto': ''", "'tipo_fonte': 'PRODUTTORE_UFFICIALE'", "'tipo_fonte' => ['PRODUTTORE_UFFICIALE', 'ARCHIVIO_UFFICIALE_PRODUTTORE']"]),
    'Android voice permissions are configured in CI': (root / 'scripts/prepare_android_manifest.py').exists() and 'Configure Android voice permissions' in (root / '.github/workflows/build.yml').read_text(encoding='utf-8'),
    'runtime health and API catalog controls are wired': all(token in main for token in ["runtime.request(action: 'health')", "runtime.request(action: 'catalog')", 'STATO RUNTIME', 'CATALOGO API']),
    'release version matches README and package': '0.3.0+15' in readme and 'version: 0.3.0+15' in pubspec,
}
for name, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + ' | ' + name)
if not all(checks.values()):
    sys.exit(1)
print(f'\n{len(checks)} controlli statici superati. Questi controlli NON sostituiscono flutter analyze/test né una build nativa.')
