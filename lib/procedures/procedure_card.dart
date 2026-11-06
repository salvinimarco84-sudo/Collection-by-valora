import 'package:flutter/material.dart';
import 'procedure_registry.dart';

class ProcedureCard extends StatelessWidget {
  const ProcedureCard({
    super.key,
    required this.procedure,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.textPrimary,
    required this.textFaint,
    required this.neutralOverlay,
    required this.neutralOverlayStrong,
    required this.onTap,
  });

  final ProcedureEntry procedure;
  final String title;
  final String description;
  final Color accentColor;
  final Color textPrimary;
  final Color textFaint;
  final Color neutralOverlay;
  final Color neutralOverlayStrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.black.withValues(alpha: 0.20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: accentColor.withValues(alpha: 0.72), width: 1.1),
    ),
    child: ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      enabled: procedure.enabled,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: procedure.enabled
            ? accentColor.withValues(alpha: 0.18)
            : neutralOverlay,
        child: Icon(
          procedure.enabled
              ? (procedure.readOnly ? Icons.play_arrow : Icons.edit_outlined)
              : Icons.lock_outline,
          size: 18,
          color: procedure.enabled ? accentColor : textFaint,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: procedure.enabled ? textPrimary : textFaint,
        ),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 11.5)),
      trailing: Icon(
        procedure.enabled ? Icons.chevron_right : Icons.lock_outline,
        size: 18,
        color: procedure.enabled ? accentColor : neutralOverlayStrong,
      ),
      isThreeLine: true,
      onTap: onTap,
    ),
  );
}
