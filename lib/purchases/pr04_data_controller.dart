part of '../main.dart';

extension _Pr04DataController on _NewPurchasePageState {
  String? _nonEmptyMetadata(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<void> _loadCollectionCategories() async {
    _categoriesLoading = true;
    try {
      final rows = await Supabase.instance.client.schema('collection').from('master_categorie_collezione')
          .select('codice_categoria, descrizione, ordine_menu, visibile').eq('visibile', true)
          .order('ordine_menu').order('descrizione');
      if (!mounted) return;
      setState(() => _collectionCategories = (rows as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) { if (mounted) setState(() => _status = 'Errore caricamento categorie: $e'); }
    finally { _categoriesLoading = false; }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)), helpText: 'DATA DELL’ACQUISTO',
      cancelText: 'ANNULLA', confirmText: 'CONFERMA DATA');
    if (d != null && mounted) setState(() { _date = d; _invalidate(); });
  }

}
