part of '../main.dart';

/// Lettura del mercato principale configurato nel profilo autenticato.
Future<String> _fetchValoraUserPrimaryMarket() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw StateError('Accedi per leggere il mercato del profilo.');
  }

  final rows = await client
      .schema('collection')
      .from('master_utente')
      .select('mercato_nazionale_principale,mercati(nome_mercato)')
      .eq('auth_user_id', user.id)
      .limit(1);

  if (rows.isEmpty) {
    throw StateError('Completa il profilo e imposta il mercato principale.');
  }

  final row = Map<String, dynamic>.from(rows.first);
  final market = row['mercati'];
  final marketName =
      market is Map ? (market['nome_mercato'] ?? '').toString().trim() : '';

  if (row['mercato_nazionale_principale'] == null || marketName.isEmpty) {
    throw StateError('Il profilo non contiene un mercato principale valido.');
  }

  return marketName;
}
