# Android Release Setup Guide

Este guia explica como configurar o build de release para Android AAB (Android App Bundle) para upload na Google Play Console.

## 1. Configuração do Keystore

### Criando um Keystore

Se você ainda não tem um keystore, crie um usando o keytool:

```bash
keytool -genkey -v -keystore android/keystore/synclife-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias synclife-key
```

**Importante:** Guarde as senhas em local seguro! Você precisará delas para futuras atualizações.

### Configurando key.properties

1. Copie o arquivo de exemplo:
```bash
copy android\key.properties.example android\key.properties
```

2. Edite `android/key.properties` com suas informações:
```properties
storePassword=sua_senha_do_keystore
keyPassword=sua_senha_da_chave
keyAlias=synclife-key
storeFile=keystore/synclife-release-key.jks
```

## 2. Configuração no GitHub Actions

Para usar o workflow automático, configure os seguintes secrets no GitHub:

### Secrets Necessários

1. **KEYSTORE_BASE64**: Keystore codificado em base64
   ```bash
   # No Windows (PowerShell)
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android\keystore\synclife-release-key.jks"))
   
   # No Linux/Mac
   base64 -i android/keystore/synclife-release-key.jks
   ```

2. **KEYSTORE_PASSWORD**: Senha do keystore
3. **KEY_PASSWORD**: Senha da chave
4. **KEY_ALIAS**: Alias da chave (ex: synclife-key)

### Como adicionar secrets no GitHub:

1. Vá para Settings > Secrets and variables > Actions
2. Clique em "New repository secret"
3. Adicione cada secret com o nome exato listado acima

## 3. Executando o Build

### Opção 1: GitHub Actions (Recomendado)

1. Vá para a aba "Actions" no GitHub
2. Selecione "Android Release AAB"
3. Clique em "Run workflow"
4. Preencha:
   - Version name (ex: 1.0.0)
   - Version code (ex: 1)
   - Release notes
5. Execute o workflow

### Opção 2: Build Local

Execute o script:
```bash
scripts\build_android_aab.bat
```

Ou manualmente:
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release
```

## 4. Upload para Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app
3. Vá para "Release" > "Testing" > "Internal testing"
4. Clique em "Create new release"
5. Upload o arquivo AAB gerado
6. Adicione release notes
7. Revise e publique

## 5. Estrutura de Arquivos

```
android/
├── keystore/
│   └── synclife-release-key.jks    # Seu keystore (não commitado)
├── key.properties                  # Configurações do keystore (não commitado)
├── key.properties.example          # Exemplo de configuração
└── app/
    └── build.gradle                # Configuração de build
```

## 6. Troubleshooting

### Erro: "keystore not found"
- Verifique se o arquivo keystore existe em `android/keystore/`
- Confirme o caminho no `key.properties`

### Erro: "wrong password"
- Verifique as senhas no `key.properties`
- Teste o keystore manualmente com keytool

### Build falha no GitHub Actions
- Verifique se todos os secrets estão configurados
- Confirme que o keystore base64 está correto

### AAB muito grande
- Ative o R8/ProGuard (já configurado)
- Use `flutter build appbundle --split-per-abi` se necessário

## 7. Próximos Passos

Após o primeiro upload:

1. Configure internal testing
2. Adicione testadores
3. Teste thoroughly
4. Promova para production quando pronto

## 8. Segurança

- **NUNCA** commite o keystore ou key.properties
- Use secrets do GitHub para CI/CD
- Faça backup seguro do keystore
- Use senhas fortes

## 9. Versionamento

O workflow automaticamente atualiza a versão no `pubspec.yaml`:
- Version name: 1.0.0 (semântico)
- Version code: 1 (incremental)

Para releases manuais, atualize manualmente:
```yaml
version: 1.0.0+1
```