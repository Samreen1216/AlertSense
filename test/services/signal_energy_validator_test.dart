import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/signal_energy_validator.dart';

void main() {
  /// Group 1: Empty Audio Rejection
  group('SignalEnergyValidator: Empty Audio Rejection', () {
    test('Empty list returns isSufficient=false, rms=0.0, dbLevel=0.0', () {
      final validator = SignalEnergyValidator();
      final result = validator.validate([]);
      
      expect(result.isSufficient, isFalse);
      expect(result.rms, 0.0);
      expect(result.dbLevel, 0.0);
      expect(result.rejectionReason, 'Empty audio buffer');
    });
  });

  /// Group 2: Silent Audio (Near-Zero Samples)
  group('SignalEnergyValidator: Silent Audio (Near-Zero Samples)', () {
    test('List of 100 samples all 0.0001 -> isSufficient=false (RMS too low)', () {
      final validator = SignalEnergyValidator();
      final samples = List.filled(100, 0.0001);
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isFalse);
    });

    test('List of 100 samples all 0.0 -> isSufficient=false, rms=0.0', () {
      final validator = SignalEnergyValidator();
      final samples = List.filled(100, 0.0);
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isFalse);
      expect(result.rms, 0.0);
    });
  });

  /// Group 3: Loud Audio (Passes Validation)
  group('SignalEnergyValidator: Loud Audio (Passes Validation)', () {
    test('List of 100 samples all 0.5 -> isSufficient=true (RMS=0.5, well above 0.004)', () {
      final validator = SignalEnergyValidator();
      final samples = List.filled(100, 0.5);
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isTrue);
      expect(result.rms, closeTo(0.5, 0.0001));
    });

    test('List of 100 samples all 1.0 -> isSufficient=true', () {
      final validator = SignalEnergyValidator();
      final samples = List.filled(100, 1.0);
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isTrue);
      expect(result.rms, closeTo(1.0, 0.0001));
    });

    test('Realistic sine wave at moderate amplitude passes', () {
      final validator = SignalEnergyValidator();
      final samples = List.generate(44100, (i) => 0.5 * sin(2 * pi * 440 * i / 44100));
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isTrue);
    });
  });

  /// Group 4: Boundary Conditions
  group('SignalEnergyValidator: Boundary Conditions', () {
    test('Samples that produce RMS exactly at minRms boundary', () {
      const minRms = 0.004;
      // Using very low minDbLevel to ensure dbLevel passes and only RMS boundary is tested
      const minDbLevel = 0.0;
      final validator = SignalEnergyValidator(
        config: SignalValidationConfig(minRms: minRms, minDbLevel: minDbLevel)
      );
      
      // RMS is exactly minRms
      final samples = List.filled(100, minRms);
      final result = validator.validate(samples);
      
      expect(result.isSufficient, isTrue);
    });

    test('Custom config with different minRms and minDbLevel values', () {
      final validator = SignalEnergyValidator(
        config: SignalValidationConfig(minRms: 0.1, minDbLevel: 50.0)
      );
      
      final samples1 = List.filled(100, 0.05); // Below minRms
      expect(validator.validate(samples1).isSufficient, isFalse);
      
      // 0.2 RMS gives db = 20*log10(0.2) + 90 = 76.02, passing both
      final samples2 = List.filled(100, 0.2);
      expect(validator.validate(samples2).isSufficient, isTrue);
    });
  });

  /// Group 5: calculateRms() Unit Tests
  group('SignalEnergyValidator: calculateRms() Unit Tests', () {
    test('RMS of [1.0] = 1.0', () {
      expect(SignalEnergyValidator.calculateRms([1.0]), closeTo(1.0, 0.0001));
    });
    
    test('RMS of [0.0] = 0.0', () {
      expect(SignalEnergyValidator.calculateRms([0.0]), 0.0);
    });

    test('RMS of [1.0, -1.0] = 1.0 (squares cancel sign)', () {
      expect(SignalEnergyValidator.calculateRms([1.0, -1.0]), closeTo(1.0, 0.0001));
    });

    test('RMS of [0.5, 0.5, 0.5, 0.5] = 0.5', () {
      expect(SignalEnergyValidator.calculateRms([0.5, 0.5, 0.5, 0.5]), closeTo(0.5, 0.0001));
    });

    test('RMS of empty list = 0.0', () {
      expect(SignalEnergyValidator.calculateRms([]), 0.0);
    });

    test('RMS of [3.0, 4.0] = sqrt((9+16)/2) = sqrt(12.5) ≈ 3.5355', () {
      expect(SignalEnergyValidator.calculateRms([3.0, 4.0]), closeTo(3.5355, 0.0001));
    });
  });

  /// Group 6: rmsToDb() Unit Tests
  group('SignalEnergyValidator: rmsToDb() Unit Tests', () {
    test('rmsToDb(0.0) = 0.0 (guard)', () {
      expect(SignalEnergyValidator.rmsToDb(0.0), 0.0);
    });

    test('rmsToDb(-1.0) = 0.0 (guard for negative)', () {
      expect(SignalEnergyValidator.rmsToDb(-1.0), 0.0);
    });

    test('rmsToDb(1.0) = 90.0 (since 20*log10(1.0) + 90 = 0 + 90)', () {
      expect(SignalEnergyValidator.rmsToDb(1.0), closeTo(90.0, 0.0001));
    });

    test('rmsToDb(0.1) = 70.0 (since 20*log10(0.1) + 90 = -20 + 90)', () {
      expect(SignalEnergyValidator.rmsToDb(0.1), closeTo(70.0, 0.0001));
    });

    test('rmsToDb(0.01) = 50.0', () {
      expect(SignalEnergyValidator.rmsToDb(0.01), closeTo(50.0, 0.0001));
    });

    test('rmsToDb(0.001) = 30.0', () {
      expect(SignalEnergyValidator.rmsToDb(0.001), closeTo(30.0, 0.0001));
    });

    test('Result is clamped to [0.0, 120.0]', () {
      // 100.0 normally gives 130.0
      expect(SignalEnergyValidator.rmsToDb(100.0), closeTo(120.0, 0.0001));
      // 0.000001 normally gives -30.0
      expect(SignalEnergyValidator.rmsToDb(0.000001), closeTo(0.0, 0.0001));
    });
  });

  /// Group 7: Custom Config
  group('SignalEnergyValidator: Custom Config', () {
    test('Custom minRms=0.01, minDbLevel=40.0 rejects signals that default config would pass', () {
      final defaultValidator = SignalEnergyValidator();
      final customValidator = SignalEnergyValidator(
        config: SignalValidationConfig(minRms: 0.01, minDbLevel: 40.0)
      );

      // RMS of 0.005 is > default minRms (0.004) but < custom minRms (0.01)
      final samples = List.filled(100, 0.005);
      
      expect(defaultValidator.validate(samples).isSufficient, isTrue);
      expect(customValidator.validate(samples).isSufficient, isFalse);
    });

    test('Custom config with very low thresholds passes almost everything', () {
      final customValidator = SignalEnergyValidator(
        config: SignalValidationConfig(minRms: 0.00001, minDbLevel: 1.0)
      );

      final samples = List.filled(100, 0.0001);
      expect(customValidator.validate(samples).isSufficient, isTrue);
    });
  });

  /// Group 8: Realistic Sine Wave
  group('SignalEnergyValidator: Realistic Sine Wave', () {
    test('Generate a 440Hz sine wave at amplitude 0.3 -> should pass', () {
      final validator = SignalEnergyValidator();
      final samples = List.generate(44100, (i) => 0.3 * sin(2 * pi * 440 * i / 44100));
      
      final result = validator.validate(samples);
      expect(result.isSufficient, isTrue);
    });

    test('Generate a 440Hz sine wave at amplitude 0.001 -> should fail', () {
      final validator = SignalEnergyValidator();
      final samples = List.generate(44100, (i) => 0.001 * sin(2 * pi * 440 * i / 44100));
      
      final result = validator.validate(samples);
      expect(result.isSufficient, isFalse);
    });
  });
}
