import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String valoraThemeAsset(String id) => switch (id) {
  'industrial' => 'assets/themes/industrial.jpg',
  'emerald' => 'assets/themes/electric_green.jpg',
  'black_gold' => 'assets/themes/black_gold.jpg',
  'comic' => 'assets/themes/comic_style.jpg',
  'midnight_blue' => 'assets/themes/midnight_blue.jpg',
  'dark_red' => 'assets/themes/fire_red.jpg',
  'pastel' => 'assets/themes/pastel.jpg',
  'minimal_zen' => 'assets/themes/minimal_zen.jpg',
  'royal_purple' => 'assets/themes/royal_purple.jpg',
  'silver_light' => 'assets/themes/silver_light.jpg',
  _ => 'assets/themes/electric_green.jpg',
};

class ValoraThemeBackdropPainter extends CustomPainter {
  final String themeId;
  final Color background;
  final Color accent;
  ValoraThemeBackdropPainter({required this.themeId, required this.background, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [background, Color.lerp(background, accent, 0.075)!, background],
    ).createShader(bounds));

    // Profondità cromatica per la schermata principale: bagliori morbidi ai bordi,
    // mantenendo il centro più quieto per la leggibilità delle schede.
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.92, -0.82),
        radius: 1.15,
        colors: [
          accent.withValues(alpha: themeId == 'emerald' || themeId == 'dark_red' ? 0.32 : 0.22),
          accent.withValues(alpha: 0.025),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, glowPaint);
    final lowerGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.94, 0.88),
        radius: 1.0,
        colors: [accent.withValues(alpha: 0.14), Colors.transparent],
      ).createShader(bounds);
    canvas.drawRect(bounds, lowerGlow);

    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1
      ..color = accent.withValues(alpha: 0.24);
    final fill = Paint()..style = PaintingStyle.fill..color = accent.withValues(alpha: 0.075);
    switch (themeId) {
      case 'emerald': // Circuiti elettronici stilizzati
        for (var row = 0; row < 11; row++) {
          final y = size.height * row / 10;
          final path = Path()..moveTo(0, y);
          var x = 0.0;
          while (x < size.width) {
            final step = 22.0 + ((row * 13 + x.toInt()) % 41);
            path.lineTo(x + step * 0.55, y);
            path.lineTo(x + step * 0.55, y + ((row % 2 == 0) ? 12 : -12));
            path.lineTo(x + step, y + ((row % 2 == 0) ? 12 : -12));
            x += step;
          }
          canvas.drawPath(path, p);
          for (var col = 0; col < 7; col++) {
            canvas.drawCircle(Offset((size.width / 7) * col + row * 5.0, y), 2.2, fill);
          }
        }
        break;
      case 'dark_red': // Crepe vulcaniche e bagliore magma
        final crack = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8
          ..color = accent.withValues(alpha: 0.15);
        for (var i = 0; i < 24; i++) {
          final x = (i * 79.0) % (size.width + 30);
          final y = (i * 113.0) % (size.height + 20);
          final path = Path()..moveTo(x, y);
          for (var n = 0; n < 5; n++) {
            path.lineTo(x + n * 9 + ((i + n) % 3) * 7, y + n * 13.0);
          }
          canvas.drawPath(path, crack);
        }
        break;
      case 'industrial':
        for (var y = 0.0; y < size.height; y += 8) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
        }
        break;
      case 'midnight_blue':
        for (var i = 0; i < 80; i++) {
          final x = (i * 67.0) % size.width;
          final y = (i * 131.0) % size.height;
          canvas.drawCircle(Offset(x, y), (i % 3 + 1).toDouble(), fill);
          if (i % 4 == 0) canvas.drawLine(Offset(x, y), Offset(x + 18, y + 10), p);
        }
        break;
      case 'black_gold':
        final vein = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4
          ..color = accent.withValues(alpha: 0.13);
        for (var i = 0; i < 13; i++) {
          final path = Path()..moveTo((i * 91.0) % size.width, 0);
          for (var y = 0.0; y < size.height; y += 38) {
            path.lineTo(((i * 91.0 + y * 0.37 + (i % 3) * 17) % size.width), y);
          }
          canvas.drawPath(path, vein);
        }
        break;
      case 'comic':
        for (var x = 0.0; x < size.width; x += 12) {
          for (var y = 0.0; y < size.height; y += 12) {
            canvas.drawCircle(Offset(x, y), 1.5, p..style = PaintingStyle.fill);
          }
        }
        break;
      case 'royal_purple':
        for (var i = 0; i < 22; i++) {
          final x = (i * 73.0) % size.width;
          final y = (i * 97.0) % size.height;
          final path = Path()..moveTo(x, y - 17)..lineTo(x + 9, y)..lineTo(x, y + 17)..lineTo(x - 9, y)..close();
          canvas.drawPath(path, p);
        }
        break;
      case 'silver_light':
        for (var i = 0; i < 16; i++) {
          final path = Path()..moveTo(0, i * 59.0);
          path.cubicTo(size.width * .25, i * 59.0 + 30, size.width * .65, i * 59.0 - 24, size.width, i * 59.0 + 8);
          canvas.drawPath(path, p);
        }
        break;
      case 'minimal_zen':
        for (var i = 0; i < 14; i++) {
          canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .78, size.height * .15 + i * 17.0), width: size.width * .7 + i * 8, height: 28 + i * 3.0), p);
        }
        break;
      case 'pastel':
        final soft = Paint()..shader = RadialGradient(colors: [accent.withValues(alpha: .12), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * .82, size.height * .25), radius: size.width * .9));
        canvas.drawRect(bounds, soft);
        break;
    }

    // Forme materiche ampie e irregolari: rompono la griglia geometrica
    // e creano masse visive più organiche, con luce e ombra sovrapposte.
    final textureRandom = math.Random(themeId.hashCode ^ 0x51A7);
    final organicHighlight = Paint()..style = PaintingStyle.fill;
    final organicShadow = Paint()..style = PaintingStyle.fill;
    if (themeId == 'dark_red' || themeId == 'black_gold' || themeId == 'royal_purple' ||
        themeId == 'emerald' || themeId == 'industrial' || themeId == 'silver_light') {
      for (var i = 0; i < 34; i++) {
        final center = Offset(
          textureRandom.nextDouble() * size.width,
          textureRandom.nextDouble() * size.height,
        );
        final radiusX = size.width * (0.035 + textureRandom.nextDouble() * 0.13);
        final radiusY = size.height * (0.012 + textureRandom.nextDouble() * 0.045);
        final points = 7 + textureRandom.nextInt(7);
        final polygon = Path();
        for (var point = 0; point < points; point++) {
          final angle = point * math.pi * 2 / points;
          final irregularity = 0.55 + textureRandom.nextDouble() * 0.8;
          final position = Offset(
            center.dx + math.cos(angle) * radiusX * irregularity,
            center.dy + math.sin(angle) * radiusY * irregularity,
          );
          if (point == 0) {
            polygon.moveTo(position.dx, position.dy);
          } else {
            polygon.lineTo(position.dx, position.dy);
          }
        }
        polygon.close();
        organicShadow.color = Colors.black.withValues(alpha: themeId == 'silver_light' ? 0.045 : 0.11);
        canvas.drawPath(polygon.shift(const Offset(1.8, 2.2)), organicShadow);
        organicHighlight.color = accent.withValues(
          alpha: (themeId == 'dark_red' || themeId == 'emerald') ? 0.075 : 0.055,
        );
        canvas.drawPath(polygon, organicHighlight);
        if (themeId == 'dark_red' || themeId == 'black_gold') {
          final edge = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = textureRandom.nextDouble() * 1.3 + 0.35
            ..color = accent.withValues(alpha: themeId == 'dark_red' ? 0.16 : 0.13);
          canvas.drawPath(polygon, edge);
        }
      }
    }

    // Passaggio materico: grana fine, micrograffi e ombreggiatura per dare
    // profondità alle superfici senza immagini remote o dipendenze dal database.
    // Coordinate deterministiche: la texture resta stabile tra un rebuild e l'altro.
    final isLight = background.computeLuminance() > 0.45;
    final grain = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 520; i++) {
      final x = ((i * 73.0 + (i % 11) * 17.0) % (size.width + 1));
      final y = ((i * 137.0 + (i % 7) * 19.0) % (size.height + 1));
      final radius = (i % 5 == 0) ? 1.15 : 0.55;
      grain.color = (isLight ? Colors.black : Colors.white)
          .withValues(alpha: (i % 4 == 0) ? 0.035 : 0.018);
      canvas.drawCircle(Offset(x, y), radius, grain);
    }

    if (themeId == 'industrial' || themeId == 'silver_light') {
      final scratch = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 95; i++) {
        final x = (i * 47.0) % (size.width + 1);
        final y = (i * 83.0) % (size.height + 1);
        scratch
          ..strokeWidth = i % 7 == 0 ? 1.0 : 0.45
          ..color = (i % 3 == 0 ? Colors.white : Colors.black)
              .withValues(alpha: isLight ? 0.055 : 0.065);
        canvas.drawLine(Offset(x, y), Offset(x + 8 + (i % 19), y + ((i % 5) - 2) * 0.45), scratch);
      }
    } else if (themeId == 'dark_red') {
      final ember = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < 90; i++) {
        final x = (i * 97.0) % (size.width + 1);
        final y = (i * 59.0) % (size.height + 1);
        ember.color = accent.withValues(alpha: i % 9 == 0 ? 0.13 : 0.035);
        canvas.drawCircle(Offset(x, y), i % 9 == 0 ? 1.7 : 0.65, ember);
      }
    } else if (themeId == 'black_gold') {
      final mineralVein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = accent.withValues(alpha: 0.10);
      for (var i = 0; i < 18; i++) {
        final startX = (i * 89.0) % (size.width + 1);
        final path = Path()..moveTo(startX, 0);
        for (var y = 24.0; y < size.height; y += 24) {
          final bend = math.sin((i + y) * 0.031) * 15.0;
          path.lineTo((startX + bend + y * 0.12).clamp(0.0, size.width), y);
        }
        canvas.drawPath(path, mineralVein);
      }
    }

    // Vignettatura morbida: il contenuto e i pulsanti restano al centro della scena.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.05,
        colors: [
          Colors.transparent,
          (isLight ? Colors.black : Colors.black).withValues(alpha: 0.20),
        ],
        stops: const [0.48, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, vignette);
  }

  @override
  bool shouldRepaint(covariant ValoraThemeBackdropPainter oldDelegate) => themeId != oldDelegate.themeId || background != oldDelegate.background || accent != oldDelegate.accent;
}


