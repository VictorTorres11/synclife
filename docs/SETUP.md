# SyncLife Setup Guide

## Project Structure

```
synclife_app/
├── lib/
│   ├── src/
│   │   ├── core/                 # Core functionality
│   │   │   ├── routing/          # App routing with GoRouter
│   │   │   ├── theme/            # Material Design 3 theming
│   │   │   └── utils/            # Shared utilities
│   │   └── features/             # Feature-based architecture
│   │       ├── auth/             # Authentication (Firebase Auth)
│   │       ├── tasks/            # Task management
│   │       ├── boards/           # Board collaboration
│   │       ├── gamification/     # XP, levels, streaks
│   │       └── notifications/    # Push notifications
│   ├── firebase_options.dart     # Firebase configuration
│   └── main.dart                 # App entry point
├── test/
│   ├── helpers/                  # Test utilities and mocks
│   ├── property_tests/           # Property-based tests
│   └── unit_tests/              # Unit tests
├── functions/                    # Firebase Cloud Functions
├── android/                      # Android configuration
├── ios/                         # iOS configuration
├── web/                         # Web configuration
└── assets/                      # Images, sounds, fonts
```

## Development Environment Setup

### Prerequisites

1. **Flutter SDK 3.24.0+**
   ```bash
   flutter --version
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

3. **Development Tools**
   - Android Studio (for Android development)
   - Xcode (for iOS development, macOS only)
   - VS Code with Flutter extension

### Initial Setup

1. **Clone and setup project:**
   ```bash
   git clone <repository-url>
   cd synclife_app
   flutter pub get
   ```

2. **Generate code:**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **Configure Firebase:**
   ```bash
   firebase login
   flutterfire configure
   ```

4. **Run tests:**
   ```bash
   flutter test
   ```

5. **Start development:**
   ```bash
   flutter run
   ```

## Architecture Overview

### State Management
- **Riverpod**: Dependency injection and state management
- **Code Generation**: Automatic provider generation with riverpod_generator

### Database
- **Firebase Firestore**: Real-time NoSQL database
- **SQLite**: Local offline storage
- **Sync Strategy**: Offline-first with conflict resolution

### Authentication
- **Firebase Auth**: Social login (Google, Apple) and email/password
- **Auto Region Detection**: GPS-based timezone and region setup

### Testing Strategy
- **Unit Tests**: Specific functionality testing
- **Property-Based Tests**: Universal property validation
- **Integration Tests**: End-to-end flow testing
- **Minimum 100 iterations** per property test

### CI/CD Pipeline
- **GitHub Actions**: Automated testing and building
- **Firebase Hosting**: Web app deployment
- **App Store/Play Store**: Mobile app distribution

## Key Features Implemented

### ✅ Project Infrastructure
- Flutter project with cross-platform support (Android, iOS, Web)
- Firebase integration (Auth, Firestore, Functions, Hosting)
- Riverpod dependency injection setup
- Comprehensive testing framework with property-based testing
- CI/CD pipeline with GitHub Actions
- Code generation setup (Riverpod providers, mocks)
- Material Design 3 theming with light/dark mode
- Internationalization support (EN, PT, ES)

### ✅ Testing Framework
- Property-based testing utilities with customizable iterations
- Test data generators for realistic test scenarios
- Mock services for Firebase integration testing
- Coverage reporting and analysis
- Automated test execution in CI/CD

### ✅ Firebase Configuration
- Firestore security rules for multi-tenant data access
- Cloud Functions for daily processing and user triggers
- Push notification setup with FCM
- Database indexes for optimal query performance
- Hosting configuration for web deployment

### ✅ Development Tools
- Linting with comprehensive Flutter rules
- Code formatting and analysis
- Build scripts for different platforms
- Development environment setup automation

## Next Steps

After completing this setup, you can proceed with implementing the core features:

1. **Authentication System** (Task 2)
2. **Task Management Core** (Task 3)
3. **Board Collaboration** (Task 5)
4. **Gamification System** (Task 6)
5. **Rewards and Monetization** (Tasks 7, 11)

Each feature will build upon this solid foundation with proper testing and validation at every step.

## Troubleshooting

### Common Issues

1. **Flutter not found**: Ensure Flutter is in your PATH
2. **Firebase configuration**: Run `flutterfire configure` to set up Firebase
3. **Build errors**: Run `flutter clean && flutter pub get`
4. **Code generation**: Run `flutter packages pub run build_runner build --delete-conflicting-outputs`

### Getting Help

- Check the [Flutter documentation](https://flutter.dev/docs)
- Review [Firebase documentation](https://firebase.google.com/docs)
- See [Riverpod documentation](https://riverpod.dev/)
- Open an issue in the project repository