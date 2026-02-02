@echo off
echo Testing Keystore Generation...
echo.

REM Create keystore directory
if not exist "android\keystore" (
    echo Creating keystore directory...
    mkdir android\keystore
)

REM Generate keystore
echo Generating test keystore...
keytool -genkey -v ^
  -keystore android\keystore\synclife-release-key.jks ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias synclife-key ^
  -storepass synclife123 ^
  -keypass synclife123 ^
  -dname "CN=SyncLife, OU=Development, O=SyncLife, L=City, S=State, C=BR"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Keystore generated successfully!
    echo Location: android\keystore\synclife-release-key.jks
    echo.
    
    REM Create key.properties
    echo Creating key.properties...
    (
        echo storePassword=synclife123
        echo keyPassword=synclife123
        echo keyAlias=synclife-key
        echo storeFile=keystore/synclife-release-key.jks
    ) > android\key.properties
    
    echo ✅ key.properties created!
    echo.
    echo Contents:
    type android\key.properties
    echo.
    
    REM Verify keystore
    echo Verifying keystore...
    keytool -list -v -keystore android\keystore\synclife-release-key.jks -storepass synclife123
    
) else (
    echo.
    echo ❌ Failed to generate keystore!
    echo.
    echo Make sure you have Java installed and keytool is in your PATH.
    echo You can install Java from: https://adoptium.net/
)

echo.
echo Test completed.
pause