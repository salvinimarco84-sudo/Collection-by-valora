part of '../main.dart';

/// Accessori di stato PR-02 delegati al controller dedicato.
extension _Pr02ControllerBindings on _ObjectRuntimePageState {
  List<Map<String, dynamic>> get _pr02SearchResults =>
      _pr02Controller.searchResults;
  set _pr02SearchResults(List<Map<String, dynamic>> value) =>
      _pr02Controller.searchResults = value;

  bool get _showPr02TechnicalTab => _pr02Controller.showTechnicalTab;
  set _showPr02TechnicalTab(bool value) =>
      _pr02Controller.showTechnicalTab = value;

  bool get _pr02SearchCompleted => _pr02Controller.searchCompleted;
  set _pr02SearchCompleted(bool value) =>
      _pr02Controller.searchCompleted = value;

  List<Map<String, dynamic>> get _pr02PendingChanges =>
      _pr02Controller.pendingChanges;

  bool get _pr02AwaitingNextChoice =>
      _pr02Controller.awaitingNextChoice;
  set _pr02AwaitingNextChoice(bool value) =>
      _pr02Controller.awaitingNextChoice = value;

  ScrollController get _pr02ScrollController =>
      _pr02Controller.scrollController;

  Map<String, Map<String, dynamic>> get _pr02PendingImages =>
      _pr02Controller.pendingImages;
}
