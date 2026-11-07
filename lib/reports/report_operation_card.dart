part of '../main.dart';

class ReportOperationCard extends StatelessWidget {
  const ReportOperationCard({
    super.key,
    required this.sectionColor,
    required this.showImage,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final Color sectionColor;
  final bool showImage;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.startsWith('https://') || imageUrl.startsWith('http://');
    return Card(
      child: ListTile(
        leading: showImage && hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _valoraImageProxyUrl(imageUrl),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.receipt_long_outlined, color: sectionColor),
                ),
              )
            : Icon(Icons.receipt_long_outlined, color: sectionColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailingText == null ? null : Text(trailingText!),
        onTap: onTap,
      ),
    );
  }
}
