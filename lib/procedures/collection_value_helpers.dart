part of '../main.dart';

extension _CollectionValueHelpers on _CollectionValuePageState {
    List<Map<String, dynamic>> _maps(dynamic value) =>
        (value as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  
    Future<List<Map<String, dynamic>>> _readAll(String table, String columns) async {
      final all = <Map<String, dynamic>>[];
      for (var offset = 0; offset < 100000; offset += 1000) {
        final page = await Supabase.instance.client.schema('collection')
            .from(table).select(columns).range(offset, offset + 999);
        final rows = _maps(page);
        all.addAll(rows);
        if (rows.length < 1000) break;
      }
      return all;
    }
  
    double? _num(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.'));
    }
  
    int? _id(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse((value ?? '').toString());
    }
  
    String _eur(double value) {
      final fixed = value.abs().toStringAsFixed(2).split('.');
      final grouped = fixed[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
      return '${value < 0 ? '-' : ''}€ $grouped,${fixed[1]}';
    }
  
    String _date(dynamic value) {
      final parsed = value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
      if (parsed == null) return 'Data non disponibile';
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    }
  
    bool _excludedState(dynamic value) {
      final state = (value ?? '').toString().trim().toUpperCase();
      return const {'USCITO', 'VENDUTO', 'PERSO', 'DISTRUTTO', 'ACCORPATO'}.contains(state);
    }
  
    bool _isEuro(dynamic value) {
      final currency = (value ?? 'EUR').toString().trim().toUpperCase();
      return currency.isEmpty || currency == 'EUR' || currency == '€';
    }
}
