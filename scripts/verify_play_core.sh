#!/bin/bash

# Script to verify Play Core migration
# This checks if the old play:core library is still present

set -e

echo "🔍 Verificando migração do Play Core..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$(dirname "$0")/.."

# Check if android directory exists
if [ ! -d "android" ]; then
    echo -e "${RED}❌ Diretório android não encontrado${NC}"
    exit 1
fi

echo "1️⃣ Verificando build.gradle..."
echo ""

# Check app/build.gradle
if grep -q "com.google.android.play:core:1.10.3" android/app/build.gradle; then
    echo -e "${RED}❌ ERRO: Biblioteca antiga play:core:1.10.3 ainda presente em app/build.gradle${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Biblioteca antiga não encontrada em app/build.gradle${NC}"
fi

# Check for new libraries
if grep -q "com.google.android.play:app-update" android/app/build.gradle; then
    echo -e "${GREEN}✅ Nova biblioteca app-update encontrada${NC}"
else
    echo -e "${YELLOW}⚠️  Nova biblioteca app-update não encontrada${NC}"
fi

if grep -q "com.google.android.play:review" android/app/build.gradle; then
    echo -e "${GREEN}✅ Nova biblioteca review encontrada${NC}"
else
    echo -e "${YELLOW}⚠️  Nova biblioteca review não encontrada${NC}"
fi

echo ""
echo "2️⃣ Verificando estratégia de resolução..."
echo ""

# Check root build.gradle for resolution strategy
if grep -q "exclude group: 'com.google.android.play', module: 'core'" android/build.gradle; then
    echo -e "${GREEN}✅ Estratégia de exclusão configurada${NC}"
else
    echo -e "${YELLOW}⚠️  Estratégia de exclusão não encontrada${NC}"
fi

echo ""
echo "3️⃣ Verificando dependências do Gradle..."
echo ""

cd android

# Check if gradlew exists
if [ ! -f "gradlew" ]; then
    echo -e "${YELLOW}⚠️  gradlew não encontrado, pulando verificação de dependências${NC}"
else
    echo "Executando: ./gradlew app:dependencies --configuration releaseRuntimeClasspath"
    echo ""
    
    # Run gradle dependencies and check for old library
    if ./gradlew app:dependencies --configuration releaseRuntimeClasspath 2>/dev/null | grep -q "com.google.android.play:core:1.10.3"; then
        echo -e "${RED}❌ ERRO: Biblioteca antiga play:core:1.10.3 detectada nas dependências transitivas${NC}"
        echo ""
        echo "Dependências encontradas:"
        ./gradlew app:dependencies --configuration releaseRuntimeClasspath 2>/dev/null | grep "com.google.android.play"
        echo ""
        echo "Solução: Adicione exclusões para os plugins que estão trazendo a dependência antiga"
        exit 1
    else
        echo -e "${GREEN}✅ Biblioteca antiga não encontrada nas dependências${NC}"
    fi
    
    echo ""
    echo "Bibliotecas Play encontradas:"
    ./gradlew app:dependencies --configuration releaseRuntimeClasspath 2>/dev/null | grep "com.google.android.play" | sort -u || echo "Nenhuma"
fi

cd ..

echo ""
echo "4️⃣ Verificando código fonte..."
echo ""

# Check for old imports in Kotlin/Java files
if find android -name "*.kt" -o -name "*.java" | xargs grep -l "com.google.android.play.core" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Imports antigos encontrados no código fonte:${NC}"
    find android -name "*.kt" -o -name "*.java" | xargs grep -n "com.google.android.play.core" 2>/dev/null
    echo ""
    echo "Nota: Verifique se esses imports precisam ser atualizados"
else
    echo -e "${GREEN}✅ Nenhum import antigo encontrado no código fonte${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Verificação concluída com sucesso!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Próximos passos:"
echo "1. Execute: flutter clean"
echo "2. Execute: flutter pub get"
echo "3. Execute: flutter build appbundle --release"
echo "4. Faça upload do AAB para Google Play Console"
echo "5. Verifique que não há avisos sobre Play Core"
echo ""
