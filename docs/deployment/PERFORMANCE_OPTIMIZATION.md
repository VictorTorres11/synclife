# SyncLife - Performance Optimization Guide

## Bundle Size Optimization

### Current Status
- Target: < 50MB for Android AAB
- Target: < 100MB for iOS IPA
- Target: < 5MB for Web (initial load)

### Optimization Strategies

#### 1. Remove Unused Dependencies

```bash
# Analyze dependencies
flutter pub deps

# Remove unused packages from pubspec.yaml
# Check for duplicate dependencies
flutter pub outdated
```

#### 2. Optimize Images

```bash
# Compress PNG images
pngquant --quality=65-80 assets/images/*.png

# Compress JPEG images
jpegoptim --max=85 assets/images/*.jpg

# Convert to WebP (better compression)
cwebp -q 80 input.png -o output.webp
```

**Image Guidelines**:
- Use WebP format when possible
- Provide multiple resolutions (1x, 2x, 3x)
- Lazy load images not immediately visible
- Use vector graphics (SVG) for icons

#### 3. Enable Tree Shaking

Already configured in build commands:
```bash
flutter build appbundle --release --tree-shake-icons
flutter build ipa --release --tree-shake-icons
```

#### 4. Split APKs by ABI (Android)

```bash
# Build separate APKs for different architectures
flutter build apk --release --split-per-abi

# Generates:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM)
# - app-x86_64-release.apk (64-bit x86)
```

#### 5. Deferred Components (Advanced)

For very large apps, implement deferred loading:

```dart
// lib/deferred_features.dart
import 'package:flutter/widgets.dart' deferred as premium_features;

Future<void> loadPremiumFeatures() async {
  await premium_features.loadLibrary();
  // Use premium_features.SomeWidget()
}
```

### Bundle Size Analysis

```bash
# Android: Analyze AAB
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks --mode=universal

bundletool get-size total --apks=app.apks

# iOS: Analyze IPA
unzip -l build/ios/ipa/synclife_app.ipa | sort -k4 -n

# Web: Analyze bundle
flutter build web --release --analyze-size
```

## Runtime Performance

### 1. Widget Optimization

#### Use const Constructors
```dart
// Bad
Widget build(BuildContext context) {
  return Container(
    child: Text('Hello'),
  );
}

// Good
Widget build(BuildContext context) {
  return const Container(
    child: Text('Hello'),
  );
}
```

#### Avoid Rebuilds
```dart
// Use keys for list items
ListView.builder(
  itemBuilder: (context, index) {
    return TaskItem(
      key: ValueKey(tasks[index].id),
      task: tasks[index],
    );
  },
);

// Use RepaintBoundary for expensive widgets
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)
```

#### Implement shouldRebuild
```dart
class TaskListDelegate extends SliverChildBuilderDelegate {
  TaskListDelegate(builder, {required childCount})
      : super(builder, childCount: childCount);

  @override
  bool shouldRebuild(covariant SliverChildBuilderDelegate oldDelegate) {
    return false; // Only rebuild when necessary
  }
}
```

### 2. List Performance

#### Use ListView.builder
```dart
// Bad: Creates all items upfront
ListView(
  children: tasks.map((task) => TaskItem(task: task)).toList(),
)

// Good: Lazy loading
ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) => TaskItem(task: tasks[index]),
)
```

#### Implement Item Extent
```dart
ListView.builder(
  itemCount: tasks.length,
  itemExtent: 80.0, // Fixed height improves performance
  itemBuilder: (context, index) => TaskItem(task: tasks[index]),
)
```

### 3. Image Loading

```dart
// Preload images
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(AssetImage('assets/images/logo.png'), context);
}

// Use cached network images
CachedNetworkImage(
  imageUrl: user.avatarUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 200, // Resize in memory
  maxWidthDiskCache: 400, // Resize on disk
)
```

### 4. State Management Optimization

```dart
// Use Riverpod selectors to prevent unnecessary rebuilds
final userNameProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  return user?.name; // Only rebuild when name changes
});

// Use family for parameterized providers
final taskProvider = Provider.family<Task, String>((ref, taskId) {
  return ref.watch(tasksProvider).firstWhere((t) => t.id == taskId);
});
```

### 5. Async Operations

```dart
// Use compute for heavy computations
Future<List<Task>> parseTasksInBackground(String json) async {
  return await compute(_parseTasks, json);
}

List<Task> _parseTasks(String json) {
  // Heavy parsing logic
  return jsonDecode(json).map((e) => Task.fromJson(e)).toList();
}

// Debounce search queries
Timer? _debounce;

void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    performSearch(query);
  });
}
```

## Database Performance

### 1. Firestore Optimization

```dart
// Use indexes for complex queries
// Create in Firebase Console or firestore.indexes.json

// Limit query results
final tasks = await firestore
    .collection('tasks')
    .where('userId', isEqualTo: userId)
    .limit(50)
    .get();

// Use pagination
Query query = firestore
    .collection('tasks')
    .orderBy('createdAt', descending: true)
    .limit(20);

// For next page
query = query.startAfterDocument(lastDocument);

// Cache strategy
final tasks = await firestore
    .collection('tasks')
    .get(const GetOptions(source: Source.cache));
```

