@echo off
echo ========================================
echo    SyncLife - Teste no Dispositivo
echo ========================================

echo.
echo Verificando dispositivos conectados...
flutter devices

echo.
echo Escolha uma opção:
echo 1. Executar em modo debug (desenvolvimento)
echo 2. Executar em modo release (performance)
echo 3. Instalar APK já compilado
echo 4. Verificar logs do dispositivo

set /p choice="Digite sua escolha (1-4): "

if "%choice%"=="1" (
    echo.
    echo Executando em modo debug...
    flutter run --debug
) else if "%choice%"=="2" (
    echo.
    echo Executando em modo release...
    flutter run --release
) else if "%choice%"=="3" (
    echo.
    echo Instalando APK...
    flutter install
) else if "%choice%"=="4" (
    echo.
    echo Mostrando logs do dispositivo...
    echo Pressione Ctrl+C para parar
    flutter logs
) else (
    echo Opção inválida!
)

echo.
pause