part of '../main.dart';

class ReportPaginationControls extends StatelessWidget {
  const ReportPaginationControls({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.pageCount,
    required this.textColor,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int pageCount;
  final Color textColor;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final firstItem = currentPage * pageSize + 1;
    final lastItem = ((currentPage + 1) * pageSize) > totalItems
        ? totalItems
        : (currentPage + 1) * pageSize;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          IconButton(
            tooltip: 'Gruppo precedente',
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          Expanded(child: Text(
            '$firstItem–$lastItem di $totalItems · Gruppo ${currentPage + 1}/$pageCount',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          )),
          IconButton(
            tooltip: 'Gruppo successivo',
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ]),
      ),
    );
  }
}
