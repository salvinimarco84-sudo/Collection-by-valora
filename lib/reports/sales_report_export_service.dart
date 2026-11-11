part of '../main.dart';

class SalesReportExportService {
  static Future<String?> createAndSave({
    required List<Map<String, dynamic>> rows,
    required bool pdf,
    required Map<String, String> period,
    required double Function(Map<String, dynamic>) amount,
    required String Function(dynamic) money,
  }) async {
    if (rows.isEmpty) throw Exception('Non ci sono vendite da esportare.');
    final headers = <String>[];
    for (final row in rows) { for (final key in row.keys) { if (!headers.contains(key)) headers.add(key); } }
    String cell(dynamic value) => value == null ? '' : value is Map || value is List ? jsonEncode(value) : value.toString();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final name = 'VALORA_REPORT_SALES_$stamp';
    late Uint8List bytes;
    final extension = pdf ? 'pdf' : 'xlsx';
    if (pdf) {
      final document = pw.Document();
      document.addPage(pw.MultiPage(
        pageFormat: pw_core.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text('COLLECTION by VALORA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('REPORT VENDITE · ${period['data_da']} / ${period['data_a']}'),
          pw.Text('Vendite: ${rows.length} · Totale: ${money(rows.fold<double>(0, (sum, row) => sum + amount(row)))}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            data: [headers, ...rows.map((row) => headers.map((key) => cell(row[key])).toList())],
            headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 6),
            headerDecoration: const pw.BoxDecoration(color: pw_core.PdfColor.fromInt(0xFFD6B15E)),
            cellAlignment: pw.Alignment.topLeft,
            border: pw.TableBorder.all(color: pw_core.PdfColor.fromInt(0xFFBBBBBB), width: 0.35),
          ),
        ],
      ));
      bytes = Uint8List.fromList(await document.save());
    } else {
      final workbook = xlsx.Excel.createExcel();
      final sheet = workbook['Vendite'];
      sheet.appendRow(headers.map((key) => xlsx.TextCellValue(key)).toList());
      for (final row in rows) { sheet.appendRow(headers.map((key) => xlsx.TextCellValue(cell(row[key]))).toList()); }
      final encoded = workbook.encode();
      if (encoded == null) throw Exception('Creazione Excel non riuscita.');
      bytes = Uint8List.fromList(encoded);
    }
    return FilePicker.platform.saveFile(
      dialogTitle: pdf ? 'Salva report PDF' : 'Salva report Excel',
      fileName: '$name.$extension', type: FileType.custom, allowedExtensions: [extension], bytes: bytes,
    );
  }
}
