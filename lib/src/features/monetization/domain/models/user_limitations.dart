import 'package:equatable/equatable.dart';
import 'subscription.dart';

/// Types of limitations that can be applied to users
enum LimitationType {
  activeTasks,
  boards,
  boardMembers,
  reminders,
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
    required this.maxReminders,
    this.currentReminders = 0,
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
  final int maxReminders;
  final int currentReminders;
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
        maxReminders: 30,
        currentReminders: 0,
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
        maxReminders: -1,
        currentReminders: 0,
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
        maxReminders: map['maxReminders'] as int? ?? 30,
        currentReminders: map['currentReminders'] as int? ?? 0,
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
        'maxReminders': maxReminders,
        'currentReminders': currentReminders,
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

  /// Checks if user can create more reminders
  bool get canCreateMoreReminders {
    if (maxReminders == -1) return true; // Unlimited
    return currentReminders < maxReminders;
  }

  /// Gets remaining reminder slots
  int get remainingReminderSlots {
    if (maxReminders == -1) return -1; // Unlimited
    return (maxReminders - currentReminders).clamp(0, maxReminders);
  }

  /// Gets reminder usage percentage (0.0 to 1.0)
  double get reminderUsagePercentage {
    if (maxReminders == -1) return 0.0; // Unlimited
    return (currentReminders / maxReminders).clamp(0.0, 1.0);
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
    int? maxReminders,
    int? currentReminders,
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
        maxReminders: maxReminders ?? this.maxReminders,
        currentReminders: currentReminders ?? this.currentReminders,
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
        maxReminders,
        currentReminders,
        updatedAt,
      ];
}
