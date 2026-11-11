part of '../main.dart';

extension _Pr04CategoryController on _NewPurchasePageState {
  Future<void> _loadCollectionCategories() async {
    _categoriesLoading = true;
    try {
      final rows = await Supabase.instance.client.schema('collection')
          .from('master_categorie_collezione')
          .select('codice_categoria, descrizione, ordine_menu, visibile')
          .eq('visibile', true)
          .order('ordine_menu')
          .order('descrizione');
      if (!mounted) return;
      setState(() => _collectionCategories = (rows as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList());
    } catch (e) {
      if (mounted) setState(() => _status = 'Errore caricamento categorie: $e');
    } finally {
      _categoriesLoading = false;
    }
  }
}
