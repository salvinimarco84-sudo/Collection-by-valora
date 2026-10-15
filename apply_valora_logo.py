from pathlib import Path

main = Path("lib/main.dart")
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
                      'assets/valora_logo.png',
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
if old_login not in source:
    raise SystemExit("ERRORE: blocco logo della schermata di accesso non trovato; nessuna modifica applicata.")
source = source.replace(old_login, new_login, 1)

old_title = """        title: const Text(
          'COLLECTION by VALORA',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),"""
new_title = """        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/valora_logo.png',
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
if old_title not in source:
    raise SystemExit("ERRORE: titolo dell'intestazione non trovato; nessuna modifica applicata.")
source = source.replace(old_title, new_title, 1)
main.write_text(source, encoding="utf-8")

pubspec = Path("pubspec.yaml")
yaml = pubspec.read_text(encoding="utf-8")
if "assets/valora_logo.png" not in yaml:
    yaml += "\nflutter:\n  uses-material-design: true\n  assets:\n    - assets/valora_logo.png\n"
    # Existing pubspec copied from FLAT has flutter: uses-material-design: true;
    # replace that section instead of creating a duplicate top-level key.
    yaml = yaml.replace(
        "flutter:\n  uses-material-design: true\n\nflutter:\n  uses-material-design: true\n  assets:\n    - assets/valora_logo.png\n",
        "flutter:\n  uses-material-design: true\n  assets:\n    - assets/valora_logo.png\n",
    )
pubspec.write_text(yaml, encoding="utf-8")
print("Logo VALORA applicato alla schermata di accesso e all'intestazione.")
