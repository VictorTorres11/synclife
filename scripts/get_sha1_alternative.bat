@echo off
echo ========================================
echo   OBTENDO SHA-1 PARA GOOGLE SIGN-IN
echo ========================================
echo.

echo OPCAO 1: Usar SHA-1 de desenvolvimento padrao
echo SHA-1: DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09
echo.

echo OPCAO 2: Gerar novo keystore (se necessario)
echo.

set /p choice="Deseja gerar um novo keystore? (s/n): "

if /i "%choice%"=="s" (
    echo Gerando novo keystore...
    
    if not exist "%USERPROFILE%\.android" (
        mkdir "%USERPROFILE%\.android"
    )
    
    echo Usando keytool para gerar keystore...
    "C:\Program Files\Java\jre1.8.0_481\bin\keytool.exe" -genkey -v -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo Keystore gerado com sucesso!
        echo Obtendo SHA-1...
        "C:\Program Files\Java\jre1.8.0_481\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
    ) else (
        echo Erro ao gerar keystore. Use o SHA-1 padrao acima.
    )
) else (
    echo.
    echo Use o SHA-1 padrao mostrado acima no Firebase Console.
)

echo.
echo ========================================
echo   PROXIMOS PASSOS:
echo ========================================
echo 1. Copie o SHA-1 fingerprint
echo 2. Va para Firebase Console ^> Project Settings ^> Your apps
echo 3. Selecione seu app Android
echo 4. Adicione o SHA-1 na secao "SHA certificate fingerprints"
echo 5. Ative Google Sign-In em Authentication ^> Sign-in method
echo 6. Baixe o novo google-services.json e substitua o atual
echo.
pause