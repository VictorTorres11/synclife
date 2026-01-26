@echo off
echo ========================================
echo   Testando Build APK Local - SyncLife
echo ========================================

echo.
echo 1. Limpando projeto...
flutter clean

echo.
echo 2. Obtendo dependências...
flutter pub get

echo.
echo 3. Gerando código...
dart run build_runner build --delete-conflicting-outputs

echo.
echo 4. Analisando código...
flutter analyze --no-fatal-infos

echo.
echo 5. Testando build debug APK...
flutter build apk --debug --verbose

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build debug bem-sucedido!
    echo Arquivo: build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo Tamanho do arquivo:
    dir "build\app\outputs\flutter-apk\app-debug.apk" | find "app-debug.apk"
    echo.
    echo 🎉 APK pronto para teste!
    echo.
    echo Para instalar no dispositivo:
    echo 1. Conecte o dispositivo Android via USB
    echo 2. Ative a depuração USB
    echo 3. Execute: flutter install
    echo.
    echo Ou transfira o APK manualmente para o dispositivo.
) else (
    echo.
    echo ❌ Erro no build debug
    echo Verifique os logs acima
)

echo.
pause