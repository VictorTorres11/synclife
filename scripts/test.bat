@echo off
echo Running SyncLife Tests...

echo.
echo 1. Getting dependencies...
flutter pub get

echo.
echo 2. Generating code...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo 3. Running all tests...
flutter test

echo.
echo 4. Running property-based tests...
flutter test test/property_tests/

echo.
echo 5. Generating coverage report...
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

echo.
echo Tests completed!