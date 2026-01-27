# 🔐 Configuração de Keystore no Codemagic

## Status Atual
✅ **Usando Debug Keystore** - Funciona para desenvolvimento e testes
❌ **Production Keystore** - Necessário apenas para Google Play Store

## Quando Configurar Keystore de Produção

### ⚠️ Necessário para:
- Upload para Google Play Store
- Distribuição oficial
- Builds de produção assinados

### ✅ Não necessário para:
- Testes internos
- Desenvolvimento
- Firebase App Distribution
- Distribuição direta (APK)

## Como Configurar (Futuro)

### 1. Gerar Keystore
```bash
keytool -genkey -v -keystore release-key.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release
```

### 2. Configurar no Codemagic
1. **Team Settings** → **Code signing identities**
2. **Android keystores** → **Add keystore**
3. Upload do arquivo `release-key.keystore`
4. Configurar alias: `release`

### 3. Adicionar Variáveis de Ambiente
```
KEYSTORE_PASSWORD = sua_senha_keystore
KEY_ALIAS = release
KEY_PASSWORD = sua_senha_chave
```

### 4. Atualizar codemagic.yaml
```yaml
environment:
  android_signing:
    - keystore_reference
```

### 5. Atualizar build.gradle
```gradle
android {
    signingConfigs {
        release {
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
            storeFile file("../release-key.keystore")
            storePassword System.getenv("KEYSTORE_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release  // Mudar de debug para release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

## Configuração Atual (Debug)

### ✅ Vantagens:
- Setup simples
- Builds rápidos
- Sem configuração adicional
- Funciona para testes

### ⚠️ Limitações:
- Não pode ser usado na Play Store
- Não é seguro para produção
- Keystore público (todos têm acesso)

## Próximos Passos

1. **Agora**: Continue usando debug keystore
2. **Antes da Play Store**: Configure keystore de produção
3. **Para distribuição**: Use Firebase App Distribution

## Comandos Úteis

### Verificar Keystore
```bash
keytool -list -v -keystore release-key.keystore
```

### Gerar SHA-1 do Keystore
```bash
keytool -list -v -keystore release-key.keystore -alias release | grep SHA1
```

### Testar Assinatura Local
```bash
flutter build apk --release
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

**💡 Dica**: Por enquanto, continue com debug keystore. Configure produção apenas quando for publicar na Play Store.