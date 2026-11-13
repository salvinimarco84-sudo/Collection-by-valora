part of '../main.dart';

/// Presentazione dedicata della procedura PR-03: ricerca, coda e conferma.
extension _Pr03ClosurePresentation on _ObjectRuntimePageState {
  List<Widget> _buildPr03ClosureSection() => [
    _field(_search, 'Cerca oggetto per descrizione o codice'),
    FilledButton.icon(
      onPressed: _loading ? null : () => _run(_searchPr02Objects),
      icon: const Icon(Icons.search),
      label: const Text('CERCA E SELEZIONA OGGETTO'),
    ),
    if (_pr03PendingClosures.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chiusure confermate in attesa: ${_pr03PendingClosures.length}',
          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold),
        ),
      ),
    if (_currentObject != null) ...[
      _dropdown(
        'Motivo chiusura',
        _closeReason,
        const ['SMARRITO', 'DISTRUTTO', 'DATO VIA'],
        (value) => setState(() => _closeReason = value!),
      ),
      _field(_notes, 'Note', lines: 2),
      FilledButton.icon(
        onPressed: _loading ? null : () => _run(_confirmPr03Closure),
        icon: const Icon(Icons.verified_outlined),
        label: const Text('CONFERMA CHIUSURA'),
      ),
    ],
  ];
}
