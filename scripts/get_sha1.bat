@echo off
echo Obtendo SHA-1 fingerprints para Google Sign-In...
echo.

cd /d "%~dp0\..\android"

echo === DEBUG SHA-1 ===
call gradlew signingReport | findstr "SHA1:"

echo.
echo === Instrucoes ===
echo 1. Copie o SHA-1 fingerprint acima
echo 2. Va para Firebase Console ^> Project Settings ^> Your apps
echo 3. Selecione seu app Android
echo 4. Adicione o SHA-1 na secao "SHA certificate fingerprints"
echo 5. Baixe o novo google-services.json e substitua o atual
echo.
pause