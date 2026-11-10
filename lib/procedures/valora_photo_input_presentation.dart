part of '../main.dart';

extension _ValoraPhotoInputPresentation on _ValoraServicePageState {
  Widget _buildValoraPhotoInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text('FOTO E FILE', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Fotocamera')),
              OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galleria')),
              OutlinedButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('Scegli file')),
            ]),
            if (_selectedImages.isNotEmpty || _selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _analyzingPhotos ? null : _analyzeSelectedPhotos,
                icon: _analyzingPhotos ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
                label: Text(_analyzingPhotos ? 'RICERCA FOTO IN CORSO…' : 'USA LE FOTO PER LA RICERCA PR-12'),
              ),
              SizedBox(height: 112, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(image.path), width: 100, height: 100, fit: BoxFit.contain)),
                    Positioned(right: 0, top: 0, child: IconButton.filledTonal(onPressed: () => _removeImage(image), icon: const Icon(Icons.close, size: 16))),
                  ]);
                },
              )),
            ],
            if (_selectedFiles.isNotEmpty) ..._selectedFiles.map((file) => ListTile(
              dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.attach_file),
              title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(onPressed: () => _removeFile(file), icon: const Icon(Icons.close)),
            )),
  
      ],
    );
  }
}
