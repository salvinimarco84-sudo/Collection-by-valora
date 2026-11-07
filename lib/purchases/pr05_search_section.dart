part of '../main.dart';

class Pr05PurchaseSearchSection extends StatelessWidget {
  const Pr05PurchaseSearchSection({
    super.key,
    required this.queryController,
    required this.busy,
    required this.found,
    required this.foundSummary,
    required this.onSearch,
    required this.onLoad,
  });

  final TextEditingController queryController;
  final bool busy;
  final List<Map<String, dynamic>> found;
  final String Function(Map<String, dynamic>) foundSummary;
  final VoidCallback onSearch;
  final ValueChanged<Map<String, dynamic>> onLoad;

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('ACQUISTI');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1 · CERCA ACQUISTO', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        TextField(
          controller: queryController,
          decoration: const InputDecoration(labelText: 'Codice acquisto o descrizione'),
          onSubmitted: (_) => onSearch(),
        ),
        FilledButton(
          onPressed: busy ? null : onSearch,
          child: const Text('CERCA'),
        ),
        for (final row in found)
          Card(
            child: ListTile(
              title: Text((row['descrizione_acquisto'] ?? row['descrizione'] ?? row['description'] ?? 'Acquisto').toString()),
              subtitle: Text(foundSummary(row)),
              trailing: const Icon(Icons.chevron_right),
              onTap: busy ? null : () => onLoad(row),
            ),
          ),
      ],
    );
  }
}
