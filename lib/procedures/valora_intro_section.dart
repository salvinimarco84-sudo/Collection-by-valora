part of '../main.dart';

/// Intestazione e istruzioni iniziali dell'assistente VALORA.
extension _ValoraIntroPresentation on _ValoraServicePageState {
  Widget buildValoraIntroSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9B45B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9B45B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD9B45B), size: 34),
          const SizedBox(height: 8),
          const Text(
            'ASSISTENTE VALORA',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD9B45B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cerca un oggetto già presente nella tua collezione oppure inserisci foto dalla fotocamera, dalla galleria o file di riferimento. Le foto vengono utilizzate per il riconoscimento e la ricerca PR-12, non vengono salvate nella scheda. L’immagine definitiva dell’oggetto proviene dai metadati verificati.',
          ),
        ],
      ),
    );
  }
}
