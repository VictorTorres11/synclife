import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:synclife_app/firebase_options.dart';
import 'package:synclife_app/src/features/rewards/data/services/firebase_store_service.dart';
import 'package:synclife_app/src/features/rewards/data/store_catalog.dart';
import 'package:synclife_app/src/features/gamification/data/services/firebase_gamification_service.dart';
import 'package:synclife_app/src/features/tasks/data/services/firebase_task_service.dart';

/// Script to initialize the FluxoCoins store with default items
Future<void> main() async {
  print('Initializing FluxoCoins Store...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase initialized successfully');

    // Create services
    final firestore = FirebaseFirestore.instance;
    final taskService = FirebaseTaskService(firestore: firestore);
    final gamificationService = FirebaseGamificationService(
      firestore: firestore,
      taskService: taskService,
    );
    final storeService = FirebaseStoreService(
      firestore: firestore,
      gamificationService: gamificationService,
    );

    // Initialize store with default items
    await storeService.initializeStore();

    print('✅ Store initialized successfully!');
    print(
        '📦 Added ${StoreCatalog.defaultItems.length} default items to the store');

    // List the items that were added
    print('\n📋 Items added:');
    for (final item in StoreCatalog.defaultItems) {
      print(
          '  • ${item.name} (${item.price} FluxoCoins) - ${item.category.name}');
    }
  } catch (e) {
    print('❌ Error initializing store: $e');
  }

  print('\nStore initialization completed!');
}
