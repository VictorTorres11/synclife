import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_limitations.dart';
import '../providers/monetization_providers.dart';
import '../widgets/upgrade_prompt_dialog.dart';

/// Utility class for Premium feature management
class PremiumUtils {
  /// Check if user can perform an action, show upgrade prompt if not
  static Future<bool> checkAndPromptForAction(
    BuildContext context,
    WidgetRef ref,
    String userId,
    LimitationType limitationType, {
    String? customMessage,
    List<String>? customBenefits,
  }) async {
    final isPremiumAsync = await ref.read(isPremiumProvider(userId).future);

    if (isPremiumAsync) return true;

    final canPerform =
        await ref.read(canPerformActionProvider(limitationType).future);

    if (!canPerform) {
      final feature = _getFeatureName(limitationType);
      final description =
          customMessage ?? _getFeatureDescription(limitationType);
      final benefits = customBenefits ?? _getDefaultBenefits();

      if (context.mounted) {
        await UpgradePromptDialog.show(
          context,
          feature: feature,
          description: description,
          benefits: benefits,
        );
      }

      return false;
    }

    return true;
  }

  /// Check if a specific Premium feature is available
  static Future<bool> isFeatureAvailable(WidgetRef ref, String userId, String featureKey) async {
    final isPremiumAsync = await ref.read(isPremiumProvider(userId).future);
    if (isPremiumAsync) return true;

    final limitationsAsync = await ref.read(userLimitationsProvider(userId).future);
    switch (featureKey) {
      case 'calendar_integration':
        return limitationsAsync.canUseCalendarIntegration;
      case 'advanced_backup':
        return limitationsAsync.canUseAdvancedBackup;
      case 'premium_themes':
        return limitationsAsync.canUsePremiumThemes;
      case 'ad_free':
        return !limitationsAsync.adsEnabled;
      default:
        return false;
    }
  }

  /// Show upgrade prompt for a specific feature
  static Future<void> showUpgradePromptForFeature(
    BuildContext context,
    String featureKey, {
    String? customDescription,
    List<String>? customBenefits,
  }) async {
    final feature = _getFeatureNameByKey(featureKey);
    final description =
        customDescription ?? _getFeatureDescriptionByKey(featureKey);
    final benefits = customBenefits ?? _getDefaultBenefits();

    await UpgradePromptDialog.show(
      context,
      feature: feature,
      description: description,
      benefits: benefits,
    );
  }

  /// Get remaining usage for a limitation type
  static Future<int> getRemainingUsage(WidgetRef ref, String userId, LimitationType limitationType) async {
    final limitationsAsync = await ref.read(userLimitationsProvider(userId).future);
    switch (limitationType) {
      case LimitationType.activeTasks:
        return limitationsAsync.remainingTaskSlots;
      case LimitationType.boards:
        return limitationsAsync.remainingBoardSlots;
      case LimitationType.boardMembers:
        return limitationsAsync.maxBoardMembers == -1
            ? -1
            : limitationsAsync.maxBoardMembers;
    }
  }

  /// Get usage percentage for progress indicators
  static Future<double> getUsagePercentage(
      WidgetRef ref, String userId, LimitationType limitationType) async {
    final limitationsAsync = await ref.read(userLimitationsProvider(userId).future);
    switch (limitationType) {
      case LimitationType.activeTasks:
        if (limitationsAsync.maxActiveTasks == -1) return 0.0;
        return limitationsAsync.currentActiveTasks / limitationsAsync.maxActiveTasks;
      case LimitationType.boards:
        if (limitationsAsync.maxBoards == -1) return 0.0;
        return limitationsAsync.currentBoards / limitationsAsync.maxBoards;
      case LimitationType.boardMembers:
        return 0.0; // Not tracked globally
    }
  }

  static String _getFeatureName(LimitationType limitationType) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'Unlimited Tasks';
      case LimitationType.boards:
        return 'Unlimited Boards';
      case LimitationType.boardMembers:
        return 'Unlimited Board Members';
    }
  }

  static String _getFeatureDescription(LimitationType limitationType) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'You\'ve reached your task limit. Upgrade to Premium for unlimited tasks.';
      case LimitationType.boards:
        return 'You\'ve reached your board limit. Upgrade to Premium for unlimited boards.';
      case LimitationType.boardMembers:
        return 'Free users have limited board members. Upgrade for unlimited collaboration.';
    }
  }

  static String _getFeatureNameByKey(String featureKey) {
    switch (featureKey) {
      case 'calendar_integration':
        return 'Calendar Integration';
      case 'advanced_backup':
        return 'Advanced Backup';
      case 'premium_themes':
        return 'Premium Themes';
      case 'ad_free':
        return 'Ad-Free Experience';
      default:
        return 'Premium Feature';
    }
  }

  static String _getFeatureDescriptionByKey(String featureKey) {
    switch (featureKey) {
      case 'calendar_integration':
        return 'Sync your tasks with external calendars like Google Calendar and Outlook.';
      case 'advanced_backup':
        return 'Automatic cloud backup with version history and cross-device sync.';
      case 'premium_themes':
        return 'Access exclusive themes and customization options.';
      case 'ad_free':
        return 'Enjoy SyncLife without any advertisements or interruptions.';
      default:
        return 'This feature is available with Premium subscription.';
    }
  }

  static List<String> _getDefaultBenefits() {
    return [
      'Unlimited tasks and boards',
      'Unlimited board members',
      'Calendar integration',
      'Advanced backup & sync',
      'Premium themes',
      'Ad-free experience',
      'Priority support',
    ];
  }
}