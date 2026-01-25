import 'package:equatable/equatable.dart';
import 'subscription.dart';

/// Types of limitations that can be applied to users
enum LimitationType {
  activeTasks,
  boards,
  boardMembers,
}

/// Represents limitations applied to free users
class UserLimitations extends Equatable {
  const UserLimitations({
    required this.userId,
    required this.maxActiveTasks,
    required this.maxBoards,
    required this.maxBoardMembers,
    required this.adsEnabled,
    required this.canUseCalendarIntegration,
    required this.canUseAdvancedBackup,
    required this.canUsePremiumThemes,
    this.currentActiveTasks = 0,
    this.currentBoards = 0,
    required this.updatedAt,
  });

  final String userId;
  final int maxActiveTasks;
  final int maxBoards;
  final int maxBoardMembers;
  final bool adsEnabled;
  final bool canUseCalendarIntegration;
  final bool canUseAdvancedBackup;
  final bool canUsePremiumThemes;
  final int currentActiveTasks;
  final int currentBoards;
  final DateTime updatedAt;

  /// Default limitations for free users
  static UserLimitations get defaultFree => UserLimitations(
        userId: '',
        maxActiveTasks: 50,
        maxBoards: 3,
        maxBoardMembers: 5,
        adsEnabled: true,
        canUseCalendarIntegration: false,
        canUseAdvancedBackup: false,
        canUsePremiumThemes: false,
        updatedAt: DateTime.now(),
      );

  /// Unlimited access for premium users
  static UserLimitations get premium => UserLimitations(
        userId: '',
        maxActiveTasks: -1, // -1 means unlimited
        maxBoards: -1,
        maxBoardMembers: -1,
        adsEnabled: false,
        canUseCalendarIntegration: true,
        canUseAdvancedBackup: true,
        canUsePremiumThemes: true,
        updatedAt: DateTime.now(),
      );

  /// Creates UserLimitations from Firestore document data
  factory UserLimitations.fromMap(Map<String, dynamic> map) => UserLimitations(
        userId: map['userId'] as String,
        maxActiveTasks: map['maxActiveTasks'] as int,
        maxBoards: map['maxBoards'] as int,
        maxBoardMembers: map['maxBoardMembers'] as int,
        adsEnabled: map['adsEnabled'] as bool,
        canUseCalendarIntegration: map['canUseCalendarIntegration'] as bool,
        canUseAdvancedBackup: map['canUseAdvancedBackup'] as bool,
        canUsePremiumThemes: map['canUsePremiumThemes'] as bool,
        currentActiveTasks: map['currentActiveTasks'] as int? ?? 0,
        currentBoards: map['currentBoards'] as int? ?? 0,
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  /// Converts UserLimitations to Firestore document data
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'maxActiveTasks': maxActiveTasks,
        'maxBoards': maxBoards,
        'maxBoardMembers': maxBoardMembers,
        'adsEnabled': adsEnabled,
        'canUseCalendarIntegration': canUseCalendarIntegration,
        'canUseAdvancedBackup': canUseAdvancedBackup,
        'canUsePremiumThemes': canUsePremiumThemes,
        'currentActiveTasks': currentActiveTasks,
        'currentBoards': currentBoards,
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Checks if user can create more tasks
  bool get canCreateMoreTasks {
    if (maxActiveTasks == -1) return true; // Unlimited
    return currentActiveTasks < maxActiveTasks;
  }

  /// Checks if user can create more boards
  bool get canCreateMoreBoards {
    if (maxBoards == -1) return true; // Unlimited
    return currentBoards < maxBoards;
  }

  /// Gets remaining task slots
  int get remainingTaskSlots {
    if (maxActiveTasks == -1) return -1; // Unlimited
    return (maxActiveTasks - currentActiveTasks).clamp(0, maxActiveTasks);
  }

  /// Gets remaining board slots
  int get remainingBoardSlots {
    if (maxBoards == -1) return -1; // Unlimited
    return (maxBoards - currentBoards).clamp(0, maxBoards);
  }

  /// Creates limitations for a specific subscription plan
  factory UserLimitations.forPlan(String userId, SubscriptionPlan plan) {
    final now = DateTime.now();

    switch (plan) {
      case SubscriptionPlan.premium:
        return premium.copyWith(userId: userId, updatedAt: now);
      case SubscriptionPlan.free:
      default:
        return defaultFree.copyWith(userId: userId, updatedAt: now);
    }
  }

  UserLimitations copyWith({
    String? userId,
    int? maxActiveTasks,
    int? maxBoards,
    int? maxBoardMembers,
    bool? adsEnabled,
    bool? canUseCalendarIntegration,
    bool? canUseAdvancedBackup,
    bool? canUsePremiumThemes,
    int? currentActiveTasks,
    int? currentBoards,
    DateTime? updatedAt,
  }) =>
      UserLimitations(
        userId: userId ?? this.userId,
        maxActiveTasks: maxActiveTasks ?? this.maxActiveTasks,
        maxBoards: maxBoards ?? this.maxBoards,
        maxBoardMembers: maxBoardMembers ?? this.maxBoardMembers,
        adsEnabled: adsEnabled ?? this.adsEnabled,
        canUseCalendarIntegration:
            canUseCalendarIntegration ?? this.canUseCalendarIntegration,
        canUseAdvancedBackup: canUseAdvancedBackup ?? this.canUseAdvancedBackup,
        canUsePremiumThemes: canUsePremiumThemes ?? this.canUsePremiumThemes,
        currentActiveTasks: currentActiveTasks ?? this.currentActiveTasks,
        currentBoards: currentBoards ?? this.currentBoards,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        userId,
        maxActiveTasks,
        maxBoards,
        maxBoardMembers,
        adsEnabled,
        canUseCalendarIntegration,
        canUseAdvancedBackup,
        canUsePremiumThemes,
        currentActiveTasks,
        currentBoards,
        updatedAt,
      ];
}
