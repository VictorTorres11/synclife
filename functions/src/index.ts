import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Scheduled function that runs every hour to process pending notifications
 */
export const processScheduledNotifications = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Processing scheduled notifications...');
    
    try {
      const now = new Date();
      
      // Get all pending notifications that should be sent now
      const pendingNotifications = await db
        .collection('scheduledNotifications')
        .where('isProcessed', '==', false)
        .where('scheduledTime', '<=', now.toISOString())
        .get();

      console.log(`Found ${pendingNotifications.size} pending notifications`);

      const batch = db.batch();
      const notificationPromises: Promise<void>[] = [];

      for (const doc of pendingNotifications.docs) {
        const notification = doc.data();
        
        // Check user's notification preferences and quiet hours
        const userPrefs = await getUserNotificationPreferences(notification.userId);
        
        if (!userPrefs || !shouldSendNotification(notification, userPrefs, now)) {
          console.log(`Skipping notification ${doc.id} due to preferences or quiet hours`);
          continue;
        }

        // Get user's FCM token
        const userToken = await getUserFCMToken(notification.userId);
        
        if (!userToken) {
          console.log(`No FCM token found for user ${notification.userId}`);
          continue;
        }

        // Send the notification
        const notificationPromise = sendFCMNotification(
          userToken,
          notification.title,
          notification.body,
          notification.data
        );
        
        notificationPromises.push(notificationPromise);

        // Mark as processed
        batch.update(doc.ref, {
          isProcessed: true,
          processedAt: now.toISOString(),
          updatedAt: now.toISOString(),
        });
      }

      // Execute all operations
      await Promise.all([
        batch.commit(),
        ...notificationPromises
      ]);

      console.log(`Successfully processed ${pendingNotifications.size} notifications`);
      
    } catch (error) {
      console.error('Error processing scheduled notifications:', error);
      throw error;
    }
  });

/**
 * Function to setup daily notification schedules for a user
 */
export const setupDailySchedules = functions.firestore
  .document('userProfiles/{userId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    
    try {
      // Only process if the document was created or updated
      if (!change.after.exists) {
        console.log(`User profile deleted for ${userId}, skipping schedule setup`);
        return;
      }

      console.log(`Setting up daily schedules for user ${userId}`);
      
      // Get user preferences
      const userPrefs = await getUserNotificationPreferences(userId);
      
      if (!userPrefs) {
        console.log(`No notification preferences found for user ${userId}`);
        return;
      }

      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);

      // Cancel existing scheduled notifications for today/tomorrow
      await cancelExistingSchedules(userId, now, tomorrow);

      // Schedule morning summary if enabled
      if (userPrefs.enableDailySummary) {
        const morningTime = new Date(tomorrow);
        morningTime.setHours(userPrefs.morningTime.hour, userPrefs.morningTime.minute, 0, 0);
        
        await scheduleMorningSummaryNotification(userId, morningTime);
      }

      // Schedule night summary if enabled
      if (userPrefs.enableNightSummary) {
        const nightTime = new Date(now);
        nightTime.setHours(userPrefs.nightTime.hour, userPrefs.nightTime.minute, 0, 0);
        
        // Only schedule if it's in the future
        if (nightTime > now) {
          await scheduleNightSummaryNotification(userId, nightTime);
        }
      }

      console.log(`Successfully setup daily schedules for user ${userId}`);
      
    } catch (error) {
      console.error(`Error setting up daily schedules for user ${userId}:`, error);
    }
  });

/**
 * Function to send team activity notifications when tasks are updated
 */
