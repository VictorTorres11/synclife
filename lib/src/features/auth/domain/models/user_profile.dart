import 'package:equatable/equatable.dart';

/// Represents extended user profile information
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.region,
    required this.timezone,
    required this.language,
    this.isOnboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String region;
  final String timezone;
  final String language;
  final bool isOnboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a UserProfile from Firestore document data
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      region: map['region'] as String,
      timezone: map['timezone'] as String,
      language: map['language'] as String,
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Converts UserProfile to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'region': region,
      'timezone': timezone,
      'language': language,
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? region,
    String? timezone,
    String? language,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      region: region ?? this.region,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        region,
        timezone,
        language,
        isOnboardingCompleted,
        createdAt,
        updatedAt,
      ];
}