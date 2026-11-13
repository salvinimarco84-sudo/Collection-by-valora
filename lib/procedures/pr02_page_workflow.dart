part of '../main.dart';

/// Composizione della schermata dedicata PR-02.
extension _Pr02PageWorkflow on _ObjectRuntimePageState {
  Widget _buildPr02Page() {
    return Pr02Page(
      sectionColor: sectionColor,
      userLabel: Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata',
      lockHeld: _lockHeld,
      loading: _loading,
      status: _output,
      scrollController: _pr02ScrollController,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RICERCA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _search,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(_searchPr02Objects),
                    decoration: InputDecoration(
                      labelText: 'Parola, parte della descrizione o codice',
                      hintText: 'Es. Batman',
                      suffixIcon: IconButton(
                        tooltip: 'Cerca',
                        onPressed: _loading ? null : () => _run(_searchPr02Objects),
                        icon: Icon(Icons.search, color: sectionColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La ricerca trova i record contenenti il termine, senza distinzione tra maiuscole e minuscole.',
                    style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12),
                  ),
                  if (_pr02SearchCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _pr02SearchResults.isEmpty
                            ? 'Nessun risultato trovato.'
                            : 'Risultati mostrati: ${_pr02SearchResults.length}',
                        style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12),
                      ),
                    ),
                  if (_pr02SearchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._pr02SearchResults.map((item) => Card(
                      margin: const EdgeInsets.only(top: 6),
                      child: ListTile(
                        title: Text('${item['codice_oggetto'] ?? ''} · ${item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome'] ?? 'Senza descrizione'}'),
                        subtitle: Text('Stato: ${item['stato'] ?? 'Non indicato'}'),
                        trailing: const Icon(Icons.chevron_right),
                        selected: _currentObject?['codice_oggetto']?.toString() == item['codice_oggetto']?.toString(),
                        onTap: _loading ? null : () => _run(() => _selectPr02Object(item)),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          if (_pr02PendingChanges.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Modifiche confermate: ${_pr02PendingChanges.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_currentObject != null) ...[
            const SizedBox(height: 12),
            _pr02MetadataCard(_currentObject!),
            if (_destination == 'COLLEZIONE')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _collectionCategoryField(),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: !_showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                          foregroundColor: !_showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                        ),
                        onPressed: () => setState(() => _showPr02TechnicalTab = false),
                        child: const Text('SCHEDA OGGETTO'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                          foregroundColor: _showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                        ),
                        onPressed: () => setState(() => _showPr02TechnicalTab = true),
                        child: const Text('DATI TECNICI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_showPr02TechnicalTab)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 620) {
                    return Column(
                      children: [
                        _pr02Side(oldValues: true),
                        _pr02Side(oldValues: false),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _pr02Side(oldValues: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _pr02Side(oldValues: false)),
                    ],
                  );
                },
              )
            else
              _pr02TechnicalCard(_currentObject!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : () => _run(_confirmPr02Changes),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('CONFERMA DATI'),
            ),
          ],
        ],
      ),
    );
  }
}
