@echo off
echo ========================================
echo   Testando Build Local - SyncLife
echo ========================================

echo.
echo Simulando ambiente Codemagic...

echo.
echo 1. Limpando projeto...
flutter clean

echo.
echo 2. Obtendo dependências...
flutter pub get

echo.
echo 3. Executando análise...
flutter analyze

echo.
echo 4. Executando testes...
flutter test --reporter expanded

echo.
echo 5. Testando build debug...
flutter build apk --debug --verbose

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build debug bem-sucedido!
    echo Arquivo: build\app\outputs\flutter-apk\app-debug.apk
    
    echo.
    echo 6. Testando build release...
    flutter build apk --release --verbose
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✅ Build release bem-sucedido!
        echo Arquivo: build\app\outputs\flutter-apk\app-release.apk
        echo.
        echo 🎉 Projeto pronto para Codemagic!
    ) else (
        echo.
        echo ❌ Erro no build release
        echo Verifique os logs acima
    )
) else (
    echo.
    echo ❌ Erro no build debug
    echo Verifique os logs acima
)

echo.
pause