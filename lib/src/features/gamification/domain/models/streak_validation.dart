import 'package:equatable/equatable.dart';

/// Represents streak validation data for a user
class StreakValidation extends Equatable {
  const StreakValidation({
    required this.userId,
    required this.date,
    required this.completedEssentialTasks,
    required this.totalEssentialTasks,
    required this.isStreakDay,
  });

  final String userId;
  final DateTime date;
  final int completedEssentialTasks;
  final int totalEssentialTasks;
  final bool isStreakDay;

  /// Creates a StreakValidation from Firestore document data
  factory StreakValidation.fromMap(Map<String, dynamic> map) => StreakValidation(
    userId: map['userId'] as String,
    date: DateTime.parse(map['date'] as String),
    completedEssentialTasks: map['completedEssentialTasks'] as int,
    totalEssentialTasks: map['totalEssentialTasks'] as int,
    isStreakDay: map['isStreakDay'] as bool,
  );

  /// Converts StreakValidation to Firestore document data
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': date.toIso8601String(),
    'completedEssentialTasks': completedEssentialTasks,
    'totalEssentialTasks': totalEssentialTasks,
    'isStreakDay': isStreakDay,
  };

  /// Checks if all essential tasks were completed
  bool get allEssentialTasksCompleted => 
      totalEssentialTasks > 0 && completedEssentialTasks >= totalEssentialTasks;

  /// Calculates completion percentage
  double get completionPercentage => 
      totalEssentialTasks > 0 ? completedEssentialTasks / totalEssentialTasks : 0.0;

  StreakValidation copyWith({
    String? userId,
    DateTime? date,
    int? completedEssentialTasks,
    int? totalEssentialTasks,
    bool? isStreakDay,
  }) => StreakValidation(
    userId: userId ?? this.userId,
    date: date ?? this.date,
    completedEssentialTasks: completedEssentialTasks ?? this.completedEssentialTasks,
    totalEssentialTasks: totalEssentialTasks ?? this.totalEssentialTasks,
    isStreakDay: isStreakDay ?? this.isStreakDay,
  );

  @override
  List<Object?> get props => [
    userId, date, completedEssentialTasks, totalEssentialTasks, isStreakDay,
  ];
}