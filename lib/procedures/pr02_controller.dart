import 'package:flutter/material.dart';

/// Stato isolato della procedura PR-02.
class Pr02Controller {
  List<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[];
  bool showTechnicalTab = false;
  bool searchCompleted = false;
  final List<Map<String, dynamic>> pendingChanges = <Map<String, dynamic>>[];
  bool awaitingNextChoice = false;
  final ScrollController scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> pendingImages =
      <String, Map<String, dynamic>>{};

  void dispose() => scrollController.dispose();
}
