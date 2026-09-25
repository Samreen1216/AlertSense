import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/services/pdf_export_service.dart';

void main() {
  group('PdfExportService Tests', () {
    test('buildPdfDocument handles empty alert list gracefully', () async {
      final doc = PdfExportService.buildPdfDocument([]);
      final Uint8List bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500)); // Valid PDF header & structure
    });

    test('buildPdfDocument generates formatted multi-event report with KPI summaries', () async {
      final testAlerts = [
        AlertEvent(
          id: 'test-1',
          soundCategory: 'fireAlarm',
          priorityLevel: 'high',
          confidence: 0.95,
          timestamp: DateTime(2026, 9, 24, 10, 15),
          acknowledged: true,
          responseAction: 'safe',
          source: 'Continuous Monitoring',
        ),
        AlertEvent(
          id: 'test-2',
          soundCategory: 'doorbell',
          priorityLevel: 'medium',
          confidence: 0.82,
          timestamp: DateTime(2026, 9, 24, 10, 30),
          acknowledged: false,
          source: 'Continuous Monitoring',
        ),
        AlertEvent(
          id: 'test-3',
          soundCategory: 'dogBarking',
          priorityLevel: 'low',
          confidence: 0.78,
          timestamp: DateTime(2026, 9, 24, 10, 45),
          acknowledged: true,
          responseAction: 'checked',
          source: 'Quick Scan',
        ),
      ];

      final doc = PdfExportService.buildPdfDocument(testAlerts);
      final Uint8List bytes = await doc.save();

      expect(bytes, isNotEmpty);
      // Valid PDF files start with %PDF
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}
