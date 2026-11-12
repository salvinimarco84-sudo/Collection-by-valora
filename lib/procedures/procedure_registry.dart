import 'package:flutter/material.dart';
import '../themes/valora_theme.dart';

class DashboardSection {
  const DashboardSection({required this.title, required this.description,
    required this.icon, required this.color, this.menuTitle});
  final String title;
  final String? menuTitle;
  final String description;
  final IconData icon;
  final Color color;
}

const List<DashboardSection> dashboardSections = [
  DashboardSection(title: 'CATALOGO', description: 'Consulta e gestisci gli oggetti', icon: Icons.inventory_2_outlined, color: Color(0xFF3978C5)),
  DashboardSection(title: 'WANTED LIST', description: 'Gestisci desideri, obiettivi di acquisto, offerte e storico.', icon: Icons.bookmark_outline, color: Color(0xFFB8BEC6)),
  DashboardSection(title: 'ACQUISTI', description: 'Gestione acquisti e allocazioni', icon: Icons.shopping_cart_outlined, color: Color(0xFFC74444)),
  DashboardSection(title: 'VENDITE', menuTitle: 'VENDITE E INSERZIONI', description: 'Vendite e inserzioni', icon: Icons.sell_outlined, color: Color(0xFF39875B)),
  DashboardSection(title: 'VALUTAZIONI', description: 'VALORA e valore collezione', icon: Icons.query_stats, color: Color(0xFF8556C7)),
  DashboardSection(title: 'REPORT', description: 'Riepiloghi e risultati', icon: Icons.analytics_outlined, color: Color(0xFFE17D35)),
  DashboardSection(title: 'RICERCHE', description: 'Ricerca oggetti e fonti', icon: Icons.search, color: Color(0xFFD6A83F)),
  DashboardSection(title: 'CONTROLLO', description: 'Stato e verifiche del sistema', icon: Icons.admin_panel_settings_outlined, color: Color(0xFF777777)),
];

class ProcedureEntry {
  const ProcedureEntry({required this.title, required this.description,
    this.apiCode, this.readOnly = true, this.enabled = true});
  final String title;
  final String description;
  final String? apiCode;
  final bool readOnly;
  final bool enabled;
}

