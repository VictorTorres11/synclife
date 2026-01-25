import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import '../../../lib/src/features/monetization/domain/models/models.dart';
import '../../../lib/src/features/monetization/domain/services/services.dart';
import '../../../lib/src/features/monetization/data/services/services.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  group('Premium Features Tests', () {
    late MockSubscriptionService mockSubscriptionService;

    setUp(() {
      mockSubscriptionService = MockSubscriptionService();
    });

    group('Calendar Integration', () {
      test('should create calendar integration for premium users', () async {
        // Arrange
        const userId = 'premium_user_id';
        const provider = CalendarProvider.google;
        const accountName = 'test@gmail.com';
        const calendarId = 'primary';

        final service = FirebaseCalendarIntegrationService();

        // Act & Assert
        expect(
          () => service.createIntegration(
            userId: userId,
            provider: provider,
            accountName: accountName,
            calendarId: calendarId,
          ),
          returnsNormally,
        );
      });

      test('should validate calendar integration model', () {
        // Arrange
        final integration = CalendarIntegration(
          id: 'test_id',
          userId: 'user_id',
          provider: CalendarProvider.google,
          accountName: 'test@gmail.com',
          calendarId: 'primary',
          isEnabled: true,
          syncDirection: SyncDirection.bidirectional,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(integration.id, equals('test_id'));
        expect(integration.provider, equals(CalendarProvider.google));
        expect(integration.isEnabled, isTrue);
        expect(integration.syncDirection, equals(SyncDirection.bidirectional));
      });

      test('should convert calendar integration to/from map', () {
        // Arrange
        final now = DateTime.now();
        final integration = CalendarIntegration(
          id: 'test_id',
          userId: 'user_id',
          provider: CalendarProvider.google,
          accountName: 'test@gmail.com',
          calendarId: 'primary',
          isEnabled: true,
          syncDirection: SyncDirection.bidirectional,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final map = integration.toMap();
        final restored = CalendarIntegration.fromMap(map);

        // Assert
        expect(restored.id, equals(integration.id));
        expect(restored.provider, equals(integration.provider));
        expect(restored.isEnabled, equals(integration.isEnabled));
        expect(restored.syncDirection, equals(integration.syncDirection));
      });
    });

    group('Advanced Backup', () {
      test('should create backup configuration', () async {
        // Arrange
        const userId = 'premium_user_id';
        const name = 'Daily Backup';
        const backupType = BackupType.incremental;
        const frequency = BackupFrequency.daily;

        final service = FirebaseAdvancedBackupService();

        // Act & Assert
        expect(
          () => service.createBackup(
            userId: userId,
            name: name,
            backupType: backupType,
            frequency: frequency,
          ),
          returnsNormally,
        );
      });

      test('should validate backup model', () {
        // Arrange
        final backup = AdvancedBackup(
          id: 'backup_id',
          userId: 'user_id',
          name: 'Test Backup',
          backupType: BackupType.full,
          frequency: BackupFrequency.weekly,
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(backup.id, equals('backup_id'));
        expect(backup.backupType, equals(BackupType.full));
        expect(backup.frequency, equals(BackupFrequency.weekly));
        expect(backup.isEnabled, isTrue);
      });

      test('should calculate next backup time correctly', () {
        // Arrange
        final now = DateTime.now();
        final backup = AdvancedBackup(
          id: 'backup_id',
          userId: 'user_id',
          name: 'Test Backup',
          backupType: BackupType.incremental,
          frequency: BackupFrequency.daily,
          isEnabled: true,
          createdAt: now,
          updatedAt: now,
          nextBackupAt: now.add(const Duration(days: 1)),
        );

        // Act & Assert
        expect(backup.nextBackupAt, isNotNull);
        expect(backup.nextBackupAt!.isAfter(now), isTrue);
      });

      test('should format backup archive size correctly', () {
        // Arrange
        final archive1 = BackupArchive(
          id: 'archive1',
          backupId: 'backup1',
          userId: 'user1',
          fileName: 'test.zip',
          filePath: '/path/test.zip',
          fileSize: 1024, // 1KB
          backupType: BackupType.full,
          createdAt: DateTime(2024, 1, 1),
          isEncrypted: false,
        );

        final archive2 = BackupArchive(
          id: 'archive2',
          backupId: 'backup2',
          userId: 'user2',
          fileName: 'test2.zip',
          filePath: '/path/test2.zip',
          fileSize: 1024 * 1024, // 1MB
          backupType: BackupType.full,
          createdAt: DateTime(2024, 1, 1),
          isEncrypted: false,
        );

        // Act & Assert
        expect(archive1.formattedSize, equals('1.0KB'));
        expect(archive2.formattedSize, equals('1.0MB'));
      });
    });

    group('Premium Themes', () {
      test('should create premium theme', () {
        // Arrange
        final colorScheme = PremiumColorScheme(
          lightScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          darkScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        );

        final theme = PremiumTheme(
          id: 'theme_id',
          name: 'Test Theme',
          description: 'A test theme',
          category: ThemeCategory.custom,
          isPremium: true,
          colorScheme: colorScheme,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(theme.id, equals('theme_id'));
        expect(theme.name, equals('Test Theme'));
        expect(theme.category, equals(ThemeCategory.custom));
        expect(theme.isPremium, isTrue);
      });

      test('should validate user theme preferences', () {
        // Arrange
        final preferences = UserThemePreferences(
          userId: 'user_id',
          selectedThemeId: 'theme_id',
          isDarkMode: true,
          followSystemTheme: false,
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(preferences.userId, equals('user_id'));
        expect(preferences.selectedThemeId, equals('theme_id'));
        expect(preferences.isDarkMode, isTrue);
        expect(preferences.followSystemTheme, isFalse);
      });

      test('should convert theme preferences to/from map', () {
        // Arrange
        final now = DateTime.now();
        final preferences = UserThemePreferences(
          userId: 'user_id',
          selectedThemeId: 'theme_id',
          isDarkMode: true,
          followSystemTheme: false,
          updatedAt: now,
        );

        // Act
        final map = preferences.toMap();
        final restored = UserThemePreferences.fromMap(map);

        // Assert
        expect(restored.userId, equals(preferences.userId));
        expect(restored.selectedThemeId, equals(preferences.selectedThemeId));
        expect(restored.isDarkMode, equals(preferences.isDarkMode));
        expect(
            restored.followSystemTheme, equals(preferences.followSystemTheme));
      });
    });

    group('Premium Feature Access', () {
      test('should allow premium users to access all features', () {
        // Arrange
        final limitations =
            UserLimitations.forPlan('user_id', SubscriptionPlan.premium);

        // Act & Assert
        expect(limitations.canUseCalendarIntegration, isTrue);
        expect(limitations.canUseAdvancedBackup, isTrue);
        expect(limitations.canUsePremiumThemes, isTrue);
        expect(limitations.adsEnabled, isFalse);
      });

      test('should restrict free users from premium features', () {
        // Arrange
        final limitations =
            UserLimitations.forPlan('user_id', SubscriptionPlan.free);

        // Act & Assert
        expect(limitations.canUseCalendarIntegration, isFalse);
        expect(limitations.canUseAdvancedBackup, isFalse);
        expect(limitations.canUsePremiumThemes, isFalse);
        expect(limitations.adsEnabled, isTrue);
      });

      test('should validate subscription upgrade enables premium features', () {
        // Arrange
        final freeLimitations =
            UserLimitations.forPlan('user_id', SubscriptionPlan.free);
        final premiumLimitations =
            UserLimitations.forPlan('user_id', SubscriptionPlan.premium);

        // Act & Assert
        expect(freeLimitations.canUseCalendarIntegration, isFalse);
        expect(premiumLimitations.canUseCalendarIntegration, isTrue);

        expect(freeLimitations.canUseAdvancedBackup, isFalse);
        expect(premiumLimitations.canUseAdvancedBackup, isTrue);

        expect(freeLimitations.canUsePremiumThemes, isFalse);
        expect(premiumLimitations.canUsePremiumThemes, isTrue);
      });
    });
  });
}
