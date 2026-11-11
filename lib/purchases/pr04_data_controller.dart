part of '../main.dart';

extension _Pr04DataController on _NewPurchasePageState {
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'DATA DELL’ACQUISTO',
      cancelText: 'ANNULLA',
      confirmText: 'CONFERMA DATA',
    );
    if (d != null && mounted) {
      setState(() {
        _date = d;
        _invalidate();
      });
    }
  }
}
