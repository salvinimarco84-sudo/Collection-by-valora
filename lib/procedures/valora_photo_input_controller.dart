part of '../main.dart';

/// Gestione degli input fotografici di VALORA.
/// Fotocamera, galleria e file mantengono gli stessi callback e criteri di selezione.
extension _ValoraPhotoInputActions on _ValoraServicePageState {
    Future<void> _pickImage(ImageSource source) async {
      try {
        final picker = ImagePicker();
        if (source == ImageSource.gallery) {
          final images = await picker.pickMultiImage(imageQuality: 92);
          if (!mounted || images.isEmpty) return;
          setState(() {
            for (final image in images) {
              if (_selectedImages.every((item) => item.path != image.path)) {
                _selectedImages.add(image);
              }
            }
          });
        } else {
          final image = await picker.pickImage(source: source, imageQuality: 92);
          if (!mounted || image == null) return;
          setState(() => _selectedImages.add(image));
        }
      } catch (e) {
        if (mounted) setState(() => _error = 'Selezione immagine non riuscita: $e');
      }
    }
  
    Future<void> _pickFiles() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
        if (!mounted || result == null) return;
        setState(() {
          for (final file in result.files) {
            if (_selectedFiles.every((item) => item.name != file.name || item.size != file.size)) {
              _selectedFiles.add(file);
            }
          }
        });
      } catch (e) {
        if (mounted) setState(() => _error = 'Selezione file non riuscita: $e');
      }
    }
  
    void _removeImage(XFile image) => setState(() => _selectedImages.remove(image));
    void _removeFile(PlatformFile file) => setState(() => _selectedFiles.remove(file));
}

