@echo off
echo Setting up SyncLife development environment...

echo.
echo 1. Getting Flutter dependencies...
flutter pub get

echo.
echo 2. Generating code (Riverpod providers, mocks)...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo 3. Configuring Firebase...
echo Please run: flutterfire configure
echo This will set up Firebase configuration for your project.

echo.
echo 4. Running initial tests...
flutter test

echo.
echo Setup completed!
echo.
echo Next steps:
echo 1. Configure Firebase: flutterfire configure
echo 2. Add your Firebase configuration files
echo 3. Run the app: flutter run
echo 4. Start development!