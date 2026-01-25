# SyncLife

SyncLife é um aplicativo de tarefas colaborativo que transforma a organização da rotina em um "jogo cooperativo". Focado em casais, amigos e grupos que desejam harmonia e menos cobranças através de gamificação profunda (RPG da vida real) e sistema de recompensas.

## Features

- 🎮 **Gamificação Profunda**: Sistema RPG com XP, níveis e streaks
- 👥 **Colaboração**: Quadros compartilhados com sincronização em tempo real
- 📱 **Multiplataforma**: Android, iOS e Web
- 🔄 **Offline-First**: Funciona sem internet, sincroniza quando conectado
- 🎯 **Sistema de Recompensas**: FluxoCoins e loja de regalias
- 🔔 **Notificações Inteligentes**: Resumos personalizados e reações rápidas

## Getting Started

### Prerequisites

- Flutter 3.13.0 or higher
- Dart 3.1.0 or higher
- Firebase CLI
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/synclife-app.git
cd synclife-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
flutter packages pub run build_runner build
```

4. Configure Firebase:
```bash
flutterfire configure
```

5. Run the app:
```bash
flutter run
```

## Development

### Project Structure

```
lib/
├── src/
│   ├── core/                 # Core functionality
│   │   ├── routing/          # App routing
│   │   ├── theme/            # App theming
│   │   └── utils/            # Utilities
│   └── features/             # Feature modules
│       ├── auth/             # Authentication
│       ├── tasks/            # Task management
│       ├── boards/           # Board management
│       ├── gamification/     # XP and rewards
│       └── notifications/    # Push notifications
test/
├── helpers/                  # Test utilities
├── property_tests/           # Property-based tests
└── unit_tests/              # Unit tests
```

### Testing

Run all tests:
```bash
flutter test
```

Run property-based tests:
```bash
flutter test test/property_tests/
```

Generate test coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Code Generation

Generate Riverpod providers and mocks:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

Watch for changes:
```bash
flutter packages pub run build_runner watch
```

## Architecture

SyncLife follows Clean Architecture principles with:

- **Presentation Layer**: Flutter widgets and Riverpod state management
- **Domain Layer**: Business logic and entities
- **Data Layer**: Firebase integration and local storage
- **Offline-First**: SQLite cache with sync queue

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run linting and tests
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.