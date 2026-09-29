import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/ui/alert/dialogs/emergency_call_dialog.dart';
import 'package:alertsense/ui/alert/dialogs/manual_whatsapp_dialog.dart';
import 'package:alertsense/ui/alert/dialogs/manual_sms_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('EmergencyCallDialog Tests', () {
    testWidgets('renders properly with default number and regional chips', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const EmergencyCallDialog(initialNumber: '1122'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency Call'), findsOneWidget);
      expect(find.text('Confirm emergency number to dial:'), findsOneWidget);
      expect(find.text('1122'), findsWidgets); // In TextField and ChoiceChip
      expect(find.text('911 (US/CA)'), findsOneWidget);
      expect(find.text('999 (UK)'), findsOneWidget);
      expect(find.text('112 (EU)'), findsOneWidget);
      expect(find.text('CALL NOW'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping 911 chip updates input text field', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const EmergencyCallDialog(initialNumber: '1122'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 911 (US/CA) chip
      await tester.tap(find.text('911 (US/CA)'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('911'));
    });

    testWidgets('tapping CALL NOW pops with confirmed number', (tester) async {
      String? returnedNumber;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedNumber = await EmergencyCallDialog.show(context, initialNumber: '1122');
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 112 (EU) chip
      await tester.tap(find.text('112 (EU)'));
      await tester.pumpAndSettle();

      // Tap CALL NOW
      await tester.tap(find.text('CALL NOW'));
      await tester.pumpAndSettle();

      expect(returnedNumber, equals('112'));
    });

    testWidgets('tapping Cancel pops with null', (tester) async {
      String? returnedNumber = 'placeholder';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedNumber = await EmergencyCallDialog.show(context, initialNumber: '1122');
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returnedNumber, isNull);
    });
  });

  group('ManualWhatsAppDialog Tests', () {
    testWidgets('renders phone and message preview inputs', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const ManualWhatsAppDialog(
            initialPhone: '+923001234567',
            defaultMessage: 'EMERGENCY: Smoke Alarm detected at current location',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alert via WhatsApp'), findsOneWidget);
      expect(find.text('+923001234567'), findsOneWidget);
      expect(find.text('EMERGENCY: Smoke Alarm detected at current location'), findsOneWidget);
      expect(find.text('Choose in WhatsApp'), findsOneWidget);
      expect(find.text('SEND'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Choose in WhatsApp returns null phone and edited message', (tester) async {
      ({String? phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualWhatsAppDialog.show(
                  context,
                  initialPhone: '+923001234567',
                  defaultMessage: 'Smoke Alarm detected',
                );
              },
              child: const Text('Open WhatsApp Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open WhatsApp Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose in WhatsApp'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.phone, isNull);
      expect(returnedResult!.message, equals('Smoke Alarm detected'));
    });

    testWidgets('tapping SEND returns entered phone and message', (tester) async {
      ({String? phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualWhatsAppDialog.show(
                  context,
                  initialPhone: '03001234567',
                  defaultMessage: 'Fire Alarm detected!',
                );
              },
              child: const Text('Open WhatsApp Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open WhatsApp Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.phone, equals('03001234567'));
      expect(returnedResult!.message, equals('Fire Alarm detected!'));
    });

    testWidgets('tapping Cancel returns null', (tester) async {
      ({String? phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualWhatsAppDialog.show(
                  context,
                  initialPhone: '03001234567',
                  defaultMessage: 'Fire Alarm',
                );
              },
              child: const Text('Open WhatsApp Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open WhatsApp Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNull);
    });
  });

  group('ManualSmsDialog Tests', () {
    testWidgets('renders phone and message preview inputs', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const ManualSmsDialog(
            initialPhone: '+15551234567',
            defaultMessage: 'EMERGENCY ALERT: Siren detected',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alert Family via SMS'), findsOneWidget);
      expect(find.text('+15551234567'), findsOneWidget);
      expect(find.text('EMERGENCY ALERT: Siren detected'), findsOneWidget);
      expect(find.text('SEND SMS'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping SEND SMS returns phone and message', (tester) async {
      ({String phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualSmsDialog.show(
                  context,
                  initialPhone: '+15551234567',
                  defaultMessage: 'Siren alert message',
                );
              },
              child: const Text('Open SMS Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open SMS Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SEND SMS'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.phone, equals('+15551234567'));
      expect(returnedResult!.message, equals('Siren alert message'));
    });

    testWidgets('tapping Cancel returns null', (tester) async {
      ({String phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualSmsDialog.show(
                  context,
                  initialPhone: '+15551234567',
                  defaultMessage: 'Alert',
                );
              },
              child: const Text('Open SMS Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open SMS Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returnedResult, isNull);
    });

    testWidgets('empty phone shows validation error and does not pop', (tester) async {
      ({String phone, String message})? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await ManualSmsDialog.show(
                  context,
                  initialPhone: '',
                  defaultMessage: 'Emergency alert',
                );
              },
              child: const Text('Open SMS Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open SMS Dialog'));
      await tester.pumpAndSettle();

      // Tap SEND SMS with empty phone input
      await tester.tap(find.text('SEND SMS'));
      await tester.pumpAndSettle();

      // Dialog should remain open and display validation error text
      expect(find.text('Please enter a recipient phone number'), findsOneWidget);
      expect(returnedResult, isNull);
    });
  });
}
