@echo off
echo ========================================
echo   CORRIGINDO PROBLEMA JAVA 25 + GRADLE
echo ========================================
echo.

echo O problema: Java 25 nao e suportado pelo Gradle atual
echo Solucao: Configurar Flutter para usar Java 11
echo.

echo Passo 1: Baixar Java 11
echo Abra: https://adoptium.net/temurin/releases/?version=11
echo Baixe: "Windows x64 JDK" (.msi installer)
echo Instale em: C:\Program Files\Eclipse Adoptium\jdk-11.x.x.x-hotspot
echo.

echo Passo 2: Configurar Flutter
echo Apos instalar Java 11, execute:
echo flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-11.x.x.x-hotspot"
echo.

echo Passo 3: Verificar
echo flutter doctor -v
echo.

echo Passo 4: Tentar build novamente
echo flutter build apk --release
echo.

echo ========================================
echo   SOLUCAO ALTERNATIVA (TEMPORARIA)
echo ========================================
echo.

echo Se nao quiser instalar Java 11, pode:
echo 1. Usar build debug: flutter run
echo 2. Ou desabilitar minificacao (ja feito)
echo.

pause