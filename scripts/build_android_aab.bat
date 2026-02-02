@echo off
echo Building Android App Bundle (AAB) for Release...
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo Warning: key.properties not found. Creating from example...
    if exist "android\key.properties.example" (
        copy "android\key.properties.example" "android\key.properties"
        echo.
        echo Please edit android\key.properties with your keystore information
        echo Then run this script again.
        pause
        exit /b 1
    ) else (
        echo Error: key.properties.example not found
        pause
        exit /b 1
    )
)

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Generating code...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo Running tests...
flutter test

echo Analyzing code...
flutter analyze

echo Building Android App Bundle (AAB)...
flutter build appbundle --release

if %errorlevel% equ 0 (
    echo.
    echo ✅ Build successful!
    echo.
    echo AAB file location:
    dir /b build\app\outputs\bundle\release\*.aab
    echo.
    echo You can now upload this AAB file to Google Play Console
    echo.
) else (
    echo.
    echo ❌ Build failed!
    echo.
)

pause