class ValoraAppearance extends ChangeNotifier {
  // Temi predefiniti: valori bloccati, selezionabili ma non modificabili singolarmente.
  static const Map<String, Map<String, Object>> themePresets = {
    'black_gold': {'name':'Black & Gold','background':0xFF101010,'card':0xB81C1C1C,'accent':0xFFD6B15E,'text':0xFFFFFFFF,'light':false,'comic':false,'zen':false},
    'midnight_blue': {'name':'Midnight Blue','background':0xFF071321,'card':0xB810243A,'accent':0xFF20B8FF,'text':0xFFF4F8FF,'light':false,'comic':false,'zen':false},
    'emerald': {'name':'Electric Green','background':0xFF050A07,'card':0x98101912,'accent':0xFF39FF62,'text':0xFFF1FFF4,'light':false,'comic':false,'zen':false},
    'silver_light': {'name':'Silver Light','background':0xFFF1F4F7,'card':0xBFFFFFFF,'accent':0xFF2878C7,'text':0xFF172333,'light':true,'comic':false,'zen':false},
    'dark_red': {'name':'Fire Red','background':0xFF100605,'card':0x98210B08,'accent':0xFFFF452E,'text':0xFFFFF5F2,'light':false,'comic':false,'zen':false},
    'royal_purple': {'name':'Royal Purple','background':0xFF160D20,'card':0xB828153A,'accent':0xFFD44CFF,'text':0xFFFFF5FF,'light':false,'comic':false,'zen':false},
    'comic': {'name':'Comic Style','background':0xFFFFD928,'card':0xFFFFFBEB,'accent':0xFFE51D2A,'text':0xFF101010,'light':true,'comic':true,'zen':false},
    'minimal_zen': {'name':'Minimal Zen','background':0xFFF3EBDD,'card':0xFFFFFCF5,'accent':0xFFB93D32,'text':0xFF27251F,'light':true,'comic':false,'zen':true},
    'industrial': {'name':'Industrial','background':0xFF20262B,'card':0xFF303940,'accent':0xFFB9C4CC,'text':0xFFF1F4F6,'light':false,'comic':false,'zen':false},
    'pastel': {'name':'Pastel','background':0xFFFFF0F5,'card':0xFFFFFFFF,'accent':0xFF19B7C9,'text':0xFF293344,'light':true,'comic':false,'zen':false},
  };
  String selectedThemeId = 'black_gold';
  Map<String, Object> get _theme => themePresets[selectedThemeId] ?? themePresets['black_gold']!;
  String get selectedThemeName => _theme['name'] as String;
  Color get accent => Color(_theme['accent'] as int);
  bool get comicStyle => _theme['comic'] as bool;
  bool get zenStyle => _theme['zen'] as bool;

