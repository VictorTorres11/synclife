@echo off
echo Building Web for production...

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
flutter pub get

REM Build Web
echo Building Web...
flutter build web --release --web-renderer canvaskit

echo Web build completed!
echo Build location: build/web/
echo Deploy the contents of build/web/ to your web server or Firebase Hosting

pause