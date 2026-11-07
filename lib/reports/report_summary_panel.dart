part of '../main.dart';

class ReportSummaryPanel extends StatelessWidget {
  const ReportSummaryPanel({
    super.key,
    required this.sectionColor,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Color sectionColor;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sectionColor.withValues(alpha: 0.55)),
      ),
      child: child,
    );
  }
}
