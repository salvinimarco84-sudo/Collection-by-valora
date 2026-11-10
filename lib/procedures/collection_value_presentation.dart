part of '../main.dart';

mixin _CollectionValuePresentation on State<CollectionValuePage> {
  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    String? detail,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1A18).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(value, textAlign: TextAlign.center, style: TextStyle(color: accent, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ),
          if (detail != null) ...[
            const SizedBox(height: 5),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }


  Widget _sectionImageHeader(String asset, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 23, bottom: 11),
      child: Container(
        height: 116,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFD6B15E).withValues(alpha: 0.72), width: 1.1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(asset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF17130D))),
          DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.black.withValues(alpha: 0.10), Colors.transparent, Colors.black.withValues(alpha: 0.08)],
            ),
          )),
          // Titolo e sottotitolo sono già incorporati nell'immagine-banner.
          // Evita di sovrapporli una seconda volta.
        ]),
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 23, bottom: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFD6B15E).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6B15E).withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: const Color(0xFFE5C77A), size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Color(0xFFF1D994), fontWeight: FontWeight.w800, letterSpacing: 0.7, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171716).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8C713D).withValues(alpha: 0.42)),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _detailLine(String label, String value, {Color valueColor = Colors.white, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 10))),
        ])),
        const SizedBox(width: 10),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