const Map<String, List<ProcedureEntry>> sectionProcedures = {
  'WANTED LIST': [
    ProcedureEntry(title: 'NUOVO DESIDERIO', description: 'Inserisci un oggetto che desideri acquistare.', apiCode: 'WANTED-NEW', readOnly: false),
    ProcedureEntry(title: 'LISTA DEI DESIDERI', description: 'Consulta gli oggetti ancora da acquistare.', apiCode: 'WANTED-ACTIVE'),
    ProcedureEntry(title: 'OBIETTIVI DI ACQUISTO', description: 'Organizza gli obiettivi per tema e priorità, senza dati economici.', apiCode: 'WANTED-GOALS', readOnly: false),
    ProcedureEntry(title: 'ACQUISTO WANTED LIST', description: 'Avvia l’acquisto del desiderio tramite la procedura PR-04.', apiCode: 'WANTED-PURCHASE', readOnly: false),
    ProcedureEntry(title: 'RICERCA OFFERTE', description: 'Usa PR-12 per cercare offerte sul desiderio selezionato e salvare i candidati da verificare.', apiCode: 'WANTED-OFFERS'),
    ProcedureEntry(title: 'STORICO WANTED LIST', description: 'Consulta desideri conclusi, offerte salvate e collegamento agli oggetti acquistati.', apiCode: 'WANTED-HISTORY'),
  ],
  'CATALOGO': [
    ProcedureEntry(title: 'Nuovo oggetto', description: 'Crea un oggetto e prepara i metadati per la ricerca.', apiCode: 'PR-01', readOnly: false),
    ProcedureEntry(title: 'Modifica oggetto', description: 'Carica la scheda completa prima di modificarla.', apiCode: 'PR-02', readOnly: false),
    ProcedureEntry(title: 'Chiudi oggetto', description: 'Registra la chiusura con motivazione.', apiCode: 'PR-03', readOnly: false),
    ProcedureEntry(title: 'Visualizza scheda', description: 'Mostra la scheda completa in formato leggibile.', apiCode: 'OBJECT_MASTER'),
    ProcedureEntry(title: 'Elenco oggetti disponibili', description: 'Mostra gli oggetti con stato DISPONIBILE.', apiCode: 'OBJECTS_AVAILABLE'),
    ProcedureEntry(title: 'Storico oggetto', description: 'Mostra la cronologia del singolo oggetto selezionato.', apiCode: 'EXPLORE_RECORDS'),

    ProcedureEntry(title: 'Importa oggetti', description: 'Importa record da CSV o JSON con anteprima e controllo duplicati.', apiCode: 'OBJECT-IMPORT'),
    ProcedureEntry(title: 'Esporta oggetti', description: 'Esporta il catalogo in CSV o JSON.', apiCode: 'OBJECT-EXPORT'),
  ],
  'ACQUISTI': [
    ProcedureEntry(title: 'Nuovo acquisto', description: 'Registra un nuovo acquisto.', apiCode: 'WRITE-PR-04', readOnly: false),
    ProcedureEntry(title: 'Modifica acquisto', description: 'Modifica un acquisto esistente.', apiCode: 'WRITE-PR-05', readOnly: false),
    ProcedureEntry(title: 'Acquisti comparati', description: 'Confronta i prezzi pagati per lo stesso prodotto, con minimo, massimo, media e storico degli acquisti.', apiCode: 'PURCHASES-COMPARE'),
    ProcedureEntry(title: 'Report acquisti', description: 'Riepilogo degli acquisti registrati.', apiCode: 'REPORT-PURCHASES'),
  ],
  'VENDITE': [
    ProcedureEntry(title: 'Nuova vendita', description: 'Registra una nuova vendita nel database VALORA.', apiCode: 'WRITE-PR-06', readOnly: false),
    ProcedureEntry(title: 'Modifica vendita', description: 'Seleziona una vendita ancora aperta e modifica data iniziale, prezzo richiesto, piattaforme o note con anteprima e conferma finale.', apiCode: 'WRITE-PR-07', readOnly: false),
    ProcedureEntry(title: 'Chiudi vendita', description: 'Seleziona una vendita attiva e registra la chiusura.', apiCode: 'WRITE-PR-08', readOnly: false),
    ProcedureEntry(title: 'Annulla vendita', description: 'Annulla una vendita conclusa, compensa l’incasso in cassa e rimette l’oggetto in vendita oppure in collezione.', apiCode: 'WRITE-PR-09', readOnly: false),
    ProcedureEntry(title: 'Report vendite attive', description: 'Consulta le vendite ancora aperte e non concluse.', apiCode: 'REPORT-ACTIVE-LISTINGS'),
    ProcedureEntry(title: 'Report vendite', description: 'Riepilogo delle vendite registrate in VALORA.', apiCode: 'REPORT-SALES'),
    ProcedureEntry(title: 'Bozze inserzioni VALORA', description: 'Consulta e modifica le bozze create per le piattaforme selezionate nelle vendite VALORA.', apiCode: 'VALORA-LISTING-DRAFTS'),
  ],
  'VALUTAZIONI': [
    ProcedureEntry(title: 'PR-11 · VALUTAZIONE COMPLESSIVA COLLEZIONE', description: 'Valuta il patrimonio complessivo a lotti e registra lo storico dei valori.', apiCode: 'LAUNCH-COLLECTION-VALUE'),
    ProcedureEntry(title: 'PR-13 · RICERCA OFFERTA', description: 'Analizza una specifica offerta d’acquisto, identifica l’oggetto tramite PR-12 e valuta la convenienza economica. Procedura in preparazione.', enabled: false),
    ProcedureEntry(title: 'PR-14 · ASSISTENTE VALORA', description: 'PR-14 coordina due percorsi: per gli oggetti già in collezione richiama PR-18 e, su scelta dell’utente, PR-06 VALORA; per gli oggetti non ancora in collezione richiama PR-12, poi PR-18 e, su scelta dell’utente, PR-04 VALORA. Le procedure ordinarie PR-04 e PR-06 restano indipendenti.', apiCode: 'LAUNCH-VALORA'),
  ],
  'FLUSSI DI CASSA': [
  ],
  'REPORT': [
    ProcedureEntry(title: 'Report per franchise / tema', description: 'Cerca in tutto il catalogo per descrizione, categoria collezionistica, tema e sottotema; esporta tutti i risultati.', apiCode: 'REPORT-COLLECTION-THEME'),
    ProcedureEntry(title: 'Flussi di cassa', description: 'Consulta entrate, uscite e saldo del periodo selezionato.', apiCode: 'REPORT-CASH'),
    ProcedureEntry(title: 'Report mattutino', description: 'Riepilogo operativo del mattino.', enabled: false),
  ],
  'RICERCHE': [
    ProcedureEntry(title: 'PR-21 · Ricerca schede', description: 'Ricerca le schede degli oggetti disponibili destinati alla collezione, per codice o descrizione. Consultazione in sola lettura.', apiCode: 'PR-21-SEARCH', readOnly: true),
    ProcedureEntry(title: 'PR-12 · Ricerca metadati in lotti', description: 'Analizza fino a 10 oggetti incompleti per lotto, mostra fonti e risultati senza modificare il database.', apiCode: 'PR-12-BATCH', readOnly: true),
    ProcedureEntry(title: 'REGISTRO FONTI · Gestisci cataloghi e siti', description: 'Consulta le fonti iniziali e aggiungi fonti specialistiche della tua nicchia collezionistica.', apiCode: 'SOURCE-REGISTRY', readOnly: false),
    ProcedureEntry(title: 'Le mie piattaforme di vendita', description: 'Aggiungi solo le piattaforme che utilizzi e attiva o disattiva ciascuna destinazione per le inserzioni VALORA.', apiCode: 'USER-SALES-PLATFORMS', readOnly: false),
  ],
  'CONTROLLO': [
    ProcedureEntry(title: 'Stato runtime', description: 'Verifica lo stato del servizio runtime.', apiCode: 'RUNTIME-HEALTH'),
    ProcedureEntry(title: 'Catalogo API', description: 'Consulta il catalogo delle API runtime.', apiCode: 'RUNTIME-CATALOG'),
    ProcedureEntry(title: 'Pulizia file', description: 'Operazione non disponibile nell’app runtime.', enabled: false),
    ProcedureEntry(title: 'CREA CATEGORIA COLLEZIONE', description: 'Crea una nuova categoria per organizzare gli oggetti della tua collezione.', apiCode: 'CREATE-COLLECTION-CATEGORY', readOnly: false),
    ProcedureEntry(title: 'MODIFICA CATEGORIA COLLEZIONE', description: 'Modifica descrizione, logo, colore e visibilità delle categorie esistenti.', apiCode: 'EDIT-COLLECTION-CATEGORY', readOnly: false),
  ],
};

Color sectionColorForApiCode(String apiCode) {
  for (final section in dashboardSections) {
    final procedures = sectionProcedures[section.title] ?? const <ProcedureEntry>[];
    if (procedures.any((procedure) => procedure.apiCode == apiCode)) {
      return ValoraAppearance.instance.colorFor(section.title);
    }
  }
  return const Color(0xFFD6B15E);
}

