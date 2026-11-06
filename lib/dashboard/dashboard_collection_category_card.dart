import 'package:flutter/material.dart';

/// Scheda categoria della collezione, con logo e anteprime degli oggetti.
class DashboardCollectionCategoryCard extends StatelessWidget {
  const DashboardCollectionCategoryCard({
    super.key,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.count,
    required this.previewImageUrls,
    required this.onTap,
    this.logoUrl,
  });

  final String code;
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int count;
  final String? logoUrl;
  final List<String?> previewImageUrls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.75)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              leading: (logoUrl ?? '').trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        logoUrl!,
                        width: 62,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _categoryBrandMark(name, color, icon),
                      ),
                    )
                  : _categoryBrandMark(name, color, icon),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              onTap: onTap,
            ),
            if (previewImageUrls.isNotEmpty)
              SizedBox(
                height: 86,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: previewImageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = previewImageUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: url == null
                            ? Icon(icon, color: color, size: 30)
                            : Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 30),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );

  Widget _categoryBrandMark(String category, Color color, IconData fallbackIcon) {
    final base = category.toUpperCase();
    if (base == 'LEGO') {
      return Container(
        width: 62,
        height: 46,
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
        width: 62,
        height: 46,
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
        width: 62,
        height: 46,
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
        width: 62,
        height: 46,
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
        width: 62,
        height: 46,
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
        width: 62,
        height: 46,
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
      width: 62,
      height: 46,
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
