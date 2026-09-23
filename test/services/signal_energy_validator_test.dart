import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/signal_energy_validator.dart';

void main() {
  group('SignalEnergyValidator Tests', () {
    const validator = SignalEnergyValidator(
      config: SignalValidationConfig(minRms: 0.008, minDbLevel: 42.0),
    );

    test('Empty audio buffer is rejected', () {
      final res = validator.validate([]);
      expect(res.isSufficient, isFalse);
      expect(res.rejectionReason, contains('Empty'));
    });

    test('Near-silent audio floor (RMS 0.002) is rejected as ambient noise floor', () {
      final silence = List<double>.filled(15600, 0.002);
      final res = validator.validate(silence);

      expect(res.isSufficient, isFalse);
      expect(res.rms, closeTo(0.002, 0.0001));
      expect(res.rejectionReason, contains('ambient noise floor'));
    });

    test('Moderate acoustic event (RMS 0.05, ~64 dB) passes signal check', () {
      final sound = List<double>.filled(15600, 0.05);
      final res = validator.validate(sound);

      expect(res.isSufficient, isTrue);
      expect(res.rms, closeTo(0.05, 0.0001));
      expect(res.dbLevel, greaterThan(60.0));
      expect(res.rejectionReason, isNull);
    });

    test('Custom threshold configuration is strictly respected', () {
      const strictValidator = SignalEnergyValidator(
        config: SignalValidationConfig(minRms: 0.10, minDbLevel: 70.0),
      );

      final sound = List<double>.filled(15600, 0.05); // passes 0.008, but fails 0.10
      final res = strictValidator.validate(sound);

      expect(res.isSufficient, isFalse);
    });

    test('calculateRms accurately calculates root mean square', () {
      final samples = [3.0, 4.0];
      // sqrt((9 + 16) / 2) = sqrt(12.5) ≈ 3.5355
      expect(SignalEnergyValidator.calculateRms(samples), closeTo(3.5355, 0.001));
    });
  });
}
