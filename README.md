# SyncLife App

A comprehensive Flutter application for task management and productivity.

## 🚀 Quick Start

### Prerequisites
- Flutter 3.24.0 or higher
- Dart SDK
- Android Studio / VS Code
- Java 17 (for Android builds)

### Setup
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`
4. Run `flutter run`

## 📱 Platforms

- ✅ Android
- ✅ iOS  
- ✅ Web

## 🔧 Development

### Running Tests
```bash
flutter test
```

### Code Generation
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Analysis
```bash
flutter analyze
```

## 🚀 Deployment

### Android Release (AAB)

**Opção 1: Codemagic (Recomendado para iniciantes)**
1. Acesse Codemagic Dashboard
2. Selecione workflow "Android AAB Release (Google Play)"
3. Execute o build (keystore gerado automaticamente)
4. Baixe AAB dos artifacts
5. Upload para Google Play Console

**Opção 2: GitHub Actions**
1. Go to Actions tab
2. Select "Android Release AAB"
3. Run workflow with version parameters
4. Download AAB from artifacts
5. Upload to Google Play Console

**Opção 3: Build Local**
```bash
scripts\build_android_aab.bat
```

**Documentação detalhada:**
- [Codemagic AAB Setup](docs/CODEMAGIC_AAB_SETUP.md) - Setup mais simples
- [Android Release Setup](docs/ANDROID_RELEASE_SETUP.md) - Setup completo
- [Workflows Documentation](docs/WORKFLOWS.md) - Todos os workflows

### Web Deployment
Automatic deployment to Firebase Hosting on push to `main` branch.

## 📚 Documentation

- [Setup Guide](docs/SETUP.md)
- [Android Release Setup](docs/ANDROID_RELEASE_SETUP.md)
- [Workflows Documentation](docs/WORKFLOWS.md)
- [Firestore Setup Guide](FIRESTORE_SETUP_GUIDE.md)

## 🏗️ Architecture

The app follows Clean Architecture principles with:
- **Features**: Modular feature-based organization
- **Core**: Shared utilities and services
- **Data**: Repository pattern with Firebase integration
- **Presentation**: Riverpod for state management

## 🔥 Firebase Integration

- Authentication
- Firestore Database
- Cloud Functions
- Analytics
- Crashlytics
- Push Notifications

## 🧪 Testing

- Unit Tests
- Widget Tests
- Integration Tests
- Property-based Tests

## 📦 Key Features

- Task Management
- Gamification System
- Rewards & Achievements
- Push Notifications
- Offline Support
- Multi-platform Sync

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
