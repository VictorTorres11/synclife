@echo off
REM SyncLife Production Build Script for Windows
REM This script automates the production build process for Android and Web

setlocal enabledelayedexpansion

REM Configuration
for /f "tokens=2 delims=: " %%a in ('findstr /C:"version:" pubspec.yaml') do set VERSION=%%a
set BUILD_DIR=build\production
set TIMESTAMP=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo ========================================
echo SyncLife Production Build
echo Version: %VERSION%
echo Timestamp: %TIMESTAMP%
echo ========================================
echo.

REM Check prerequisites
echo Checking Prerequisites...
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter not found. Please install Flutter.
    exit /b 1
)
echo [OK] Flutter found

where java >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Java not found. Android builds may fail.
) else (
    echo [OK] Java found
)

REM Clean previous builds
echo.
echo Cleaning Previous Builds...
flutter clean
if exist build rmdir /s /q build
echo [OK] Clean complete

REM Get dependencies
echo.
echo Getting Dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to get dependencies
    exit /b 1
)
echo [OK] Dependencies fetched

REM Run tests (optional)
if "%1"=="--skip-tests" (
    echo.
    echo Skipping tests...
) else (
    echo.
    echo Running Tests...
    flutter test
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Tests failed. Fix tests before building production.
        exit /b 1
    )
    echo [OK] All tests passed
)

REM Build Android
echo.
echo Building Android Release...
echo.

if not exist android\key.properties (
    echo Warning: android\key.properties not found.
    echo Using debug signing. For production, create key.properties.
)

echo Building App Bundle (AAB)...
flutter build appbundle --release --obfuscate --split-debug-info=build\app\outputs\symbols
if %ERRORLEVEL% NEQ 0 (
    echo Error: Android AAB build failed
    exit /b 1
)

echo Building APK...
flutter build apk --release --obfuscate --split-debug-info=build\app\outputs\symbols
if %ERRORLEVEL% NEQ 0 (
    echo Error: Android APK build failed
    exit /b 1
)

REM Create output directory
if not exist %BUILD_DIR%\android mkdir %BUILD_DIR%\android

REM Copy outputs
copy build\app\outputs\bundle\release\app-release.aab %BUILD_DIR%\android\synclife-%VERSION%-%TIMESTAMP%.aab
copy build\app\outputs\flutter-apk\app-release.apk %BUILD_DIR%\android\synclife-%VERSION%-%TIMESTAMP%.apk

echo [OK] Android build complete

REM Build Web
echo.
echo Building Web Release...
echo.

flutter build web --release --web-renderer canvaskit
if %ERRORLEVEL% NEQ 0 (
    echo Error: Web build failed
    exit /b 1
)

REM Create output directory
if not exist %BUILD_DIR%\web mkdir %BUILD_DIR%\web

REM Copy output
xcopy /E /I /Y build\web %BUILD_DIR%\web

echo [OK] Web build complete

REM Generate build report
echo.
echo Generating Build Report...

set REPORT_FILE=%BUILD_DIR%\build_report_%TIMESTAMP%.txt

echo SyncLife Production Build Report > %REPORT_FILE%
echo ================================ >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo Build Information: >> %REPORT_FILE%
echo - Version: %VERSION% >> %REPORT_FILE%
echo - Timestamp: %TIMESTAMP% >> %REPORT_FILE%
flutter --version >> %REPORT_FILE% 2>&1
echo. >> %REPORT_FILE%
echo Build Outputs: >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo Android: >> %REPORT_FILE%
dir %BUILD_DIR%\android >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo Web: >> %REPORT_FILE%
dir %BUILD_DIR%\web >> %REPORT_FILE%

echo [OK] Build report generated: %REPORT_FILE%

REM Display summary
echo.
echo ========================================
echo Build Summary
echo ========================================
echo.
echo Build completed successfully!
echo.
echo Output directory: %BUILD_DIR%
echo.
echo Android builds:
dir /b %BUILD_DIR%\android
echo.
echo Web build: %BUILD_DIR%\web
echo.
echo Next steps:
echo 1. Test builds on real devices
echo 2. Upload to respective stores
echo 3. Monitor crash reports and analytics
echo.

endlocal