export const sendTeamActivityNotification = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const taskId = context.params.taskId;
    
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      
      // Only process if task was completed or assigned to someone
      const wasCompleted = !beforeData.isCompleted && afterData.isCompleted;
      const wasAssigned = beforeData.assignedTo !== afterData.assignedTo && afterData.assignedTo;
      
      if (!wasCompleted && !wasAssigned) {
        return;
      }

      console.log(`Task ${taskId} was ${wasCompleted ? 'completed' : 'assigned'}`);
      
      // Get board information
      const boardDoc = await db.collection('boards').doc(afterData.boardId).get();
      
      if (!boardDoc.exists || boardDoc.data()?.type !== 'shared') {
        console.log(`Task ${taskId} is not on a shared board, skipping team notification`);
        return;
      }

      const board = boardDoc.data()!;
      const memberIds = board.memberIds as string[];
      
      // Get the user who performed the action
      const actorId = afterData.assignedTo || afterData.updatedBy;
      const actorDoc = await db.collection('users').doc(actorId).get();
      const actorName = actorDoc.exists ? 
        (actorDoc.data()?.displayName || 'Someone') : 'Someone';

      // Send notifications to other board members
      const notificationPromises = memberIds
        .filter(memberId => memberId !== actorId) // Don't notify the actor
        .map(async (memberId) => {
          // Check if user has team notifications enabled
          const userPrefs = await getUserNotificationPreferences(memberId);
          
          if (!userPrefs?.enableTeamUpdates) {
            return;
          }

          const action = wasCompleted ? 'completed' : 'was assigned';
          const title = '👥 Team Update';
          const body = `${actorName} ${action} "${afterData.title}"`;
          const notificationId = `team_${afterData.boardId}_${taskId}_${Date.now()}`;
          
          // Schedule immediate notification
          await db.collection('scheduledNotifications').add({
            id: notificationId,
            userId: memberId,
            type: 'teamActivity',
            title,
            body,
            scheduledTime: new Date().toISOString(),
            data: {
              boardId: afterData.boardId,
              boardName: board.name,
              taskId,
              taskTitle: afterData.title,
              actorName,
              action: wasCompleted ? 'completed' : 'assigned',
              notificationId, // Include notification ID for reactions
              enableReactions: true,
            },
            isProcessed: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          });
        });

      await Promise.all(notificationPromises);
      
      console.log(`Sent team activity notifications for task ${taskId}`);
      
    } catch (error) {
      console.error(`Error sending team activity notification for task ${taskId}:`, error);
    }
  });

/**
 * Function to handle emoji reactions from notifications
 */
