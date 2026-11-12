part of '../main.dart';

extension _Pr04PhotoController on _NewPurchasePageState {
  Future<void> _photoAndRecognize(_PurchaseItemDraft item) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) throw Exception('Foto vuota o superiore a 10 MB.');
      setState(() {
        item.photoBytes = bytes;
        item.photoName = picked.name.isNotEmpty ? picked.name : 'foto_acquisto.jpg';
        item.photoUrl = null;
        item.photoStatus = 'Foto acquisita. Riconoscimento PR-12 in corso…';
      });
      await _recognizeAndApplyPurchasePhoto(item, bytes);
    } catch (e) {
      if (mounted) setState(() => item.photoStatus = 'Riconoscimento non riuscito: $e');
    }
  }
}
