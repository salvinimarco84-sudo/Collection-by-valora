from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
main = ROOT / "lib" / "main.dart"
pubspec = ROOT / "pubspec.yaml"
logo = ROOT / "valora_logo.png"

if not logo.is_file():
    raise SystemExit(
        "ERRORE: valora_logo.png non trovato nella radice del repository."
    )
if not main.is_file():
    raise SystemExit("ERRORE: lib/main.dart non trovato.")

source = main.read_text(encoding="utf-8")

old_login = """                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardColor,
                      border: Border.all(color: goldColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: goldColor,
                      size: 56,
                    ),
                  ),"""

new_login = """                  ClipOval(
                    child: Image.asset(
                      'valora_logo.png',
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        color: goldColor,
                        size: 56,
                      ),
                    ),
                  ),"""

old_title = """        title: const Text(
          'COLLECTION by VALORA',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),"""

new_title = """        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'valora_logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.inventory_2_outlined,
                color: goldColor,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'COLLECTION by VALORA',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),"""

# Avoid partially editing main.dart if the expected source blocks are absent.
if old_login not in source:
    raise SystemExit(
        "ERRORE: blocco logo della schermata di accesso non trovato. "
        "Nessun file è stato modificato."
    )
if old_title not in source:
    raise SystemExit(
        "ERRORE: titolo dell'intestazione non trovato. "
        "Nessun file è stato modificato."
    )

source = source.replace(old_login, new_login, 1)
source = source.replace(old_title, new_title, 1)

# Ensure Flutter packages the logo from the repository root, without assets/.
yaml = pubspec.read_text(encoding="utf-8") if pubspec.exists() else ""
flutter_block = re.search(
    r"(?ms)^flutter:\s*\n(?:(?:^[ \t].*\n)|(?:^[ \t]*\n))*",
    yaml,
)

if flutter_block:
    block = flutter_block.group(0)
    lines = [line for line in block.splitlines() if line.strip()]
    if not any(re.match(r"^\s+uses-material-design\s*:", line) for line in lines):
        lines.append("  uses-material-design: true")

    # Remove any prior root-logo or assets-folder logo entries, then add root path.
    lines = [
        line for line in lines
        if not re.match(r"^\s*-\s*['\"]?(?:assets/)?valora_logo\.png['\"]?\s*$", line)
    ]

    # Keep a single assets key at the Flutter section level.
    assets_index = next(
        (i for i, line in enumerate(lines)
         if re.match(r"^\s+assets\s*:", line)),
        None,
    )
    if assets_index is None:
        lines.append("  assets:")
        lines.append("    - valora_logo.png")
    else:
        # Keep the assets key and replace its list with the root logo.
        lines = lines[:assets_index + 1] + ["    - valora_logo.png"]

    replacement = "\n".join(lines) + "\n"
    yaml = yaml[:flutter_block.start()] + replacement + yaml[flutter_block.end():]
else:
    if yaml and not yaml.endswith("\n"):
        yaml += "\n"
    yaml += "\nflutter:\n  uses-material-design: true\n  assets:\n    - valora_logo.png\n"

# Write only after all source checks and pubspec preparation have succeeded.
main.write_text(source, encoding="utf-8")
pubspec.write_text(yaml, encoding="utf-8")
print("Logo VALORA configurato dalla radice del repository.")
