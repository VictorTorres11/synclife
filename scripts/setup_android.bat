@echo off
echo Configurando ambiente Android...

echo.
echo 1. Certifique-se de que o Android Studio está instalado
echo 2. Abra o Android Studio e vá em File > Settings > Appearance & Behavior > System Settings > Android SDK
echo 3. Instale pelo menos uma versão do Android SDK (recomendado: API 33 ou superior)
echo 4. Vá na aba SDK Tools e instale:
echo    - Android SDK Command-line Tools
echo    - Android SDK Build-Tools
echo    - Android SDK Platform-Tools
echo    - Android Emulator (opcional, para testes)

echo.
echo 5. Configure as variáveis de ambiente:
echo    ANDROID_HOME = C:\Users\%USERNAME%\AppData\Local\Android\Sdk
echo    Adicione ao PATH: %%ANDROID_HOME%%\platform-tools
echo    Adicione ao PATH: %%ANDROID_HOME%%\cmdline-tools\latest\bin

echo.
echo 6. Reinicie o terminal e execute: flutter doctor
echo.
pause