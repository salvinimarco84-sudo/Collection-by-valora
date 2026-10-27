#!/usr/bin/env python3
"""Static regression checks for the current VALORA Flutter source.

These checks validate source contracts only. They do not replace Dart analysis,
Flutter tests, a native build, or authenticated end-to-end checks against TEST.
"""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
main = (root / "lib" / "main.dart").read_text(encoding="utf-8")
pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
workflow_path = root / ".github" / "workflows" / "collection-valora-ci.yml"
workflow = workflow_path.read_text(encoding="utf-8") if workflow_path.exists() else ""

checks = {
    "object edit action is wired": "MODIFICA OGGETTO" in main and "Future<void> _openObjectForEdit()" in main,
    "put-for-sale action is wired": "METTI IN VENDITA" in main and "Future<void> _putObjectForSale()" in main,
    "new sale screen exists": "class NewSalePage" in main,
    "new sale can preselect the requested object": "NewSalePage(initialObjectCode: id)" in main and "final int? initialObjectCode;" in main,
    "PR-02 collection category is selected": "_selectedCollectionCategory" in main and "categoria_collezione_selezionata" in main,
    "PR-02 removes technical category from object payload": "oggetto_collezione_categoria" in main and "_savePr02PendingChanges" in main,
    "PR-01 validates collection category": "Seleziona una categoria COLLEZIONE valida." in main,
    "PR-12 catalog scan exists": "_loadIncompleteMetadataCatalog" in main,
    "PR-12 batch engine exists": "_runPr12AiBatch" in main and "LOTTO DA 10" in main,
    "active listings report code exists": "apiCode: 'REPORT-SALES-ACTIVE'" in main,
    "runtime lock methods exist": "Future<void> _acquireLock()" in main and "Future<void> _releaseLock()" in main,
    "write response checks persistence confirmation": "result['scrittura_eseguita'] != true" in main,
    "test project ID is present": "eeiekkflpnkummxtvljy" in main,
    "known production project ID is absent": "bufwceckrmbocctarthj" not in main,
    "package version is explicitly defined": "version: 0.3.2+18" in pubspec,
    "CI runs Flutter analysis": "flutter analyze lib/main.dart --no-pub --no-fatal-infos --no-fatal-warnings" in workflow,
    "CI runs Flutter tests": "flutter test --reporter expanded" in workflow,
    "CI builds Android release": "flutter build apk --release" in workflow,
    "CI runs static checks": "python scripts/static_contract_check.py" in workflow,
}
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + " | " + name)
if not all(checks.values()):
    sys.exit(1)
print(f"\\n{len(checks)} controlli statici superati. Non sostituiscono i test end-to-end.")
