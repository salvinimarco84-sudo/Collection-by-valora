part of '../main.dart';

extension _Pr04WantedLinkController on _NewPurchasePageState {
  Future<void> _completeWantedPurchaseLink() async {
    final wantedId = widget.wantedDesireId;
    final purchaseCode = _wantedPurchaseCode;
    if (wantedId == null || purchaseCode == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Sessione utente non valida per collegare il desiderio.');
    final db = Supabase.instance.client.schema('collection');
    final linkedRows = await db.from('acquisti_oggetti')
        .select('codice_oggetto')
        .eq('codice_acquisto', purchaseCode);
    final rows = (linkedRows as List).whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row)).toList();
    if (rows.length != 1) {
      throw StateError('Acquisto $purchaseCode verificato, ma il collegamento restituisce ${rows.length} oggetti invece di uno. Il desiderio resta attivo.');
    }
    final objectCode = int.tryParse((rows.single['codice_oggetto'] ?? '').toString());
    if (objectCode == null || objectCode <= 0) {
      throw StateError('Codice oggetto non valido per l’acquisto $purchaseCode. Il desiderio resta attivo.');
    }
    final updated = await db.from('wanted_desideri').update({
      'stato': 'ACQUISTATO',
      'codice_oggetto_acquistato': objectCode,
      'data_chiusura': DateTime.now().toUtc().toIso8601String(),
      'data_aggiornamento': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', wantedId).eq('user_id', user.id).eq('stato', 'ATTIVO')
      .select('id,stato,codice_oggetto_acquistato').maybeSingle();
    if (updated == null ||
        updated['stato'] != 'ACQUISTATO' ||
        int.tryParse((updated['codice_oggetto_acquistato'] ?? '').toString()) != objectCode) {
      throw StateError('Acquisto $purchaseCode salvato, ma il desiderio non è stato chiuso e verificato. Usa nuovamente CONFERMA COLLEGAMENTO, senza ripetere PR-04.');
    }
  }
}
