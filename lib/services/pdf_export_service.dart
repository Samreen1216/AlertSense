import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/alert_event.dart';

/// Production-grade PDF generator for AlertSense event history and incident reports.
/// Fulfills Proposal Section 3.6 (Alert History) & Section 5 (Recommended Tech Stack).
class PdfExportService {
  PdfExportService._();

  /// Resolve human-readable category label
  static String _resolveCategoryLabel(String raw) {
    try {
      return SoundCategory.values
          .firstWhere((c) => c.name.toLowerCase() == raw.toLowerCase())
          .label;
    } catch (_) {
      return raw;
    }
  }

  /// Builds the complete pw.Document with header, summary KPIs, tables, and footer.
  static pw.Document buildPdfDocument(List<AlertEvent> alerts) {
    final pdf = pw.Document(
      title: 'AlertSense Incident Report',
      author: 'AlertSense Assistive Technology',
      subject: 'Environmental Sound Awareness Event Log',
    );

    final totalAlerts = alerts.length;
    final highCount = alerts.where((a) => a.priorityLevel.toLowerCase() == 'high').length;
    final mediumCount = alerts.where((a) => a.priorityLevel.toLowerCase() == 'medium').length;
    final lowCount = alerts.where((a) => a.priorityLevel.toLowerCase() == 'low').length;
    final acknowledgedCount = alerts.where((a) => a.acknowledged).length;

    // Calculate top sound
    final countMap = <String, int>{};
    for (final a in alerts) {
      final name = _resolveCategoryLabel(a.soundCategory);
      countMap[name] = (countMap[name] ?? 0) + 1;
    }
    String topSound = 'None';
    int topSoundCount = 0;
    countMap.forEach((name, count) {
      if (count > topSoundCount) {
        topSoundCount = count;
        topSound = name;
      }
    });

    final nowFormatted = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header: (context) => _buildHeader(nowFormatted),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 14),
          _buildKpiSummary(
            totalAlerts: totalAlerts,
            highCount: highCount,
            mediumCount: mediumCount,
            lowCount: lowCount,
            acknowledgedCount: acknowledgedCount,
            topSound: topSound,
            topSoundCount: topSoundCount,
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Acoustic Incident Log',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text(
                'Showing $totalAlerts event(s)',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildAlertsTable(alerts),
        ],
      ),
    );

    return pdf;
  }

  /// Builds the document header with title, subtitle, and branding
  static pw.Widget _buildHeader(String generatedTime) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AlertSense',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'AI Environmental Sound Awareness System - Incident Report',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date: $generatedTime',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                ),
                child: pw.Text(
                  'CONFIDENTIAL & ACCESSIBLE',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// KPI metric cards summarizing alert activity
  static pw.Widget _buildKpiSummary({
    required int totalAlerts,
    required int highCount,
    required int mediumCount,
    required int lowCount,
    required int acknowledgedCount,
    required String topSound,
    required int topSoundCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildKpiCard('Total Events', '$totalAlerts', PdfColors.blue800),
          _buildKpiCard('Life-Safety (High)', '$highCount', PdfColors.red800),
          _buildKpiCard('Important (Medium)', '$mediumCount', PdfColors.orange800),
          _buildKpiCard('Ambient (Low)', '$lowCount', PdfColors.green800),
          _buildKpiCard(
            'Acknowledged',
            totalAlerts > 0 ? '${((acknowledgedCount / totalAlerts) * 100).toInt()}%' : '0%',
            PdfColors.teal800,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Formatted table listing all alert events
  static pw.Widget _buildAlertsTable(List<AlertEvent> alerts) {
    if (alerts.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 24),
        child: pw.Center(
          child: pw.Text(
            'No alert events recorded in this time range.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
          ),
        ),
      );
    }

    final rows = alerts.map((a) {
      final categoryLabel = _resolveCategoryLabel(a.soundCategory);
      final dateStr = DateFormat('MM/dd/yy HH:mm').format(a.timestamp);
      final priority = a.priorityLevel.toUpperCase();
      final confStr = '${(a.confidence * 100).toStringAsFixed(0)}%';
      final statusStr = a.acknowledged
          ? 'Acknowledged (${a.responseAction ?? "checked"})'
          : 'Unacknowledged';

      return [
        dateStr,
        categoryLabel,
        priority,
        confStr,
        a.source,
        statusStr,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Timestamp', 'Sound Category', 'Priority', 'Conf.', 'Source', 'Status'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  /// Running footer with page numbering and disclaimer
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'AlertSense - Turn important sounds into alerts you can see and feel.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Saves the compiled PDF to temporary storage and returns the File
  static Future<File> generatePdfFile(List<AlertEvent> alerts) async {
    final pdf = buildPdfDocument(alerts);
    final Uint8List bytes = await pdf.save();

    final outputDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${outputDir.path}/AlertSense_Report_$timestamp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Exports and triggers the system share sheet with the generated PDF
  static Future<void> exportAndSharePdf(List<AlertEvent> alerts) async {
    final file = await generatePdfFile(alerts);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'AlertSense Environmental Sound Incident Log (PDF)',
      subject: 'AlertSense Incident Report',
    );
  }
}