export const processNotificationReaction = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { notificationId, reaction } = data;
  const userId = context.auth.uid;

  if (!notificationId || !reaction) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Processing reaction ${reaction} for notification ${notificationId} by user ${userId}`);

    // Validate reaction
    const validReactions = ['thumbs_up', 'heart', 'fire', 'clap', 'rocket', 'star'];
    if (!validReactions.includes(reaction)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid reaction type');
    }

    const reactionId = `${notificationId}_${userId}`;
    const now = new Date();

    // Use a transaction to ensure consistency
    await db.runTransaction(async (transaction) => {
      const reactionRef = db.collection('notificationReactions').doc(reactionId);
      const summaryRef = db.collection('notificationReactionSummaries').doc(notificationId);

      // Get existing reaction and summary
      const existingReactionDoc = await transaction.get(reactionRef);
      const summaryDoc = await transaction.get(summaryRef);

      let currentSummary: any;
      if (summaryDoc.exists) {
        currentSummary = summaryDoc.data()!;
      } else {
        currentSummary = {
          notificationId,
          reactionCounts: {},
          userReactions: {},
          totalReactions: 0,
        };
      }

      // Handle existing reaction
      if (existingReactionDoc.exists) {
        const existingReaction = existingReactionDoc.data()!;

        // If same reaction, remove it (toggle behavior)
        if (existingReaction.reaction === reaction) {
          transaction.delete(reactionRef);
          
          // Update summary - remove reaction
          const updatedCounts = { ...currentSummary.reactionCounts };
          const currentCount = updatedCounts[reaction] || 0;
          if (currentCount > 1) {
            updatedCounts[reaction] = currentCount - 1;
          } else {
            delete updatedCounts[reaction];
          }

          const updatedUserReactions = { ...currentSummary.userReactions };
          delete updatedUserReactions[userId];

          const updatedSummary = {
            ...currentSummary,
            reactionCounts: updatedCounts,
            userReactions: updatedUserReactions,
            totalReactions: currentSummary.totalReactions - 1,
          };

          if (updatedSummary.totalReactions > 0) {
            transaction.set(summaryRef, updatedSummary);
          } else {
            transaction.delete(summaryRef);
          }
          return { action: 'removed', reaction };
        } else {
          // Different reaction - update existing
          const newReaction = {
            id: reactionId,
            notificationId,
            userId,
            reaction,
            createdAt: now.toISOString(),
          };
          transaction.set(reactionRef, newReaction);

          // Update summary - remove old reaction, add new one
          const updatedCounts = { ...currentSummary.reactionCounts };
          
          // Remove old reaction count
          const oldCount = updatedCounts[existingReaction.reaction] || 0;
          if (oldCount > 1) {
            updatedCounts[existingReaction.reaction] = oldCount - 1;
          } else {
            delete updatedCounts[existingReaction.reaction];
          }

          // Add new reaction count
          updatedCounts[reaction] = (updatedCounts[reaction] || 0) + 1;

          const updatedUserReactions = { ...currentSummary.userReactions };
          updatedUserReactions[userId] = reaction;

          const updatedSummary = {
            ...currentSummary,
            reactionCounts: updatedCounts,
            userReactions: updatedUserReactions,
          };

          transaction.set(summaryRef, updatedSummary);
          return { action: 'updated', reaction, previousReaction: existingReaction.reaction };
        }
      } else {
        // New reaction
        const newReaction = {
          id: reactionId,
          notificationId,
          userId,
          reaction,
          createdAt: now.toISOString(),
        };
        transaction.set(reactionRef, newReaction);

        // Update summary - add new reaction
        const updatedCounts = { ...currentSummary.reactionCounts };
        updatedCounts[reaction] = (updatedCounts[reaction] || 0) + 1;

        const updatedUserReactions = { ...currentSummary.userReactions };
        updatedUserReactions[userId] = reaction;

        const updatedSummary = {
          ...currentSummary,
          reactionCounts: updatedCounts,
          userReactions: updatedUserReactions,
          totalReactions: currentSummary.totalReactions + 1,
        };

        transaction.set(summaryRef, updatedSummary);
        return { action: 'added', reaction };
      }
    });

    console.log(`Successfully processed reaction ${reaction} for notification ${notificationId}`);
    return { success: true, notificationId, reaction };
    
  } catch (error) {
    console.error(`Error processing reaction for notification ${notificationId}:`, error);
    throw new functions.https.HttpsError('internal', 'Failed to process reaction');
  }
});

/**
 * Daily processing function that runs at midnight UTC
 */
export const dailyProcessing = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting daily processing...');
    
    try {
      // Get all users who need daily processing
      const usersSnapshot = await db.collection('users').get();
      
      const processingPromises = usersSnapshot.docs.map(async (userDoc) => {
        const userId = userDoc.id;
        
        try {
          // Generate and schedule night summary for today
          await generateAndScheduleNightSummary(userId);
          
          // Setup schedules for tomorrow
          await setupTomorrowSchedules(userId);
          
        } catch (error) {
          console.error(`Error in daily processing for user ${userId}:`, error);
        }
      });

      await Promise.all(processingPromises);
      
      console.log(`Daily processing completed for ${usersSnapshot.size} users`);
      
    } catch (error) {
      console.error('Error in daily processing:', error);
      throw error;
    }
  });

// Helper functions

async function getUserNotificationPreferences(userId: string) {
  try {
    // Try to get preferences from user's local storage (simulated via Firestore)
    const prefsDoc = await db.collection('userNotificationPreferences').doc(userId).get();
    
    if (prefsDoc.exists) {
      return prefsDoc.data();
    }
    
    // Return default preferences if none found
    return {
      enablePushNotifications: true,
      enableDailySummary: true,
      enableTeamUpdates: true,
      enableNightSummary: true,
      enableTaskReminders: true,
      morningTime: { hour: 8, minute: 0 },
      nightTime: { hour: 22, minute: 0 },
      quietHoursStart: { hour: 22, minute: 0 },
      quietHoursEnd: { hour: 8, minute: 0 },
      enableQuietHours: true,
    };
  } catch (error) {
    console.error(`Error getting notification preferences for user ${userId}:`, error);
    return null;
  }
}

async function getUserFCMToken(userId: string): Promise<string | null> {
  try {
    const tokenDoc = await db.collection('deviceTokens').doc(userId).get();
    
    if (tokenDoc.exists) {
      const data = tokenDoc.data()!;
      return data.token || null;
    }
    
    return null;
  } catch (error) {
    console.error(`Error getting FCM token for user ${userId}:`, error);
    return null;
  }
}

function shouldSendNotification(notification: any, userPrefs: any, currentTime: Date): boolean {
  // Check if push notifications are enabled
  if (!userPrefs.enablePushNotifications) {
    return false;
  }

  // Check notification type preferences
  switch (notification.type) {
    case 'morningSummary':
      if (!userPrefs.enableDailySummary) return false;
      break;
    case 'nightSummary':
      if (!userPrefs.enableNightSummary) return false;
      break;
    case 'teamActivity':
      if (!userPrefs.enableTeamUpdates) return false;
      break;
    case 'taskReminder':
      if (!userPrefs.enableTaskReminders) return false;
      break;
  }

  // Check quiet hours
  if (userPrefs.enableQuietHours) {
    const currentHour = currentTime.getHours();
    const currentMinute = currentTime.getMinutes();
    const currentMinutes = currentHour * 60 + currentMinute;
    
    const startMinutes = userPrefs.quietHoursStart.hour * 60 + userPrefs.quietHoursStart.minute;
    const endMinutes = userPrefs.quietHoursEnd.hour * 60 + userPrefs.quietHoursEnd.minute;
    
    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startMinutes > endMinutes) {
      if (currentMinutes >= startMinutes || currentMinutes <= endMinutes) {
        return false;
      }
    } else {
      // Handle same-day quiet hours (e.g., 12:00 to 14:00)
      if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
        return false;
      }
    }
  }

  return true;
}

async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data?: any
): Promise<void> {
  try {
    const message: admin.messaging.Message = {
      token,
      notification: {
        title,
        body,
      },
      data: data ? Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      ) : undefined,
      android: {
        notification: {
          channelId: 'synclife_notifications',
          priority: 'high' as const,
          // Add action buttons for emoji reactions
          actions: [
            {
              action: 'reaction_thumbs_up',
              title: '👍',
            },
            {
              action: 'reaction_heart',
              title: '❤️',
            },
            {
              action: 'reaction_fire',
              title: '🔥',
            },
          ],
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            badge: 1,
            sound: 'default',
            // Add category for action buttons on iOS
            category: 'NOTIFICATION_WITH_REACTIONS',
          },
        },
      },
    };

    const response = await messaging.send(message);
    console.log('Successfully sent message:', response);
    
  } catch (error) {
    console.error('Error sending FCM notification:', error);
    throw error;
  }
}

async function cancelExistingSchedules(userId: string, startDate: Date, endDate: Date): Promise<void> {
  const existingNotifications = await db
    .collection('scheduledNotifications')
    .where('userId', '==', userId)
    .where('isProcessed', '==', false)
    .where('scheduledTime', '>=', startDate.toISOString())
    .where('scheduledTime', '<', endDate.toISOString())
    .get();

  const batch = db.batch();
  existingNotifications.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  if (!existingNotifications.empty) {
    await batch.commit();
    console.log(`Cancelled ${existingNotifications.size} existing notifications for user ${userId}`);
  }
}

async function scheduleMorningSummaryNotification(userId: string, scheduledTime: Date): Promise<void> {
  const morningSummary = await generateMorningSummary(userId);
  const notificationId = `morning_${userId}_${scheduledTime.toISOString().split('T')[0]}`;
  
  await db.collection('scheduledNotifications').add({
    id: notificationId,
    userId,
    type: 'morningSummary',
    title: '🌅 Good Morning!',
    body: generateMorningSummaryBody(morningSummary),
    scheduledTime: scheduledTime.toISOString(),
    data: {
      ...morningSummary,
      notificationId, // Include notification ID for reactions
      enableReactions: true,
    },
    isProcessed: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  
  console.log(`Scheduled morning summary for user ${userId} at ${scheduledTime.toISOString()}`);
}

async function scheduleNightSummaryNotification(userId: string, scheduledTime: Date): Promise<void> {
  const nightSummary = await generateNightSummary(userId);
  const notificationId = `night_${userId}_${scheduledTime.toISOString().split('T')[0]}`;
  
  await db.collection('scheduledNotifications').add({
    id: notificationId,
    userId,
    type: 'nightSummary',
    title: '🌙 Daily Recap',
    body: generateNightSummaryBody(nightSummary),
    scheduledTime: scheduledTime.toISOString(),
    data: {
      ...nightSummary,
      notificationId, // Include notification ID for reactions
      enableReactions: true,
    },
    isProcessed: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  
  console.log(`Scheduled night summary for user ${userId} at ${scheduledTime.toISOString()}`);
}

async function generateMorningSummary(userId: string) {
  const today = new Date();
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const endOfDay = new Date(startOfDay);
  endOfDay.setDate(endOfDay.getDate() + 1);

  // Get user stats for streak info
  const userStatsDoc = await db.collection('userStats').doc(userId).get();
  const userStats = userStatsDoc.exists ? userStatsDoc.data() : { currentStreak: 0 };

  // Get today's tasks
  const tasksSnapshot = await db
    .collection('tasks')
    .where('assignedTo', '==', userId)
    .where('dueDate', '>=', startOfDay.toISOString())
    .where('dueDate', '<', endOfDay.toISOString())
    .get();

  const tasks = tasksSnapshot.docs.map(doc => doc.data());
  const essentialTasks = tasks.filter(task => task.tags?.includes('essential')).length;

  return {
    userId,
    tasksForToday: tasks.map(task => ({
      id: task.id,
      title: task.title,
      isEssential: task.tags?.includes('essential') || false,
      tags: task.tags || [],
    })),
    essentialTasksCount: essentialTasks,
    currentStreak: userStats.currentStreak || 0,
    motivationalMessage: generateMotivationalMessage(userStats.currentStreak || 0, essentialTasks),
  };
}

async function generateNightSummary(userId: string) {
  const today = new Date();
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

  // Get user stats
  const userStatsDoc = await db.collection('userStats').doc(userId).get();
  const userStats = userStatsDoc.exists ? userStatsDoc.data() : {
    currentStreak: 0,
    longestStreak: 0,
    totalXP: 0,
    level: 1,
  };

  // Get today's completed tasks
  const completedTasksSnapshot = await db
    .collection('tasks')
    .where('assignedTo', '==', userId)
    .where('isCompleted', '==', true)
    .where('updatedAt', '>=', startOfDay.toISOString())
    .get();

  const completedTasks = completedTasksSnapshot.docs.map(doc => doc.data());
  
  // Calculate XP gained today
  let xpGained = 0;
  const categoryBreakdown: { [key: string]: number } = {};

  for (const task of completedTasks) {
    const taskXP = calculateTaskXP(task.tags || [], task.tags?.includes('essential') || false);
    xpGained += taskXP;

    const category = getCategoryFromTags(task.tags || []);
    categoryBreakdown[category] = (categoryBreakdown[category] || 0) + taskXP;
  }

  // Calculate FluxoCoins earned (1 per 10 XP)
  const fluxoCoinsEarned = Math.floor(xpGained / 10);

  return {
    userId,
    completedTasks: completedTasks.map(task => ({
      id: task.id,
      title: task.title,
      isEssential: task.tags?.includes('essential') || false,
      tags: task.tags || [],
    })),
    xpGained,
    fluxoCoinsEarned,
    streakStatus: {
      current: userStats.currentStreak || 0,
      longest: userStats.longestStreak || 0,
      isActive: (userStats.currentStreak || 0) > 0,
      message: generateStreakMessage(userStats.currentStreak || 0, userStats.longestStreak || 0),
    },
    categoryBreakdown,
  };
}

async function generateAndScheduleNightSummary(userId: string): Promise<void> {
  const userPrefs = await getUserNotificationPreferences(userId);
  
  if (!userPrefs?.enableNightSummary) {
    return;
  }

  const now = new Date();
  const nightTime = new Date(now);
  nightTime.setHours(userPrefs.nightTime.hour, userPrefs.nightTime.minute, 0, 0);
  
  // If night time has passed, schedule for tomorrow
  if (nightTime <= now) {
    nightTime.setDate(nightTime.getDate() + 1);
  }

  await scheduleNightSummaryNotification(userId, nightTime);
}

async function setupTomorrowSchedules(userId: string): Promise<void> {
  const userPrefs = await getUserNotificationPreferences(userId);
  
  if (!userPrefs) {
    return;
  }

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Schedule morning summary if enabled
  if (userPrefs.enableDailySummary) {
    const morningTime = new Date(tomorrow);
    morningTime.setHours(userPrefs.morningTime.hour, userPrefs.morningTime.minute, 0, 0);
    
    await scheduleMorningSummaryNotification(userId, morningTime);
  }
}

function generateMorningSummaryBody(summary: any): string {
  const taskCount = summary.tasksForToday.length;
  const essentialCount = summary.essentialTasksCount;

  if (taskCount === 0) {
    return 'No tasks scheduled for today. Enjoy your free time! 🎉';
  }

  return `You have ${taskCount} tasks today${essentialCount > 0 ? ` (${essentialCount} essential)` : ''}. ${summary.motivationalMessage}`;
}

function generateNightSummaryBody(summary: any): string {
  const completedCount = summary.completedTasks.length;
  const xp = summary.xpGained;

  if (completedCount === 0) {
    return 'No tasks completed today. Tomorrow is a new opportunity! 💪';
  }

  return `Great job! You completed ${completedCount} tasks and earned ${xp} XP. ${summary.streakStatus.message}`;
}

function generateMotivationalMessage(streak: number, essentialTasks: number): string {
  if (streak >= 7) {
    return `Amazing ${streak}-day streak! Keep the momentum going! 🔥`;
  } else if (streak >= 3) {
    return `You're on a roll with a ${streak}-day streak! 🚀`;
  } else if (essentialTasks > 0) {
    return `Focus on your ${essentialTasks} essential tasks to build your streak! 💪`;
  } else {
    return "Every task completed is progress. You've got this! ⭐";
  }
}

function generateStreakMessage(current: number, longest: number): string {
  if (current === 0) {
    return 'Ready to start a new streak tomorrow? 🌟';
  } else if (current === longest) {
    return `New personal record! ${current}-day streak! 🏆`;
  } else {
    return `Keep going! ${current}-day streak (best: ${longest} days) 🔥`;
  }
}

function calculateTaskXP(tags: string[], isEssential: boolean): number {
  let baseXP = 10;

  if (isEssential) {
    baseXP += 5;
  }

  for (const tag of tags) {
    switch (tag.toLowerCase()) {
      case 'health':
        baseXP += 3;
        break;
      case 'work':
        baseXP += 2;
        break;
      case 'finance':
        baseXP += 4;
        break;
      case 'home':
        baseXP += 2;
        break;
      default:
        baseXP += 1;
    }
  }

  return baseXP;
}

function getCategoryFromTags(tags: string[]): string {
  const categoryPriority = ['Health', 'Finance', 'Work', 'Home'];

  for (const category of categoryPriority) {
    if (tags.some(tag => tag.toLowerCase() === category.toLowerCase())) {
      return category;
    }
  }

  return 'Home';
}