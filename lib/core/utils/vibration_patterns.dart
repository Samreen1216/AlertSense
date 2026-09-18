class VibrationPatterns {
  VibrationPatterns._();

  static const List<int> fireAlarm = [0, 500, 200, 500, 200, 500];
  static const List<int> emergencySiren = [0, 800, 200, 800];
  static const List<int> glassBreaking = [0, 1000];
  static const List<int> doorbell = [0, 300, 100, 300];
  static const List<int> knocking = [0, 200, 100, 200, 100, 200];
  static const List<int> babyCrying = [0, 400, 200, 400, 200, 400];
  static const List<int> dogBarking = [0, 200];
  static const List<int> vehicleHorn = [0, 150, 100, 150];

  /// Doubles all durations for sleep mode boost
  static List<int> sleepModeBoost(List<int> pattern) {
    return pattern.map((duration) => duration * 2).toList();
  }
}