  ValoraAppearance._();
  static final instance = ValoraAppearance._();
  static const Map<String, Color> defaults = {
    'CATALOGO': Color(0xFF3978C5),
    'ACQUISTI': Color(0xFFC74444),
    'VENDITE': Color(0xFF39875B),
    'VALUTAZIONI': Color(0xFFD6A83F),
    'REPORT': Color(0xFFE17D35),
    'RICERCHE': Color(0xFF38BDF8),
    'CONTROLLO': Color(0xFF777777),
    'COLLEZIONE': Color(0xFFD6B45C),
    'LEGO': Color(0xFFE31B23),
    'SAINT SEIYA': Color(0xFF7137B8),
    'MOTO DIE-CAST': Color(0xFFDD741D),
    'FUMETTI': Color(0xFF008C4A),
    'GUNDAM': Color(0xFFC62828),
    'TRANSFORMERS': Color(0xFF2476C8),
    'ALTRE COLLEZIONI': Color(0xFF466B87),
  };
  static const List<Color> palette = [
    Color(0xFF3978C5),Color(0xFF39875B),Color(0xFFC74444),Color(0xFFD6A83F),
    Color(0xFF8556C7),Color(0xFFE17D35),Color(0xFF568DAD),Color(0xFF777777),
    Color(0xFF00897B),Color(0xFF8E24AA),Color(0xFF5C6BC0),Color(0xFF7CB342),
    Color(0xFFEF6C00),Color(0xFFAD1457),Color(0xFF00838F),Color(0xFF6D4C41),
    Color(0xFF546E7A),Color(0xFF9E9D24),Color(0xFF3949AB),Color(0xFF00ACC1),
    Color(0xFFF4511E),Color(0xFF43A047),Color(0xFF6A1B9A),Color(0xFF283593),
  ];
  final Map<String, Color> colors = Map<String, Color>.from(defaults);
  bool whiteBackground = false;
  bool useBlockLayout = false;
  final Map<String, String> imageUrls = {};
  final Map<String, String> imagePaths = {};
  Color colorFor(String section) => colors[section] ?? defaults[section] ?? const Color(0xFFD6B15E);
  Color get background => Color(_theme['background'] as int);
  Color get card => Color(_theme['card'] as int);
  Color get textPrimary => Color(_theme['text'] as int);
  Color get textSecondary => (_theme['light'] as bool) ? const Color(0xFF424242) : Colors.white70;
  Color get textMuted => (_theme['light'] as bool) ? const Color(0xFF555555) : Colors.white60;
  Color get textSubtle => (_theme['light'] as bool) ? const Color(0xFF626262) : Colors.white54;
  Color get textFaint => (_theme['light'] as bool) ? const Color(0xFF666666) : Colors.white38;
  Color get neutralOverlay => (_theme['light'] as bool) ? Colors.black.withValues(alpha: 0.06) : Colors.white10;
  Color get neutralOverlayStrong => (_theme['light'] as bool) ? Colors.black.withValues(alpha: 0.12) : Colors.white24;
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    selectedThemeId = p.getString('valora_selected_theme') ?? 'black_gold';
    if (!themePresets.containsKey(selectedThemeId)) selectedThemeId = 'black_gold';
    whiteBackground = _theme['light'] as bool;
    useBlockLayout = p.getBool('valora_block_layout') ?? false;
    imageUrls.clear();
    imagePaths.clear();
    for (final k in defaults.keys) {
      final url = p.getString('valora_image_url_$k');
      final path = p.getString('valora_image_path_$k');
      if (url != null && url.isNotEmpty) imageUrls[k] = url;
      if (path != null && path.isNotEmpty) imagePaths[k] = path;
    }
    for (final k in defaults.keys) { final v=p.getInt('valora_color_$k'); if(v!=null) colors[k]=Color(v); }
    // RICERCHE mantiene l'accento celeste e VALUTAZIONI quello oro anche con preferenze precedenti.
    for (final section in const ['RICERCHE', 'VALUTAZIONI']) {
      colors[section] = defaults[section]!;
      await p.setInt('valora_color_$section', defaults[section]!.value);
    }
    final used=<int>{};
    for(final k in defaults.keys) {
      if(!used.add(colors[k]!.value)) {
        final replacement=palette.firstWhere((c)=>used.add(c.value),orElse:()=>defaults[k]!);
        colors[k]=replacement;
      }
    }
    notifyListeners();
  }
  Future<void> setTheme(String themeId) async {
    if (!themePresets.containsKey(themeId)) return;
    selectedThemeId = themeId;
    whiteBackground = themePresets[themeId]!['light'] as bool;
    final p = await SharedPreferences.getInstance();
    await p.setString('valora_selected_theme', themeId);
    await p.setBool('valora_white_background', whiteBackground);
    notifyListeners();
  }
  Future<void> setLayout(bool blocks) async {
    useBlockLayout = blocks;
    final p = await SharedPreferences.getInstance();
    await p.setBool('valora_block_layout', blocks);
    notifyListeners();
  }
  Future<void> setSectionImage(String section, {String? url, String? path}) async {
    final p = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      imageUrls.remove(section);
      await p.remove('valora_image_url_$section');
    } else {
      imageUrls[section] = url.trim();
      await p.setString('valora_image_url_$section', url.trim());
    }
    if (path == null || path.trim().isEmpty) {
      imagePaths.remove(section);
      await p.remove('valora_image_path_$section');
    } else {
      imagePaths[section] = path.trim();
      await p.setString('valora_image_path_$section', path.trim());
    }
    notifyListeners();
  }
  Future<void> setBackground(bool white) async {
    whiteBackground=white;
    final p=await SharedPreferences.getInstance(); await p.setBool('valora_white_background',white); notifyListeners();
  }
  Future<void> setColor(String section,Color color) async {
    if(colors.entries.any((e)=>e.key!=section&&e.value.value==color.value)) return;
    colors[section]=color;
    final p=await SharedPreferences.getInstance(); await p.setInt('valora_color_$section',color.value); notifyListeners();
  }
  Future<void> reset() async {
    selectedThemeId = 'black_gold';
    whiteBackground = false;
    colors..clear()..addAll(defaults);
    final p = await SharedPreferences.getInstance();
    await p.setString('valora_selected_theme', selectedThemeId);
    await p.setBool('valora_white_background', false);
    for (final k in defaults.keys) { await p.remove('valora_color_$k'); }
    notifyListeners();
  }
}
