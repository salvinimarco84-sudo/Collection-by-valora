from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
MAIN = ROOT / "lib" / "main.dart"
PUBSPEC = ROOT / "pubspec.yaml"
LOGO = ROOT / "valora_logo.png"

if not LOGO.is_file():
    raise SystemExit("ERRORE: valora_logo.png non trovato nella radice del repository.")
if not MAIN.is_file():
    raise SystemExit("ERRORE: lib/main.dart non trovato.")
if not PUBSPEC.is_file():
    raise SystemExit("ERRORE: pubspec.yaml non trovato.")

source = MAIN.read_text(encoding="utf-8")

# Riconosce il vecchio contenitore-logo anche se il formatter Flutter
# ha cambiato spazi e interruzioni di riga.
login_pattern = re.compile(
    r"Container\s*\(\s*"
    r"width\s*:\s*112\s*,\s*"
    r"height\s*:\s*112\s*,\s*"
    r"decoration\s*:\s*BoxDecoration\s*\(\s*"
    r"shape\s*:\s*BoxShape\.circle\s*,\s*"
    r"color\s*:\s*cardColor\s*,\s*"
    r"border\s*:\s*Border\.all\s*\(\s*color\s*:\s*goldColor\s*,\s*width\s*:\s*2\s*\)\s*,?\s*\)\s*,\s*"
    r"child\s*:\s*const\s+Icon\s*\(\s*"
    r"Icons\.inventory_2_outlined\s*,\s*color\s*:\s*goldColor\s*,\s*size\s*:\s*56\s*,?\s*\)\s*,?\s*\)",
    re.MULTILINE,
)

new_login = """ClipOval(
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
                    )"""

if "Image.asset('valora_logo.png'" not in source and "Image.asset(\n                        'valora_logo.png'" not in source:
    source, count = login_pattern.subn(new_login, source, count=1)
    if count == 0:
        # Non bloccare la build per una differenza grafica: il logo è facoltativo.
        print("AVVISO: blocco logo login non riconosciuto; mantengo l'icona attuale.")

# Logo nell'AppBar, se il titolo atteso esiste. La mancata corrispondenza
# non deve interrompere la compilazione.
appbar_patterns = [
    re.compile(r"title\s*:\s*const\s+Text\s*\(\s*'COLLECTION by VALORA'\s*,\s*style\s*:\s*TextStyle\s*\(\s*fontWeight\s*:\s*FontWeight\.bold\s*,\s*letterSpacing\s*:\s*1\s*\)\s*\)"),
    re.compile(r"title\s*:\s*const\s+Text\s*\(\s*\n\s*'COLLECTION by VALORA'\s*,\s*\n\s*style\s*:\s*TextStyle\(fontWeight:\s*FontWeight\.bold,\s*letterSpacing:\s*1\),\s*\n\s*\)"),
]
new_title = """title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'valora_logo.png',
                width: 40,
                height: 40,
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
          )"""
if "Image.asset(" not in source or "'valora_logo.png'" not in source:
    for pattern in appbar_patterns:
        source, count = pattern.subn(new_title, source, count=1)
        if count:
            break

# Configura l'asset dal percorso root del repository; rimuove il vecchio assets/ path.
yaml = PUBSPEC.read_text(encoding="utf-8")
flutter_match = re.search(r"(?ms)^flutter:\s*\n(?P<body>(?:(?:^[ \t].*\n)|(?:^[ \t]*\n))*)", yaml)
if flutter_match:
    lines = ("flutter:\n" + flutter_match.group("body")).splitlines()
    lines = [line for line in lines if not re.match(r"^\s*-\s*['\"]?(?:assets/)?valora_logo\.png['\"]?\s*$", line)]
    if not any(re.match(r"^\s+uses-material-design\s*:", line) for line in lines):
        lines.append("  uses-material-design: true")
    if not any(re.match(r"^\s+assets\s*:", line) for line in lines):
        lines.append("  assets:")
    # Dichiarare entrambi i percorsi: il file originale alla radice e la copia
    # usata dalla schermata di accesso Flutter.
    lines.append("    - valora_logo.png")
    lines.append("    - assets/valora_logo.png")
    replacement = "\n".join(lines) + "\n"
    yaml = yaml[:flutter_match.start()] + replacement + yaml[flutter_match.end():]
else:
    yaml = yaml.rstrip() + "\n\nflutter:\n  uses-material-design: true\n  assets:\n    - valora_logo.png\n    - assets/valora_logo.png\n"

# Scrittura solo dopo aver controllato tutti i file richiesti.
MAIN.write_text(source, encoding="utf-8")
PUBSPEC.write_text(yaml, encoding="utf-8")
# Imposta nome e icona Android usando lo stesso file logo impiegato nella schermata di accesso.
ANDROID = ROOT / "android"
if ANDROID.is_dir():
    try:
        from PIL import Image, ImageOps
    except ImportError as exc:
        raise SystemExit("ERRORE: Pillow è necessario per generare l'icona Android.") from exc

    manifest = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    if manifest.is_file():
        manifest_text = manifest.read_text(encoding="utf-8")
        manifest_text = re.sub(r'android:label="[^"]*"', 'android:label="COLLECTION by VALORA"', manifest_text, count=1)
        manifest_text = re.sub(r'android:icon="[^"]*"', 'android:icon="@mipmap/ic_launcher"', manifest_text, count=1)
        manifest.write_text(manifest_text, encoding="utf-8")

    with Image.open(LOGO) as original:
        logo = original.convert("RGBA")
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        folder = ANDROID / "app" / "src" / "main" / "res" / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        canvas = Image.new("RGBA", (size, size), (18, 18, 18, 255))
        fitted = ImageOps.contain(logo, (int(size * 0.82), int(size * 0.82)), Image.Resampling.LANCZOS)
        canvas.alpha_composite(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2))
        canvas.save(folder / "ic_launcher.png")
        adaptive_size = int(size * 2)
        foreground = Image.new("RGBA", (adaptive_size, adaptive_size), (0, 0, 0, 0))
        fitted_fg = ImageOps.contain(logo, (int(adaptive_size * 0.66), int(adaptive_size * 0.66)), Image.Resampling.LANCZOS)
        foreground.alpha_composite(fitted_fg, ((adaptive_size - fitted_fg.width) // 2, (adaptive_size - fitted_fg.height) // 2))
        foreground.save(folder / "ic_launcher_foreground.png")

    adaptive = ANDROID / "app" / "src" / "main" / "res" / "mipmap-anydpi-v26"
    adaptive.mkdir(parents=True, exist_ok=True)
    (adaptive / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n', encoding="utf-8")
    colors = ANDROID / "app" / "src" / "main" / "res" / "values"
    colors.mkdir(parents=True, exist_ok=True)
    (colors / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources><color name="ic_launcher_background">#121212</color></resources>\n',
        encoding="utf-8")
    print("Nome e icona Android configurati con il logo VALORA.")
print("Logo VALORA configurato dalla radice del repository.")
