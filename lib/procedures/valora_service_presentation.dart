part of '../main.dart';

extension _ValoraServicePagePresentation on _ValoraServicePageState {
  Widget buildPage(BuildContext context) {
    final selected = _objects.where((o) => o['codice_oggetto'] == _selectedId).firstOrNull;
    final matches = _matchingObjects;
    return Scaffold(
      appBar: AppBar(title: Text(ValoraI18n.tr('VALORA'))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(18), children: [
          buildValoraIntroSection(),
          const SizedBox(height: 16),
          buildPhotoInputSection(context),
          const SizedBox(height: 18),
          buildCollectionSearchSection(selected: selected, matches: matches),
          buildMarketValuationSection(),
          buildValoraCatalogActionsSection(selected),
        ]),
    );
  }
}
