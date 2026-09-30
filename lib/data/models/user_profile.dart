import 'package:equatable/equatable.dart';

/// User profile model corresponding to the Supabase `profiles` table.
///
/// Schema:
/// - id (uuid, primary key, references auth.users)
/// - full_name (text)
/// - email (text)
/// - created_at (timestamptz)
/// - updated_at (timestamptz)
class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to parse from a Supabase row map.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Convert to Supabase row map for upsert / update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, createdAt, updatedAt];
}