### 2. SQLite Optimization

```dart
// Use indexes
await db.execute('''
  CREATE INDEX idx_tasks_user_id ON tasks(user_id);
  CREATE INDEX idx_tasks_due_date ON tasks(due_date);
''');

// Use transactions for bulk operations
await db.transaction((txn) async {
  for (var task in tasks) {
    await txn.insert('tasks', task.toMap());
  }
});

// Use prepared statements
final stmt = await db.rawQuery(
  'SELECT * FROM tasks WHERE user_id = ? AND due_date > ?',
  [userId, DateTime.now().toIso8601String()],
);
```

### 3. Caching Strategy

```dart
class CacheManager {
  final Map<String, CacheEntry> _cache = {};
  final Duration _ttl = Duration(minutes: 5);

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T;
  }

  void set<T>(String key, T value) {
    _cache[key] = CacheEntry(value, DateTime.now());
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime timestamp;
  
  CacheEntry(this.value, this.timestamp);
}
```

## Network Performance

### 1. Request Optimization

```dart
// Batch requests
Future<void> syncMultipleTasks(List<Task> tasks) async {
  final batch = firestore.batch();
  
  for (var task in tasks) {
    final ref = firestore.collection('tasks').doc(task.id);
    batch.set(ref, task.toJson());
  }
  
  await batch.commit();
}

// Use compression
final response = await http.post(
  Uri.parse(apiUrl),
  headers: {
    'Content-Encoding': 'gzip',
    'Accept-Encoding': 'gzip',
  },
  body: gzip.encode(utf8.encode(jsonData)),
);
```

### 2. Offline-First Strategy

```dart
// Check connectivity before network calls
final connectivity = await Connectivity().checkConnectivity();

if (connectivity == ConnectivityResult.none) {
  // Queue for later sync
  await syncQueue.add(operation);
  return cachedData;
}

// Optimistic updates
void completeTask(Task task) {
  // Update UI immediately
  task.isCompleted = true;
  notifyListeners();
  
  // Sync in background
  _syncTaskCompletion(task).catchError((error) {
    // Revert on error
    task.isCompleted = false;
    notifyListeners();
  });
}
```

## Memory Management

### 1. Dispose Resources

```dart
class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late StreamSubscription _subscription;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _subscription = taskStream.listen(_onTaskUpdate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(controller: _scrollController);
  }
}
```

### 2. Memory Leak Detection

```bash
# Run with memory profiling
flutter run --profile

# Use DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Monitor memory in DevTools:
# - Memory tab
# - Look for growing heap
# - Check for retained objects
```

## Build Performance

### 1. Gradle Optimization (Android)

```gradle
// android/gradle.properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
android.enableR8.fullMode=true
android.enableJetifier=true
android.useAndroidX=true
```

### 2. Xcode Optimization (iOS)

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Use new build system
# Xcode > File > Workspace Settings > Build System > New Build System
```

### 3. Flutter Build Cache

```bash
# Clear Flutter cache if needed
flutter clean
flutter pub cache repair

# Use build cache
flutter build apk --release --build-shared-library
```

## Monitoring Performance

### 1. Firebase Performance Monitoring

```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  Future<T> traceOperation<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    
    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}
```

### 2. Custom Metrics

```dart
// Track specific operations
final trace = FirebasePerformance.instance.newTrace('task_sync');
await trace.start();

trace.incrementMetric('tasks_synced', tasks.length);
trace.putAttribute('sync_type', 'full');

await trace.stop();
```

### 3. Performance Testing

```bash
# Run performance tests
flutter drive --target=test_driver/performance_test.dart --profile

# Analyze timeline
flutter analyze --watch
```

## Performance Targets

### App Launch
- Cold start: < 3 seconds
- Warm start: < 1 second
- Hot reload: < 500ms

### UI Responsiveness
- Frame rate: 60 FPS (16.67ms per frame)
- Jank: < 1% of frames
- Input latency: < 100ms

### Network
- API response: < 500ms (p95)
- Image load: < 1 second
- Sync operation: < 2 seconds

### Memory
- Baseline: < 100MB
- Peak: < 200MB
- No memory leaks

### Battery
- Background drain: < 2% per hour
- Active use: < 10% per hour

## Checklist

- [ ] Bundle size optimized (< 50MB Android, < 100MB iOS)
- [ ] Images compressed and optimized
- [ ] Unused dependencies removed
- [ ] Tree shaking enabled
- [ ] const constructors used where possible
- [ ] ListView.builder for long lists
- [ ] Images preloaded and cached
- [ ] Database queries indexed
- [ ] Network requests batched
- [ ] Offline-first strategy implemented
- [ ] Resources properly disposed
- [ ] Performance monitoring enabled
- [ ] Performance targets met
- [ ] Memory leaks checked
- [ ] Battery usage optimized
