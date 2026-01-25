# Como Converter AAB para APK e Instalar no Celular

## Método 1: Usar bundletool (Oficial Google)

### 1. Baixar bundletool
```bash
# Baixe de: https://github.com/google/bundletool/releases
# Arquivo: bundletool-all-1.15.6.jar (versão mais recente)
```

### 2. Converter AAB para APK
```bash
# No terminal/cmd:
java -jar bundletool-all-1.15.6.jar build-apks --bundle=app-release.aab --output=app.apks --mode=universal

# Extrair APK:
java -jar bundletool-all-1.15.6.jar extract-apks --apks=app.apks --output-dir=./apk --device-spec=device_spec.json
```

### 3. Instalar no celular
```bash
adb install universal.apk
```

## Método 2: Usar APK Online (Mais Fácil)

### Sites confiáveis para conversão:
1. **APK Extractor Online** (pesquise no Google)
2. **Bundle Tool Online** 

⚠️ **Cuidado**: Use apenas sites confiáveis para arquivos de produção

## Método 3: Modificar Codemagic (Recomendado)

### Workflow atualizado para gerar APK + AAB:

```yaml
- name: Build debug APK (para teste)
  script: |
    flutter build apk --debug --no-tree-shake-icons

- name: Build release APK (para teste)  
  script: |
    flutter build apk --release --no-tree-shake-icons

- name: Build AAB (para Play Store)
  script: |
    flutter build appbundle --release --no-tree-shake-icons
```

## Como Instalar APK no Celular

### 1. Habilitar "Fontes Desconhecidas"
- **Android**: Configurações > Segurança > Fontes Desconhecidas
- **Ou**: Configurações > Apps > Acesso especial > Instalar apps desconhecidos

### 2. Transferir APK para o celular
- Via cabo USB
- Via Google Drive/Dropbox
- Via WhatsApp (para si mesmo)
- Via email

### 3. Instalar
- Abra o arquivo APK no celular
- Toque em "Instalar"
- Confirme a instalação

## Diferenças: APK vs AAB

| Formato | Uso | Tamanho | Instalação |
|---------|-----|---------|------------|
| **APK** | Teste/Sideload | Maior | Direta no celular |
| **AAB** | Play Store | Menor | Só via Play Store |

## Próximos Passos

### Para Teste Imediato:
1. ✅ Modifique o workflow para gerar APK
2. ✅ Execute novo build no Codemagic
3. ✅ Baixe o APK e instale no celular

### Para Publicação:
1. ✅ Use o AAB atual para publicar na Play Store
2. ✅ AAB é o formato preferido do Google
3. ✅ Play Store otimiza automaticamente para cada dispositivo

## Comando Rápido para Teste Local

Se quiser testar localmente (precisa do Android SDK):
```bash
# Gerar APK debug:
flutter build apk --debug

# Instalar direto no celular conectado:
flutter install
```

**O importante é que o build funcionou! Agora é só escolher o método de instalação.** 🚀