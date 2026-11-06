import 'package:flutter/material.dart';

/// Marchio grafico della categoria mostrato nelle anteprime della dashboard.
class DashboardCategoryBrandMark extends StatelessWidget {
  final String category;
  final Color color;
  final IconData fallbackIcon;

  const DashboardCategoryBrandMark({
    super.key,
    required this.category,
    required this.color,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final base = category.toUpperCase();
    if (base == 'LEGO') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD71920),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: const Text('LEGO', style: TextStyle(
          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900,
          letterSpacing: -1.2, shadows: [Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 1)],
        )),
      );
    }
    if (base == 'TRANSFORMERS') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF174A8B), Color(0xFF101820)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF6DB8FF), width: 1.4),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shield_outlined, color: Color(0xFF6DB8FF), size: 19),
          Text('TRANSFORMERS', maxLines: 1, style: TextStyle(
            color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900, letterSpacing: 0.2,
          )),
        ]),
      );
    }
    if (base == 'GUNDAM') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0E8),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF3B6EA8), width: 2),
        ),
        child: const Text('GUNDAM', style: TextStyle(
          color: Color(0xFF164B8C), fontSize: 11, fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        )),
      );
    }
    if (base == 'FUMETTI') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: const Stack(alignment: Alignment.center, children: [
          Icon(Icons.menu_book_rounded, color: Color(0xFF17202A), size: 29),
          Positioned(right: 3, top: 1, child: Icon(Icons.bolt, color: Color(0xFFD71920), size: 17)),
        ]),
      );
    }
    if (base == 'SAINT SEIYA') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4C237E), Color(0xFF171024)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD7B56D), width: 1.4),
        ),
        child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD76A), size: 30),
      );
    }
    if (base == 'MOTO DIE-CAST') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF7D19), Color(0xFF9D3C0B)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFFFC078), width: 1.2),
        ),
        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 31),
      );
    }
    return Container(
      width: 62, height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Icon(fallbackIcon, color: color, size: 27),
    );
  }
}
