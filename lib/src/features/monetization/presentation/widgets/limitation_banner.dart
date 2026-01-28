import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_limitations.dart';
import '../providers/monetization_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'upgrade_prompt_dialog.dart';

/// Banner showing current limitations for free users
class LimitationBanner extends ConsumerWidget {
  const LimitationBanner({
    super.key,
    required this.limitationType,
    this.message,
    this.showUpgradeButton = true,
  });

  final LimitationType limitationType;
  final String? message;
  final bool showUpgradeButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    
    if (user == null) return const SizedBox.shrink();

    final isPremiumAsync = ref.watch(isPremiumProvider(user.id));
    final limitationsAsync = ref.watch(userLimitationsProvider(user.id));

    return isPremiumAsync.when(
      data: (isPremium) {
        // Don't show banner for Premium users
        if (isPremium) return const SizedBox.shrink();

        return limitationsAsync.when(
          data: (limitations) {
            final shouldShow = _shouldShowBanner(limitations);
            if (!shouldShow) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message ?? _getDefaultMessage(limitations),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (showUpgradeButton) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _showUpgradePrompt(context),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onErrorContainer,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  bool _shouldShowBanner(UserLimitations limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return !limitations.canCreateMoreTasks;
      case LimitationType.boards:
        return !limitations.canCreateMoreBoards;
      case LimitationType.boardMembers:
        return limitations.maxBoardMembers != -1;
    }
  }

  String _getDefaultMessage(UserLimitations limitations) {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'You\'ve reached your task limit (${limitations.maxActiveTasks}). Upgrade to Premium for unlimited tasks.';
      case LimitationType.boards:
        return 'You\'ve reached your board limit (${limitations.maxBoards}). Upgrade to Premium for unlimited boards.';
      case LimitationType.boardMembers:
        return 'Free users can add up to ${limitations.maxBoardMembers} members per board. Upgrade for unlimited members.';
    }
  }

  void _showUpgradePrompt(BuildContext context) {
    final feature = _getFeatureName();
    final description = _getFeatureDescription();
    final benefits = _getFeatureBenefits();

    UpgradePromptDialog.show(
      context,
      feature: feature,
      description: description,
      benefits: benefits,
    );
  }

  String _getFeatureName() {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'Unlimited Tasks';
      case LimitationType.boards:
        return 'Unlimited Boards';
      case LimitationType.boardMembers:
        return 'Unlimited Board Members';
    }
  }

  String _getFeatureDescription() {
    switch (limitationType) {
      case LimitationType.activeTasks:
        return 'Create as many tasks as you need without any restrictions.';
      case LimitationType.boards:
        return 'Organize your life with unlimited boards for different projects and areas.';
      case LimitationType.boardMembers:
        return 'Collaborate with unlimited team members on your boards.';
    }
  }

  List<String> _getFeatureBenefits() {
    return [
      'Unlimited tasks and boards',
      'Unlimited board members',
      'Calendar integration',
      'Advanced backup & sync',
      'Premium themes',
      'Ad-free experience',
    ];
  }
}
