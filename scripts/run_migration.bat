@echo off
REM Migration script runner for Windows
REM This script helps run the UserLimitations migration

echo ========================================
echo UserLimitations Migration Script
echo ========================================
echo.

REM Check if GOOGLE_APPLICATION_CREDENTIALS is set
if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
    echo ERROR: GOOGLE_APPLICATION_CREDENTIALS environment variable is not set
    echo.
    echo Please set it to the path of your Firebase service account key:
    echo   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account-key.json
    echo.
    echo Or run this script with the path as an argument:
    echo   run_migration.bat C:\path\to\service-account-key.json
    echo.
    pause
    exit /b 1
)

REM If argument provided, use it as credentials path
if not "%1"=="" (
    echo Using credentials from: %1
    set GOOGLE_APPLICATION_CREDENTIALS=%1
) else (
    echo Using credentials from: %GOOGLE_APPLICATION_CREDENTIALS%
)

echo.
echo Running migration script...
echo.

REM Run the migration script
dart run scripts/migrate_user_limitations.dart

echo.
echo ========================================
echo Migration script completed
echo ========================================
echo.
pause
