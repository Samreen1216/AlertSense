class ClassificationResult {
  final String soundCategory; // SoundCategory enum name
  final double confidence;
  final DateTime timestamp;
  final List<MapEntry<String, double>> topPredictions; // top 5 predictions
  final double ambientDbLevel;
  
  const ClassificationResult({
    required this.soundCategory,
    required this.confidence,
    required this.timestamp,
    required this.topPredictions,
    required this.ambientDbLevel,
  });

  @override
  String toString() {
    return 'ClassificationResult(soundCategory: $soundCategory, confidence: $confidence, timestamp: $timestamp, topPredictions: $topPredictions, ambientDbLevel: $ambientDbLevel)';
  }
}
