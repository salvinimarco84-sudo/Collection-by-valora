part of '../main.dart';

/// Composizione della schermata dedicata PR-02.
extension _Pr02PageWorkflow on _ObjectRuntimePageState {
  Widget _buildPr02Page() {
    return Pr02Page(
      sectionColor: sectionColor,
      userLabel: Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata',
      lockHeld: _lockHeld,
      status: _output,
      scrollController: _pr02ScrollController,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1 · CERCA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _search,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(_searchPr02Objects),
                    decoration: InputDecoration(
                      labelText: 'Codice oggetto o descrizione',
                      hintText: 'Codice esatto o parte della descrizione',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Cerca',
                        onPressed: _loading ? null : () => _run(_searchPr02Objects),
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_pr02SearchCompleted && _pr02SearchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Nessun risultato. Verifica il codice o prova una descrizione più breve.'),
                    ),
                  if (_pr02SearchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Risultati: ${_pr02SearchResults.length}. Tocca il record da modificare.'),
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
                  'Blocco provvisorio: ${_pr02PendingChanges.length} oggetti confermati',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_currentObject != null && !_pr02AwaitingNextChoice) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2 · DATI OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _pr02MetadataCard(_currentObject!),
                    if (_destination == 'COLLEZIONE') _collectionCategoryField(),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('SCHEDA OGGETTO'), icon: Icon(Icons.edit_note)),
                        ButtonSegment(value: true, label: Text('DATI TECNICI'), icon: Icon(Icons.info_outline)),
                      ],
                      selected: {_showPr02TechnicalTab},
                      onSelectionChanged: (value) => setState(() => _showPr02TechnicalTab = value.first),
                    ),
                    const SizedBox(height: 10),
                    if (_showPr02TechnicalTab)
                      _pr02TechnicalCard(_currentObject!)
                    else
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
                              const SizedBox(width: 12),
                              Expanded(child: _pr02Side(oldValues: false)),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : () => _run(_confirmPr02Changes),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('CONFERMA DATI E AGGIUNGI AL BLOCCO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_pr02AwaitingNextChoice)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3 · MODIFICA CONFERMATA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Ultima modifica salvata e verificata. Modifiche in attesa: ${_pr02PendingChanges.length}.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _continuePr02WithAnotherObject,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('SÌ, MODIFICA UN ALTRO OGGETTO'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('NO, TERMINA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
