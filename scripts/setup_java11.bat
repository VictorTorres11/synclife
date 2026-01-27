@echo off
echo ========================================
echo   CONFIGURANDO JAVA 11 PARA FLUTTER
echo ========================================
echo.

echo O Flutter requer Java 11 ou superior para builds Android.
echo Seu sistema tem Java 25, que nao e compativel com Gradle.
echo.

echo Opcoes:
echo 1. Baixar e instalar Java 11 manualmente
echo 2. Usar Java 11 portatil (recomendado)
echo 3. Configurar JAVA_HOME temporariamente
echo.

set /p choice="Escolha uma opcao (1-3): "

if "%choice%"=="1" (
    echo.
    echo Abra o link abaixo para baixar Java 11:
    echo https://adoptium.net/temurin/releases/?version=11
    echo.
    echo Apos instalar, execute este script novamente.
    pause
    exit /b
)

if "%choice%"=="2" (
    echo.
    echo Baixando Java 11 portatil...
    echo Esta opcao requer conexao com internet.
    echo.
    echo Por favor, baixe manualmente de:
    echo https://adoptium.net/temurin/releases/?version=11
    echo.
    echo E extraia para: C:\Java\jdk-11
    pause
    exit /b
)

if "%choice%"=="3" (
    echo.
    echo Configurando JAVA_HOME temporariamente...
    echo.
    echo AVISO: Esta e uma solucao temporaria.
    echo Para uma solucao permanente, instale Java 11.
    echo.
    
    rem Tentar encontrar Java 11 no sistema
    if exist "C:\Program Files\Java\jdk-11*" (
        for /d %%i in ("C:\Program Files\Java\jdk-11*") do (
            set "JAVA_HOME=%%i"
            echo Encontrado Java 11 em: %%i
        )
    ) else (
        echo Java 11 nao encontrado no sistema.
        echo Por favor, instale Java 11 primeiro.
        pause
        exit /b
    )
    
    echo.
    echo Configurando variaveis de ambiente...
    setx JAVA_HOME "%JAVA_HOME%"
    setx PATH "%JAVA_HOME%\bin;%PATH%"
    
    echo.
    echo Configuracao concluida!
    echo Reinicie o terminal e tente o build novamente.
)

echo.
pause