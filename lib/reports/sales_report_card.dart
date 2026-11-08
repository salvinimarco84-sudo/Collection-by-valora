part of '../main.dart';

class SalesReportCard extends StatelessWidget {
  const SalesReportCard({super.key, required this.row, required this.amountLabel, this.imageUrl, this.onTap});
  final Map<String, dynamic> row;
  final String amountLabel;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('VENDITE');
    final objectCode = (row['codice_oggetto'] ?? row['id_oggetto'] ?? 'N/D').toString();
    final saleCode = (row['codice_vendita'] ?? row['codice_vendita_aperta'] ?? row['id_vendita'] ?? 'N/D').toString();
    final description = (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome_oggetto'] ?? row['titolo'] ?? 'Vendita senza descrizione').toString();
    final date = (row['data_vendita'] ?? row['data_chiusura'] ?? row['data'] ?? 'Data non indicata').toString();
    final validImage = imageUrl != null && (imageUrl!.startsWith('https://') || imageUrl!.startsWith('http://'));
    return Card(child: ListTile(
      contentPadding: const EdgeInsets.all(10),
      leading: validImage
          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_valoraImageProxyUrl(imageUrl!), width: 68, height: 68, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.receipt_long_outlined, color: color, size: 30)))
          : Icon(Icons.receipt_long_outlined, color: color, size: 30),
      title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Vendita #$saleCode · Oggetto #$objectCode\nData: $date'),
      isThreeLine: true,
      trailing: Text(amountLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    ));
  }
}
