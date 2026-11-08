part of '../main.dart';

class Pr04PurchasePhotoField extends StatelessWidget {
  const Pr04PurchasePhotoField({
    super.key,
    required this.busy,
    required this.photoUrl,
    required this.photoBytes,
    required this.photoStatus,
    required this.onPhoto,
  });

  final bool busy;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final String photoStatus;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: busy ? null : onPhoto,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('SCATTA FOTO · RICONOSCIMENTO PR-12'),
      ),
      if (photoUrl != null) Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _valoraImageProxyUrl(photoUrl!),
            height: 130,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => photoBytes != null
                ? Image.memory(photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain)
                : const Icon(Icons.broken_image_outlined),
          ),
        ),
      ) else if (photoBytes != null) Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain),
        ),
      ),
      Text(photoStatus, style: TextStyle(
        fontSize: 12,
        color: ValoraAppearance.instance.textSecondary,
      )),
    ],
  );
}
