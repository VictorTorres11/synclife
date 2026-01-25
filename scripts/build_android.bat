@echo off
echo ========================================
echo    SyncLife - Android Build Script
echo ========================================

echo.
echo Verificando ambiente Flutter...
flutter doctor --android-licenses

echo.
echo Limpando build anterior...
flutter clean
flutter pub get

echo.
echo Escolha o tipo de build:
echo 1. APK Debug (para testes rápidos)
echo 2. APK Release (para distribuição)
echo 3. App Bundle (para Google Play Store)
echo 4. Instalar diretamente no dispositivo conectado

set /p choice="Digite sua escolha (1-4): "

if "%choice%"=="1" (
    echo.
    echo Construindo APK Debug...
    flutter build apk --debug
    echo.
    echo ✓ APK Debug criado em: build\app\outputs\flutter-apk\app-debug.apk
) else if "%choice%"=="2" (
    echo.
    echo Construindo APK Release...
    flutter build apk --release
    echo.
    echo ✓ APK Release criado em: build\app\outputs\flutter-apk\app-release.apk
) else if "%choice%"=="3" (
    echo.
    echo Construindo App Bundle...
    flutter build appbundle --release
    echo.
    echo ✓ App Bundle criado em: build\app\outputs\bundle\release\app-release.aab
) else if "%choice%"=="4" (
    echo.
    echo Verificando dispositivos conectados...
    flutter devices
    echo.
    echo Instalando no dispositivo...
    flutter install
) else (
    echo Opção inválida!
    goto end
)

echo.
echo ========================================
echo Build concluído com sucesso!
echo ========================================

:end
pause