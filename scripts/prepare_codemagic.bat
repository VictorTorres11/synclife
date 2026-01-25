@echo off
echo ========================================
echo   Preparando SyncLife para Codemagic
echo ========================================

echo.
echo 1. Verificando configuração do projeto...
flutter doctor

echo.
echo 2. Limpando builds anteriores...
flutter clean

echo.
echo 3. Obtendo dependências...
flutter pub get

echo.
echo 4. Executando análise de código...
flutter analyze

echo.
echo 5. Executando testes...
flutter test

echo.
echo 6. Verificando se o projeto compila...
flutter build apk --debug --verbose

echo.
echo ========================================
echo Projeto preparado para Codemagic!
echo ========================================
echo.
echo Próximos passos:
echo 1. Faça commit das alterações
echo 2. Push para seu repositório Git
echo 3. Configure o projeto no Codemagic
echo 4. Execute o primeiro build
echo.
pause