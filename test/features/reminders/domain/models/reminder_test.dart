import 'package:flutter_test/flutter_test.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder.dart';
import 'package:synclife_app/src/features/reminders/domain/models/reminder_priority.dart';

void main() {
  group('Reminder Model', () {
    // Test data
    final testDateTime = DateTime(2024, 1, 15, 10, 30);
    final testReminder = Reminder(
      id: 'reminder_123',
      content: 'Buy groceries for dinner',
      userId: 'user_456',
      boardId: 'board_789',
      createdAt: testDateTime,
      updatedAt: testDateTime,
      tags: ['shopping', 'urgent'],
      priority: ReminderPriority.high,
    );

    group('Constructor', () {
      test('should create reminder with all required fields', () {
        // Arrange & Act
        final reminder = Reminder(
          id: 'test_id',
          content: 'Test content',
          userId: 'test_user',
          boardId: 'test_board',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        // Assert
        expect(reminder.id, 'test_id');
        expect(reminder.content, 'Test content');
        expect(reminder.userId, 'test_user');
        expect(reminder.boardId, 'test_board');
        expect(reminder.createdAt, testDateTime);
        expect(reminder.updatedAt, testDateTime);
        expect(reminder.tags, isEmpty);
        expect(reminder.priority, ReminderPriority.medium);
      });

      test('should create reminder with optional fields', () {
        // Arrange & Act
        final reminder = Reminder(
          id: 'test_id',
          content: 'Test content',
          userId: 'test_user',
          boardId: 'test_board',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          tags: ['tag1', 'tag2'],
          priority: ReminderPriority.low,
        );

        // Assert
        expect(reminder.tags, ['tag1', 'tag2']);
        expect(reminder.priority, ReminderPriority.low);
      });

      test('should default to empty tags list when not provided', () {
        // Arrange & Act
        final reminder = Reminder(
          id: 'test_id',
          content: 'Test content',
          userId: 'test_user',
          boardId: 'test_board',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        // Assert
        expect(reminder.tags, isEmpty);
        expect(reminder.tags, isA<List<String>>());
      });

      test('should default to medium priority when not provided', () {
        // Arrange & Act
        final reminder = Reminder(
          id: 'test_id',
          content: 'Test content',
          userId: 'test_user',
          boardId: 'test_board',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        // Assert
        expect(reminder.priority, ReminderPriority.medium);
      });
    });

    group('Serialization - toMap()', () {
      test('should convert reminder to map with all fields', () {
        // Arrange & Act
        final map = testReminder.toMap();

        // Assert
        expect(map['id'], 'reminder_123');
        expect(map['content'], 'Buy groceries for dinner');
        expect(map['userId'], 'user_456');
        expect(map['boardId'], 'board_789');
        expect(map['createdAt'], testDateTime.toIso8601String());
        expect(map['updatedAt'], testDateTime.toIso8601String());
        expect(map['tags'], ['shopping', 'urgent']);
        expect(map['priority'], 'high');
      });

      test('should serialize empty tags list correctly', () {
        // Arrange
        final reminder = Reminder(
          id: 'test_id',
          content: 'Test content',
          userId: 'test_user',
          boardId: 'test_board',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          tags: [],
        );

        // Act
        final map = reminder.toMap();

        // Assert
        expect(map['tags'], isEmpty);
        expect(map['tags'], isA<List<String>>());
      });

      test('should serialize all priority levels correctly', () {
        // Test low priority
        final lowReminder = testReminder.copyWith(priority: ReminderPriority.low);
        expect(lowReminder.toMap()['priority'], 'low');

        // Test medium priority
        final mediumReminder = testReminder.copyWith(priority: ReminderPriority.medium);
        expect(mediumReminder.toMap()['priority'], 'medium');

        // Test high priority
        final highReminder = testReminder.copyWith(priority: ReminderPriority.high);
        expect(highReminder.toMap()['priority'], 'high');
      });

      test('should serialize DateTime fields as ISO 8601 strings', () {
        // Arrange
        final specificDateTime = DateTime(2024, 3, 15, 14, 30, 45, 123);
        final reminder = testReminder.copyWith(
          createdAt: specificDateTime,
          updatedAt: specificDateTime,
        );

        // Act
        final map = reminder.toMap();

        // Assert
        expect(map['createdAt'], specificDateTime.toIso8601String());
        expect(map['updatedAt'], specificDateTime.toIso8601String());
        expect(map['createdAt'], contains('2024-03-15'));
        expect(map['createdAt'], contains('14:30:45'));
      });
    });

    group('Deserialization - fromMap()', () {
      test('should create reminder from map with all fields', () {
        // Arrange
        final map = {
          'id': 'reminder_123',
          'content': 'Buy groceries for dinner',
          'userId': 'user_456',
          'boardId': 'board_789',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          'tags': ['shopping', 'urgent'],
          'priority': 'high',
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.id, 'reminder_123');
        expect(reminder.content, 'Buy groceries for dinner');
        expect(reminder.userId, 'user_456');
        expect(reminder.boardId, 'board_789');
        expect(reminder.createdAt, testDateTime);
        expect(reminder.updatedAt, testDateTime);
        expect(reminder.tags, ['shopping', 'urgent']);
        expect(reminder.priority, ReminderPriority.high);
      });

      test('should handle missing tags field with empty list', () {
        // Arrange
        final map = {
          'id': 'test_id',
          'content': 'Test content',
          'userId': 'test_user',
          'boardId': 'test_board',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          // tags field missing
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.tags, isEmpty);
      });

      test('should handle null tags field with empty list', () {
        // Arrange
        final map = {
          'id': 'test_id',
          'content': 'Test content',
          'userId': 'test_user',
          'boardId': 'test_board',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          'tags': null,
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.tags, isEmpty);
      });

      test('should handle missing priority field with medium default', () {
        // Arrange
        final map = {
          'id': 'test_id',
          'content': 'Test content',
          'userId': 'test_user',
          'boardId': 'test_board',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          // priority field missing
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.priority, ReminderPriority.medium);
      });

      test('should handle null priority field with medium default', () {
        // Arrange
        final map = {
          'id': 'test_id',
          'content': 'Test content',
          'userId': 'test_user',
          'boardId': 'test_board',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          'priority': null,
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.priority, ReminderPriority.medium);
      });

      test('should parse all priority levels correctly', () {
        // Test low priority
        final lowMap = {
          'id': 'test_id',
          'content': 'Test',
          'userId': 'user',
          'boardId': 'board',
          'createdAt': testDateTime.toIso8601String(),
          'updatedAt': testDateTime.toIso8601String(),
          'priority': 'low',
        };
        expect(Reminder.fromMap(lowMap).priority, ReminderPriority.low);

        // Test medium priority
        final mediumMap = {...lowMap, 'priority': 'medium'};
        expect(Reminder.fromMap(mediumMap).priority, ReminderPriority.medium);

        // Test high priority
        final highMap = {...lowMap, 'priority': 'high'};
        expect(Reminder.fromMap(highMap).priority, ReminderPriority.high);
      });

      test('should parse ISO 8601 DateTime strings correctly', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 1, 10, 0, 0);
        final updatedAt = DateTime(2024, 1, 2, 15, 30, 0);
        final map = {
          'id': 'test_id',
          'content': 'Test',
          'userId': 'user',
          'boardId': 'board',
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
        };

        // Act
        final reminder = Reminder.fromMap(map);

        // Assert
        expect(reminder.createdAt, createdAt);
        expect(reminder.updatedAt, updatedAt);
      });
    });

    group('Serialization Round-Trip', () {
      test('should preserve all data through toMap/fromMap cycle', () {
        // Arrange
        final original = testReminder;

        // Act
        final map = original.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.id, original.id);
        expect(restored.content, original.content);
        expect(restored.userId, original.userId);
        expect(restored.boardId, original.boardId);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
        expect(restored.tags, original.tags);
        expect(restored.priority, original.priority);
      });

      test('should preserve reminder with empty tags', () {
        // Arrange
        final original = testReminder.copyWith(tags: []);

        // Act
        final map = original.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.tags, isEmpty);
        expect(restored, original);
      });

      test('should preserve reminder with multiple tags', () {
        // Arrange
        final original = testReminder.copyWith(
          tags: ['tag1', 'tag2', 'tag3', 'tag4'],
        );

        // Act
        final map = original.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.tags, ['tag1', 'tag2', 'tag3', 'tag4']);
        expect(restored, original);
      });

      test('should preserve all priority levels through round-trip', () {
        for (final priority in ReminderPriority.values) {
          // Arrange
          final original = testReminder.copyWith(priority: priority);

          // Act
          final map = original.toMap();
          final restored = Reminder.fromMap(map);

          // Assert
          expect(restored.priority, priority);
          expect(restored, original);
        }
      });

      test('should preserve DateTime precision through round-trip', () {
        // Arrange
        final preciseDateTime = DateTime(2024, 3, 15, 14, 30, 45, 123, 456);
        final original = testReminder.copyWith(
          createdAt: preciseDateTime,
          updatedAt: preciseDateTime,
        );

        // Act
        final map = original.toMap();
        final restored = Reminder.fromMap(map);

        // Assert - ISO 8601 preserves milliseconds but not microseconds
        expect(restored.createdAt.year, preciseDateTime.year);
        expect(restored.createdAt.month, preciseDateTime.month);
        expect(restored.createdAt.day, preciseDateTime.day);
        expect(restored.createdAt.hour, preciseDateTime.hour);
        expect(restored.createdAt.minute, preciseDateTime.minute);
        expect(restored.createdAt.second, preciseDateTime.second);
        expect(restored.createdAt.millisecond, preciseDateTime.millisecond);
      });
    });

    group('Equatable Equality', () {
      test('should be equal when all fields are identical', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = Reminder(
          id: 'reminder_123',
          content: 'Buy groceries for dinner',
          userId: 'user_456',
          boardId: 'board_789',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          tags: ['shopping', 'urgent'],
          priority: ReminderPriority.high,
        );

        // Assert
        expect(reminder1, equals(reminder2));
        expect(reminder1.hashCode, equals(reminder2.hashCode));
      });

      test('should not be equal when id differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(id: 'different_id');

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when content differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(content: 'Different content');

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when userId differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(userId: 'different_user');

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when boardId differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(boardId: 'different_board');

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when createdAt differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(
          createdAt: testDateTime.add(const Duration(seconds: 1)),
        );

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when updatedAt differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(
          updatedAt: testDateTime.add(const Duration(seconds: 1)),
        );

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when tags differ', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(tags: ['different', 'tags']);

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when tag order differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(tags: ['urgent', 'shopping']);

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal when priority differs', () {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(priority: ReminderPriority.low);

        // Assert
        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should handle equality with empty tags', () {
        // Arrange
        final reminder1 = testReminder.copyWith(tags: []);
        final reminder2 = testReminder.copyWith(tags: []);

        // Assert
        expect(reminder1, equals(reminder2));
      });
    });

    group('copyWith()', () {
      test('should return identical reminder when no parameters provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith();

        // Assert
        expect(copied, equals(testReminder));
        expect(copied.id, testReminder.id);
        expect(copied.content, testReminder.content);
        expect(copied.userId, testReminder.userId);
        expect(copied.boardId, testReminder.boardId);
        expect(copied.createdAt, testReminder.createdAt);
        expect(copied.updatedAt, testReminder.updatedAt);
        expect(copied.tags, testReminder.tags);
        expect(copied.priority, testReminder.priority);
      });

      test('should update id when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(id: 'new_id');

        // Assert
        expect(copied.id, 'new_id');
        expect(copied.content, testReminder.content);
        expect(copied.userId, testReminder.userId);
      });

      test('should update content when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(content: 'New content');

        // Assert
        expect(copied.content, 'New content');
        expect(copied.id, testReminder.id);
      });

      test('should update userId when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(userId: 'new_user');

        // Assert
        expect(copied.userId, 'new_user');
        expect(copied.id, testReminder.id);
      });

      test('should update boardId when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(boardId: 'new_board');

        // Assert
        expect(copied.boardId, 'new_board');
        expect(copied.id, testReminder.id);
      });

      test('should update createdAt when provided', () {
        // Arrange
        final newDateTime = DateTime(2024, 12, 31);

        // Act
        final copied = testReminder.copyWith(createdAt: newDateTime);

        // Assert
        expect(copied.createdAt, newDateTime);
        expect(copied.updatedAt, testReminder.updatedAt);
      });

      test('should update updatedAt when provided', () {
        // Arrange
        final newDateTime = DateTime(2024, 12, 31);

        // Act
        final copied = testReminder.copyWith(updatedAt: newDateTime);

        // Assert
        expect(copied.updatedAt, newDateTime);
        expect(copied.createdAt, testReminder.createdAt);
      });

      test('should update tags when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(tags: ['new', 'tags']);

        // Assert
        expect(copied.tags, ['new', 'tags']);
        expect(copied.id, testReminder.id);
      });

      test('should update priority when provided', () {
        // Arrange & Act
        final copied = testReminder.copyWith(priority: ReminderPriority.low);

        // Assert
        expect(copied.priority, ReminderPriority.low);
        expect(copied.id, testReminder.id);
      });

      test('should update multiple fields at once', () {
        // Arrange
        final newDateTime = DateTime(2024, 12, 31);

        // Act
        final copied = testReminder.copyWith(
          content: 'Updated content',
          boardId: 'new_board',
          updatedAt: newDateTime,
          tags: ['updated'],
          priority: ReminderPriority.low,
        );

        // Assert
        expect(copied.content, 'Updated content');
        expect(copied.boardId, 'new_board');
        expect(copied.updatedAt, newDateTime);
        expect(copied.tags, ['updated']);
        expect(copied.priority, ReminderPriority.low);
        // Unchanged fields
        expect(copied.id, testReminder.id);
        expect(copied.userId, testReminder.userId);
        expect(copied.createdAt, testReminder.createdAt);
      });

      test('should allow setting tags to empty list', () {
        // Arrange & Act
        final copied = testReminder.copyWith(tags: []);

        // Assert
        expect(copied.tags, isEmpty);
      });

      test('should create independent copy (not reference)', () {
        // Arrange
        final copied = testReminder.copyWith(content: 'Modified');

        // Assert
        expect(copied.content, 'Modified');
        expect(testReminder.content, 'Buy groceries for dinner');
        expect(copied, isNot(same(testReminder)));
      });
    });

    group('ReminderPriority Enum', () {
      test('should have three priority levels', () {
        // Assert
        expect(ReminderPriority.values.length, 3);
        expect(ReminderPriority.values, contains(ReminderPriority.low));
        expect(ReminderPriority.values, contains(ReminderPriority.medium));
        expect(ReminderPriority.values, contains(ReminderPriority.high));
      });

      test('toJson() should return enum name', () {
        // Assert
        expect(ReminderPriority.low.toJson(), 'low');
        expect(ReminderPriority.medium.toJson(), 'medium');
        expect(ReminderPriority.high.toJson(), 'high');
      });

      test('fromJson() should parse valid priority strings', () {
        // Assert
        expect(ReminderPriority.fromJson('low'), ReminderPriority.low);
        expect(ReminderPriority.fromJson('medium'), ReminderPriority.medium);
        expect(ReminderPriority.fromJson('high'), ReminderPriority.high);
      });

      test('fromJson() should default to medium for invalid strings', () {
        // Assert
        expect(ReminderPriority.fromJson('invalid'), ReminderPriority.medium);
        expect(ReminderPriority.fromJson(''), ReminderPriority.medium);
        expect(ReminderPriority.fromJson('LOW'), ReminderPriority.medium);
        expect(ReminderPriority.fromJson('High'), ReminderPriority.medium);
      });

      test('should support round-trip conversion', () {
        // Test all priority levels
        for (final priority in ReminderPriority.values) {
          // Act
          final json = priority.toJson();
          final restored = ReminderPriority.fromJson(json);

          // Assert
          expect(restored, priority);
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long content', () {
        // Arrange
        final longContent = 'A' * 500; // Maximum allowed length
        final reminder = testReminder.copyWith(content: longContent);

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.content, longContent);
        expect(restored.content.length, 500);
      });

      test('should handle special characters in content', () {
        // Arrange
        final specialContent = 'Test with émojis 🎉 and spëcial çhars!';
        final reminder = testReminder.copyWith(content: specialContent);

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.content, specialContent);
      });

      test('should handle many tags', () {
        // Arrange
        final manyTags = List.generate(20, (i) => 'tag$i');
        final reminder = testReminder.copyWith(tags: manyTags);

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.tags, manyTags);
        expect(restored.tags.length, 20);
      });

      test('should handle tags with special characters', () {
        // Arrange
        final specialTags = ['tag-with-dash', 'tag_with_underscore', 'tag.with.dot'];
        final reminder = testReminder.copyWith(tags: specialTags);

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.tags, specialTags);
      });

      test('should handle DateTime at epoch', () {
        // Arrange
        final epochTime = DateTime.fromMillisecondsSinceEpoch(0);
        final reminder = testReminder.copyWith(
          createdAt: epochTime,
          updatedAt: epochTime,
        );

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.createdAt, epochTime);
        expect(restored.updatedAt, epochTime);
      });

      test('should handle DateTime far in the future', () {
        // Arrange
        final futureTime = DateTime(2099, 12, 31, 23, 59, 59);
        final reminder = testReminder.copyWith(
          createdAt: futureTime,
          updatedAt: futureTime,
        );

        // Act
        final map = reminder.toMap();
        final restored = Reminder.fromMap(map);

        // Assert
        expect(restored.createdAt, futureTime);
        expect(restored.updatedAt, futureTime);
      });
    });
  });
}
