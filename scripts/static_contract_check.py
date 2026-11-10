#!/usr/bin/env python3
"""Static regression checks for the current VALORA Flutter source.

These checks validate source contracts only. They do not replace Dart analysis,
Flutter tests, a native build, or authenticated end-to-end checks against TEST.
"""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
main = (root / "lib" / "main.dart").read_text(encoding="utf-8")
pr06_page_state = (root / "lib" / "procedures" / "pr06_page_state.dart").read_text(encoding="utf-8")
pr02_runtime = (root / "lib" / "procedures" / "pr02_runtime_procedure.dart").read_text(encoding="utf-8")
pr12_runtime = (root / "lib" / "procedures" / "valora_pr12_runtime.dart").read_text(encoding="utf-8")
pr12_candidate_apply = (root / "lib" / "procedures" / "valora_pr12_candidate_apply.dart").read_text(encoding="utf-8")
pr12_batch_page = (root / "lib" / "procedures" / "pr12_batch_page.dart").read_text(encoding="utf-8")
pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
workflow_path = root / ".github" / "workflows" / "collection-valora-ci.yml"
workflow = workflow_path.read_text(encoding="utf-8") if workflow_path.exists() else ""

checks = {
    "object edit action is wired": "MODIFICA OGGETTO" in main and "Future<void> _openObjectForEdit()" in main,
    "put-for-sale action is wired": "METTI IN VENDITA" in main and "Future<void> _putObjectForSale()" in main,
    "new sale screen exists": "class NewSalePage" in pr06_page_state,
    "new sale can preselect the requested object": "NewSalePage(initialObjectCode: id)" in main and "final int? initialObjectCode;" in pr06_page_state,
    "PR-02 loads editable collection categories": "widget.apiCode == 'PR-02'" in main and "_loadCollectionCategories();" in main and "_collectionCategoryField()" in main,
    "PR-02 collection category is selected": "_selectedCollectionCategory" in main and "categoria_collezione_selezionata" in main,
    "PR-02 removes technical category from object payload": "oggetto_collezione_categoria" in pr02_runtime and "_savePr02PendingChanges" in pr02_runtime,
    "PR-01 validates collection category": "Seleziona una categoria COLLEZIONE valida." in main,
    "PR-12 runtime is extracted": "part 'procedures/valora_pr12_runtime.dart';" in main and "extension _ObjectRuntimePagePr12Runtime" in pr12_runtime,
    "PR-12 candidate application is extracted": "part 'procedures/valora_pr12_candidate_apply.dart';" in main and "extension _ObjectRuntimePagePr12CandidateApply" in pr12_candidate_apply and "Future<void> _pr12ApplySelectedCandidate(" in pr12_candidate_apply,
    "PR-12 catalog scan exists": "_loadIncompleteMetadataCatalog" in pr12_runtime,
    "PR-12 batch engine exists": "_runPr12AiBatch" in pr12_runtime and "LOTTO DA 10" in (root / "lib" / "procedures" / "pr12_runtime_presentation.dart").read_text(encoding="utf-8"),
    "PR-12 presentation is extracted": "part 'procedures/pr12_runtime_presentation.dart';" in main and "Widget _buildPr12Screen()" in (root / "lib" / "procedures" / "pr12_runtime_presentation.dart").read_text(encoding="utf-8") and "if (code == 'PR-12') return _buildPr12Screen();" in main,
    "VALORA photo search presentation is extracted": "part 'procedures/valora_photo_search_presentation.dart';" in main and "Widget _buildPhotoSearchResultsSection()" in (root / "lib" / "procedures" / "valora_photo_search_presentation.dart").read_text(encoding="utf-8") and "_buildPhotoSearchResultsSection()" in (root / "lib" / "procedures" / "valora_service_presentation.dart").read_text(encoding="utf-8"),
    "VALORA confirmed photo candidate flow is extracted": "part 'procedures/valora_photo_candidate_flow.dart';" in main and "mixin _ValoraPhotoCandidateFlow" in (root / "lib" / "procedures" / "valora_photo_candidate_flow.dart").read_text(encoding="utf-8") and "Future<void> _openUncataloguedCandidate(int index) async" in (root / "lib" / "procedures" / "valora_photo_candidate_flow.dart").read_text(encoding="utf-8"),
    "active listings report code exists": "REPORT-ACTIVE-LISTINGS" in main,
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
