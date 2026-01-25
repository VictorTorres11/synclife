import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/notification_reaction.dart';
import '../../domain/services/notification_reaction_service.dart';

/// Firebase implementation of notification reaction service
class FirebaseNotificationReactionService
    implements NotificationReactionService {
  FirebaseNotificationReactionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> sendReaction({
    required String notificationId,
    required String userId,
    required EmojiReaction reaction,
  }) async {
    try {
      final reactionId = '${notificationId}_$userId';
      final now = DateTime.now();

      // Use a transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final reactionRef =
            _firestore.collection('notificationReactions').doc(reactionId);

        final summaryRef = _firestore
            .collection('notificationReactionSummaries')
            .doc(notificationId);

        // Get existing reaction and summary
        final existingReactionDoc = await transaction.get(reactionRef);
        final summaryDoc = await transaction.get(summaryRef);

        NotificationReactionSummary currentSummary;
        if (summaryDoc.exists) {
          currentSummary = NotificationReactionSummary.fromMap(
            summaryDoc.data()!,
          );
        } else {
          currentSummary = NotificationReactionSummary(
            notificationId: notificationId,
            reactionCounts: {},
            userReactions: {},
            totalReactions: 0,
          );
        }

        // Handle existing reaction
        if (existingReactionDoc.exists) {
          final existingReaction = NotificationReaction.fromMap(
            existingReactionDoc.data()!,
          );

          // If same reaction, remove it (toggle behavior)
          if (existingReaction.reaction == reaction) {
            transaction.delete(reactionRef);

            // Update summary - remove reaction
            final updatedCounts =
                Map<EmojiReaction, int>.from(currentSummary.reactionCounts);
            final currentCount = updatedCounts[reaction] ?? 0;
            if (currentCount > 1) {
              updatedCounts[reaction] = currentCount - 1;
            } else {
              updatedCounts.remove(reaction);
            }

            final updatedUserReactions =
                Map<String, EmojiReaction>.from(currentSummary.userReactions);
            updatedUserReactions.remove(userId);

            final updatedSummary = currentSummary.copyWith(
              reactionCounts: updatedCounts,
              userReactions: updatedUserReactions,
              totalReactions: currentSummary.totalReactions - 1,
            );

            if (updatedSummary.totalReactions > 0) {
              transaction.set(summaryRef, updatedSummary.toMap());
            } else {
              transaction.delete(summaryRef);
            }
            return;
          } else {
            // Different reaction - update existing
            final newReaction = existingReaction.copyWith(
              reaction: reaction,
              createdAt: now,
            );
            transaction.set(reactionRef, newReaction.toMap());

            // Update summary - remove old reaction, add new one
            final updatedCounts =
                Map<EmojiReaction, int>.from(currentSummary.reactionCounts);

            // Remove old reaction count
            final oldCount = updatedCounts[existingReaction.reaction] ?? 0;
            if (oldCount > 1) {
              updatedCounts[existingReaction.reaction] = oldCount - 1;
            } else {
              updatedCounts.remove(existingReaction.reaction);
            }

            // Add new reaction count
            updatedCounts[reaction] = (updatedCounts[reaction] ?? 0) + 1;

            final updatedUserReactions =
                Map<String, EmojiReaction>.from(currentSummary.userReactions);
            updatedUserReactions[userId] = reaction;

            final updatedSummary = currentSummary.copyWith(
              reactionCounts: updatedCounts,
              userReactions: updatedUserReactions,
            );

            transaction.set(summaryRef, updatedSummary.toMap());
          }
        } else {
          // New reaction
          final newReaction = NotificationReaction(
            id: reactionId,
            notificationId: notificationId,
            userId: userId,
            reaction: reaction,
            createdAt: now,
          );
          transaction.set(reactionRef, newReaction.toMap());

          // Update summary - add new reaction
          final updatedCounts =
              Map<EmojiReaction, int>.from(currentSummary.reactionCounts);
          updatedCounts[reaction] = (updatedCounts[reaction] ?? 0) + 1;

          final updatedUserReactions =
              Map<String, EmojiReaction>.from(currentSummary.userReactions);
          updatedUserReactions[userId] = reaction;

          final updatedSummary = currentSummary.copyWith(
            reactionCounts: updatedCounts,
            userReactions: updatedUserReactions,
            totalReactions: currentSummary.totalReactions + 1,
          );

          transaction.set(summaryRef, updatedSummary.toMap());
        }
      });

      debugPrint(
          'Successfully processed reaction for notification $notificationId');
    } catch (e) {
      debugPrint('Error sending reaction: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeReaction({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final reactionId = '${notificationId}_$userId';

      await _firestore.runTransaction((transaction) async {
        final reactionRef =
            _firestore.collection('notificationReactions').doc(reactionId);

        final summaryRef = _firestore
            .collection('notificationReactionSummaries')
            .doc(notificationId);

        final reactionDoc = await transaction.get(reactionRef);
        if (!reactionDoc.exists) {
          return; // No reaction to remove
        }

        final reaction = NotificationReaction.fromMap(reactionDoc.data()!);
        transaction.delete(reactionRef);

        // Update summary
        final summaryDoc = await transaction.get(summaryRef);
        if (summaryDoc.exists) {
          final summary =
              NotificationReactionSummary.fromMap(summaryDoc.data()!);

          final updatedCounts =
              Map<EmojiReaction, int>.from(summary.reactionCounts);
          final currentCount = updatedCounts[reaction.reaction] ?? 0;
          if (currentCount > 1) {
            updatedCounts[reaction.reaction] = currentCount - 1;
          } else {
            updatedCounts.remove(reaction.reaction);
          }

          final updatedUserReactions =
              Map<String, EmojiReaction>.from(summary.userReactions);
          updatedUserReactions.remove(userId);

          final updatedSummary = summary.copyWith(
            reactionCounts: updatedCounts,
            userReactions: updatedUserReactions,
            totalReactions: summary.totalReactions - 1,
          );

          if (updatedSummary.totalReactions > 0) {
            transaction.set(summaryRef, updatedSummary.toMap());
          } else {
            transaction.delete(summaryRef);
          }
        }
      });

      debugPrint(
          'Successfully removed reaction for notification $notificationId');
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  @override
  Future<NotificationReactionSummary?> getReactionSummary(
      String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notificationReactionSummaries')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return NotificationReactionSummary.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting reaction summary: $e');
      return null;
    }
  }

  @override
  Future<List<NotificationReaction>> getReactions(String notificationId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notificationReactions')
          .where('notificationId', isEqualTo: notificationId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationReaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting reactions: $e');
      return [];
    }
  }

  @override
  Future<NotificationReaction?> getUserReaction({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final reactionId = '${notificationId}_$userId';
      final doc = await _firestore
          .collection('notificationReactions')
          .doc(reactionId)
          .get();

      if (doc.exists) {
        return NotificationReaction.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user reaction: $e');
      return null;
    }
  }

  @override
  Stream<NotificationReactionSummary> watchReactionSummary(
      String notificationId) {
    return _firestore
        .collection('notificationReactionSummaries')
        .doc(notificationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return NotificationReactionSummary.fromMap(doc.data()!);
      } else {
        return NotificationReactionSummary(
          notificationId: notificationId,
          reactionCounts: {},
          userReactions: {},
          totalReactions: 0,
        );
      }
    });
  }

  @override
  Future<void> processNotificationReaction({
    required String notificationId,
    required String userId,
    required String reactionValue,
  }) async {
    try {
      final reaction = EmojiReaction.fromValue(reactionValue);
      await sendReaction(
        notificationId: notificationId,
        userId: userId,
        reaction: reaction,
      );

      debugPrint(
          'Processed notification reaction: $reactionValue for notification $notificationId');
    } catch (e) {
      debugPrint('Error processing notification reaction: $e');
      rethrow;
    }
  }
}
