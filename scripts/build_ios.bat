@echo off
echo ========================================
echo    SyncLife - iOS Build Script
echo ========================================

echo.
echo ATENÇÃO: Para iOS você precisa de:
echo - macOS com Xcode instalado
echo - Conta de desenvolvedor Apple
echo - Dispositivo iOS ou simulador

echo.
echo Este script é para referência. Execute no macOS:
echo.
echo # Limpar builds anteriores
echo flutter clean
echo flutter pub get
echo.
echo # Para simulador iOS
echo flutter build ios --simulator
echo.
echo # Para dispositivo físico (requer certificados)
echo flutter build ios --release
echo.
echo # Instalar no dispositivo conectado
echo flutter install
echo.
echo # Abrir no Xcode para assinatura e distribuição
echo open ios/Runner.xcworkspace

echo.
echo Para testar no dispositivo físico:
echo 1. Conecte o iPhone via USB
echo 2. Confie no computador no iPhone
echo 3. Execute: flutter devices
echo 4. Execute: flutter run --release

echo.
pause