#!/usr/bin/env python3
"""Block accidental removal of files that existed in the Run 1085 baseline.

Intentional removals require an explicit, reviewed entry in
scripts/regression_removals_allowlist.txt with a reason.
"""
from pathlib import Path
import subprocess
import sys

BASELINE = "d86142c9ecb6fa2ea93fb7d8815cb23fd1f76008"
PROTECTED_PREFIXES = ("lib/", "assets/", "supabase/migrations/", "sql/")
PROTECTED_FILES = ("pubspec.yaml", "valora_logo.png", "apply_valora_logo.py")
ALLOWLIST = Path("scripts/regression_removals_allowlist.txt")


def git(*args):
    return subprocess.check_output(["git", *args], text=True).splitlines()


def tracked_at(ref):
    return set(git("ls-tree", "-r", "--name-only", ref))


def main():
    try:
        baseline_files = tracked_at(BASELINE)
        current_files = tracked_at("HEAD")
    except subprocess.CalledProcessError as error:
        print(f"FAIL | impossibile leggere baseline Git {BASELINE}: {error}")
        return 2

    allowed = {}
    if ALLOWLIST.exists():
        for line in ALLOWLIST.read_text(encoding="utf-8").splitlines():
            value = line.strip()
            if not value or value.startswith("#"):
                continue
            path, separator, reason = value.partition("|")
            if not separator or not reason.strip():
                print(f"FAIL | voce allowlist non valida: {line}")
                return 1
            allowed[path.strip()] = reason.strip()

    protected = {
        path for path in baseline_files
        if path.startswith(PROTECTED_PREFIXES) or path in PROTECTED_FILES
    }
    removed = sorted((protected - current_files) - set(allowed))
    stale = sorted(set(allowed) - (protected - current_files))

    if removed:
        print("FAIL | file protetti della Run 1085 rimossi senza autorizzazione:")
        for path in removed:
            print(f"  - {path}")
    if stale:
        print("FAIL | autorizzazioni obsolete o non applicate:")
        for path in stale:
            print(f"  - {path}")
    if removed or stale:
        print("Ripristinare i file oppure aggiungere una rimozione motivata e revisionata all'allowlist.")
        return 1

    print(f"PASS | {len(protected)} file della baseline Run 1085 verificati: nessuna perdita non autorizzata.")
    print("PASS | eventuali rimozioni intenzionali richiedono motivazione esplicita.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
