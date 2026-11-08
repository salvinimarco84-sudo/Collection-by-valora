part of '../main.dart';

class ActiveSaleReportCard extends StatelessWidget {
  const ActiveSaleReportCard({
    super.key,
    required this.row,
    required this.amountLabel,
    this.imageUrl,
    this.onTap,
  });

  final Map<String, dynamic> row;
  final String amountLabel;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('VENDITE');
    final objectCode = (row['codice_oggetto'] ?? row['id_oggetto'] ?? 'N/D').toString();
    final saleCode = (row['codice_vendita_aperta'] ?? row['codice_vendita'] ?? 'N/D').toString();
    final description = (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome_oggetto'] ?? 'Oggetto senza descrizione').toString();
    final date = (row['data_inizio_vendita'] ?? row['data_apertura'] ?? row['data'] ?? 'Data non indicata').toString();
    final platform = (row['piattaforme_report'] ?? row['nome_piattaforma'] ?? 'Non indicata').toString();
    final validImage = imageUrl != null && (imageUrl!.startsWith('https://') || imageUrl!.startsWith('http://'));
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: validImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_valoraImageProxyUrl(imageUrl!), width: 68, height: 68, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: color, size: 30)),
              )
            : Icon(Icons.inventory_2_outlined, color: color, size: 30),
        title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text('Vendita #$saleCode · Oggetto #$objectCode\nAperta: $date\nPiattaforma: $platform'),
        ),
        isThreeLine: true,
        trailing: Text(amountLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }
}
