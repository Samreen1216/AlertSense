import 'dart:convert';

class AlertEvent {
  final String id;
  final String soundCategory; // enum name as string
  final String priorityLevel; // enum name as string  
  final double confidence;
  final DateTime timestamp;
  final bool acknowledged;
  final int? durationSeconds; // for ongoing alerts
  final String? responseAction; // 'safe', 'called_emergency', 'alerted_family', 'dismissed'
  final String source; // 'Continuous Monitoring', 'Quick Scan'

  const AlertEvent({
    required this.id,
    required this.soundCategory,
    required this.priorityLevel,
    required this.confidence,
    required this.timestamp,
    this.acknowledged = false,
    this.durationSeconds,
    this.responseAction,
    this.source = 'Continuous Monitoring',
  });

  AlertEvent copyWith({
    String? id,
    String? soundCategory,
    String? priorityLevel,
    double? confidence,
    DateTime? timestamp,
    bool? acknowledged,
    int? durationSeconds,
    String? responseAction,
    String? source,
  }) {
    return AlertEvent(
      id: id ?? this.id,
      soundCategory: soundCategory ?? this.soundCategory,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      responseAction: responseAction ?? this.responseAction,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'soundCategory': soundCategory,
      'priorityLevel': priorityLevel,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
      'durationSeconds': durationSeconds,
      'responseAction': responseAction,
      'source': source,
    };
  }

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    return AlertEvent(
      id: map['id'] ?? '',
      soundCategory: map['soundCategory'] ?? '',
      priorityLevel: map['priorityLevel'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      acknowledged: map['acknowledged'] ?? false,
      durationSeconds: map['durationSeconds'],
      responseAction: map['responseAction'],
      source: map['source'] ?? 'Continuous Monitoring',
    );
  }

  String toJson() => json.encode(toMap());

  factory AlertEvent.fromJson(String source) => AlertEvent.fromMap(json.decode(source));
}
