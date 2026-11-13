import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../localization/valora_i18n.dart';
import '../themes/valora_theme.dart';

/// Presentazione indipendente del campo fotografico della maschera PR-01.
class Pr01ImageField extends StatelessWidget {
  const Pr01ImageField({
    super.key,
    required this.sectionColor,
    required this.selectedImageBytes,
    required this.existingImagePreview,
    required this.status,
    required this.loading,
    required this.onAssistant,
    required this.onGallery,
  });

  final Color sectionColor;
  final Uint8List? selectedImageBytes;
  final Widget? existingImagePreview;
  final String status;
  final bool loading;
  final VoidCallback onAssistant;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final hasSelected = selectedImageBytes != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: sectionColor, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ValoraI18n.tr('ASSISTENTE VALORA'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(
                'Scatta una foto: riconosco l’oggetto, cerco con PR-12 e compilo i campi disponibili. Poi controlli e completi tu.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 13),
              ),
            ])),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onAssistant,
              icon: loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.mic),
              label: Text(loading ? 'ASSISTENTE AL LAVORO…' : 'ASSISTENTE VALORA · SCATTA E CERCA'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (hasSelected) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(selectedImageBytes!, height: 180,
                  width: double.infinity, fit: BoxFit.contain),
            ),
          ] else if (existingImagePreview != null) ...[
            const SizedBox(height: 10),
            existingImagePreview!,
          ],
          const SizedBox(height: 8),
          Text(status, style: TextStyle(
            color: status.startsWith('Assistente non disponibile') ||
                    status.startsWith('Scatto')
                ? Colors.orangeAccent
                : ValoraAppearance.instance.textSecondary,
            fontSize: 12,
          )),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: loading ? null : onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Scegli invece una foto dalla galleria'),
            ),
          ),
        ]),
      ),
    );
  }
}
