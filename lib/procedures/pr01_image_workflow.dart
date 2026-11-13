part of '../main.dart';

/// Flusso completo delle immagini PR-01: acquisizione, assistente PR-12,
/// presentazione, upload/registrazione e recupero delle immagini esistenti.
extension _Pr01ImageWorkflow on _ObjectRuntimePageState {
  Future<void> _pickImageFile() async {
    try {
      final selection = await _pr01ImageManager.pickFromGallery();
      if (selection == null) return;
      setState(() {
        _selectedImageBytes = selection.bytes;
        _selectedImageName = selection.fileName;
        _imageAcquisition = selection.acquisition;
        _imageStatus = 'Immagine pronta: ${selection.fileName}. Verrà associata dopo il salvataggio.';
      });
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Caricamento immagine non riuscito: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      final selection = await _pr01ImageManager.capturePhoto();
      if (selection == null) return;
      setState(() {
        _selectedImageBytes = selection.bytes;
        _selectedImageName = selection.fileName;
        _imageAcquisition = selection.acquisition;
        _imageStatus = 'Foto pronta. Avvia il riconoscimento per passare a PR-12.';
      });
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Scatto foto non riuscito: $e');
    }
  }

  Future<void> _startAssistantPhoto() async {
    if (_loading) return;
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _imageStatus = 'Apro la fotocamera…';
    });
    await _captureImage();
    if (!mounted) return;
    if (_selectedImageBytes == null || _selectedImageBytes!.isEmpty) {
      setState(() => _imageStatus = 'Nessuna foto acquisita. Premi ASSISTENTE VALORA per riprovare.');
      return;
    }
    await _recognizeSelectedPhoto();
  }

  Future<void> _recognizeSelectedPhoto() async {
    final bytes = _selectedImageBytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scatta prima una foto dell’oggetto.')));
      return;
    }
    setState(() { _loading = true; _imageStatus = 'Sto riconoscendo l’oggetto e cercando fonti con PR-12…'; });
    try {
      final recognition = await _pr01ImageManager.recognize(
        bytes: bytes,
        fileName: _selectedImageName,
      );
      final clues = recognition['identificazione'] as Map<String, dynamic>;
      final results = recognition['risultati'] as List<Map<String, dynamic>>;
      if (!mounted) return;
      final description = (clues['descrizione_provvisoria'] ?? '').toString().trim();
      final maker = (clues['marchio'] ?? '').toString().trim();
      final code = (clues['codice_prodotto'] ?? '').toString().trim();
      final category = (clues['categoria'] ?? '').toString().trim();
      setState(() {
        if (description.isNotEmpty) _description.text = description;
        if (maker.isNotEmpty) _producer.text = maker;
        if (code.isNotEmpty) _family.text = code;
        if (category.isNotEmpty) _line.text = category;
        if (_description.text.trim().isEmpty && results.isNotEmpty) {
          final title = (results.first['title'] ?? '').toString().trim();
          if (title.isNotEmpty) _description.text = title;
        }
        _metadataSearchExecuted = true;
        _metadataResult = results.isEmpty
          ? 'Riconoscimento completato. Nessuna corrispondenza online affidabile: verifica e completa i dati.'
          : 'Riconoscimento completato. PR-12 ha trovato ${results.length} risultati da verificare.';
        final uncertainty = clues['incertezze'] is List ? (clues['incertezze'] as List).join(' · ') : '';
        _imageStatus = 'Assistente VALORA: campi compilati con le informazioni disponibili. ${uncertainty.isNotEmpty ? "Da verificare: $uncertainty. " : ""}Controlla i dati prima di salvare.';
      });
      if (mounted) {
        final details = <String>[
          if (description.isNotEmpty) 'Descrizione',
          if (maker.isNotEmpty) 'Marca',
          if (code.isNotEmpty) 'Codice prodotto',
          if (category.isNotEmpty) 'Categoria',
        ];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(details.isEmpty
            ? 'Ricerca terminata. Completa manualmente i campi non riconosciuti.'
            : 'Maschera compilata: ${details.join(", ")}. Verifica i risultati PR-12 e completa il record.'),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Assistente non disponibile: $e. Puoi comunque compilare la maschera manualmente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _imageField() {
    final imageUrl = _existingImageUrl;
    final existingPreview = imageUrl != null && imageUrl.startsWith('http')
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _valoraImageProxyUrl(imageUrl),
              height: 160,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _imagePlaceholder(size: 100),
            ),
          )
        : null;
    return Pr01ImageField(
      sectionColor: sectionColor,
      selectedImageBytes: _selectedImageBytes,
      existingImagePreview: existingPreview,
      status: _imageStatus,
      loading: _loading,
      onAssistant: _startAssistantPhoto,
      onGallery: _pickImageFile,
    );
  }

  Widget _readOnlyImageCard() {
    final imageUrl = _existingImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('IMMAGINE OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (imageUrl != null && imageUrl.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _valoraImageProxyUrl(imageUrl),
                width: double.infinity,
                height: 240,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : SizedBox(height: 180, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes == null ? null : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!))),
                errorBuilder: (_, __, ___) => Column(children: [
                  Icon(Icons.broken_image_outlined, size: 42, color: ValoraAppearance.instance.textFaint),
                  const SizedBox(height: 6),
                  Text('Immagine registrata, ma anteprima non disponibile.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                ]),
              ),
            )
          else
            Row(children: [
              Icon(Icons.image_outlined, size: 30, color: ValoraAppearance.instance.textFaint),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _imageStatus == 'Verifica immagine associata…' ? 'Caricamento immagine…' :
                _imageStatus == 'Immagine già associata all’oggetto.' ? 'Immagine associata, ma URL non disponibile.' :
                'Nessuna immagine associata a questo oggetto.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary),
              )),
            ]),
        ]),
      ),
    );
  }

  Future<String> _uploadAndRegisterImage({
    required int objectId, required Uint8List bytes, required String fileName,
    required String acquisition, required String procedure,
  }) {
    return _pr01ImageManager.uploadAndRegister(
      objectId: objectId,
      bytes: bytes,
      fileName: fileName,
      acquisition: acquisition,
      procedure: procedure,
    );
  }

  Future<void> _loadExistingImage(int objectId) async {
    final imageUrl = await _pr01ImageManager.loadExistingImage(objectId);
    if (!mounted || _loadedObjectId != objectId) return;
    setState(() {
      _existingImageUrl = imageUrl;
      _imageStatus = imageUrl != null
          ? 'Immagine associata alla scheda.'
          : 'Nessuna immagine associata a questo oggetto.';
    });
  }
}
