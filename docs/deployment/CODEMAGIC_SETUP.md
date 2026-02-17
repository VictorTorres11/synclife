# SyncLife - CodeMagic CI/CD Setup Guide

## Configuração de Assinatura de Código no CodeMagic

### Problema Atual

O build está falando com o erro:
```
Keystore file '/Users/builder/clone/android/app/debug.keystore' not found for signing config 'release'.
```

Isso acontece porque o CodeMagic precisa das credenciais de assinatura configuradas para fazer builds de release.

## Solução: Configurar Credenciais no CodeMagic

### Opção 1: Usar Code Signing Identity do CodeMagic (Recomendado)

1. **Acesse o CodeMagic Dashboard**:
   - Vá para https://codemagic.io
   - Faça login e selecione seu projeto

2. **Configure Android Code Signing**:
   - Vá para **App settings** > **Code signing identities**
   - Na seção **Android**, clique em **Add key**

3. **Upload do Keystore**:
   - **Keystore file**: Faça upload do arquivo `.jks` ou `.keystore`
   - **Keystore password**: Digite a senha do keystore
   - **Key alias**: Digite o alias da chave (ex: `synclife-key`)
   - **Key password**: Digite a senha da chave
   - Clique em **Save**

4. **Ative no Workflow**:
   - Vá para **Workflow settings**
   - Na seção **Code signing**, marque a opção para usar o keystore configurado

### Opção 2: Usar Variáveis de Ambiente

1. **Prepare o Keystore em Base64**:
   ```bash
   # No seu computador local, converta o keystore para base64
   base64 -i android/app/synclife-release-key.jks -o keystore.base64.txt
   ```

2. **Configure Variáveis de Ambiente no CodeMagic**:
   - Vá para **App settings** > **Environment variables**
   - Adicione as seguintes variáveis:
     - `KEYSTORE_BASE64`: Cole o conteúdo do arquivo `keystore.base64.txt`
     - `KEYSTORE_PASSWORD`: Senha do keystore
     - `KEY_ALIAS`: Alias da chave (ex: `synclife-key`)
     - `KEY_PASSWORD`: Senha da chave
   - Marque todas como **Secure** (ícone de cadeado)

3. **Atualize o Script de Build**:
   
   Adicione no arquivo `codemagic.yaml` (ou crie se não existir):

   ```yaml
   workflows:
     android-release:
       name: Android AAB Release (Google Play)
       environment:
         groups:
           - keystore_credentials
         vars:
           PACKAGE_NAME: "com.synclife.synclife_app"
       scripts:
         - name: Set up keystore
           script: |
             echo $KEYSTORE_BASE64 | base64 --decode > $CM_BUILD_DIR/android/app/synclife-release-key.jks
             
         - name: Create key.properties
           script: |
             cat > $CM_BUILD_DIR/android/key.properties <<EOF
             storePassword=$KEYSTORE_PASSWORD
             keyPassword=$KEY_PASSWORD
             keyAlias=$KEY_ALIAS
             storeFile=synclife-release-key.jks
             EOF
             
         - name: Get Flutter packages
           script: |
             flutter pub get
             
         - name: Build AAB
           script: |
             flutter build appbundle --release
             
       artifacts:
         - build/app/outputs/bundle/release/app-release.aab
   ```

### Opção 3: Usar Google Play App Signing (Mais Simples)

Se você ainda não publicou o app na Google Play Store:

1. **Gere um Keystore Temporário para Upload**:
   ```bash
   keytool -genkey -v -keystore upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure no CodeMagic** (usando Opção 1 ou 2 acima)

3. **Ative Google Play App Signing**:
   - Ao fazer o primeiro upload na Play Console
   - Google Play irá gerenciar a chave de assinatura final
   - Você só precisa assinar com a "upload key"
   - Benefício: Se perder a chave, pode gerar uma nova

## Verificação da Configuração

### Teste Local Primeiro

Antes de configurar no CodeMagic, teste localmente:

```bash
# 1. Verifique se o keystore existe
ls -la android/app/*.jks

# 2. Verifique se key.properties existe
cat android/key.properties

# 3. Teste o build
flutter build appbundle --release

# 4. Verifique a assinatura
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### Logs de Debug no CodeMagic

Se o build falhar, adicione logs para debug:

```yaml
- name: Debug keystore setup
  script: |
    echo "Checking keystore file..."
    ls -la $CM_BUILD_DIR/android/app/
    echo "Checking key.properties..."
    cat $CM_BUILD_DIR/android/key.properties | sed 's/Password=.*/Password=***/'
```

## Estrutura de Arquivos Esperada

```
android/
├── app/
│   ├── build.gradle          # Configurado para ler key.properties
│   └── synclife-release-key.jks  # Keystore (criado pelo script)
└── key.properties            # Credenciais (criado pelo script)
```

## Troubleshooting

### Erro: "Release keystore file not found"

**Causa**: O caminho do keystore no `key.properties` está incorreto ou o arquivo não existe

**Solução**:

1. **Verifique o caminho no key.properties**:
   - O caminho deve ser relativo ao diretório `android/app/`
   - Se o keystore está em `android/keystore/`, use: `storeFile=../keystore/synclife-release-key.jks`
   - Se está em `android/app/`, use: `storeFile=synclife-release-key.jks`

2. **Verifique se o arquivo existe**:
   ```yaml
   - name: Debug keystore location
     script: |
       echo "Checking keystore..."
       ls -la android/keystore/
       echo "Checking from app directory:"
       cd android/app
       ls -la ../keystore/
   ```

3. **Teste o caminho do build.gradle**:
   ```yaml
   - name: Test keystore path
     script: |
       cd android/app
       STORE_FILE=$(grep storeFile ../key.properties | cut -d'=' -f2)
       echo "storeFile path: $STORE_FILE"
       if [ -f "$STORE_FILE" ]; then
         echo "✅ Keystore found!"
       else
         echo "❌ Keystore not found at: $STORE_FILE"
       fi
   ```

### Erro: "Keystore file not found"

**Causa**: O arquivo keystore não foi criado corretamente

**Solução**:
```yaml
- name: Debug keystore
  script: |
    echo "Current directory: $(pwd)"
    echo "Keystore location: $CM_BUILD_DIR/android/app/"
    ls -la $CM_BUILD_DIR/android/app/
    file $CM_BUILD_DIR/android/app/synclife-release-key.jks
```

### Erro: "Wrong password"

**Causa**: Senha incorreta nas variáveis de ambiente

**Solução**:
- Verifique as variáveis no CodeMagic
- Teste localmente com as mesmas credenciais
- Certifique-se de não ter espaços extras

### Erro: "Invalid keystore format"

**Causa**: Problema na conversão base64

**Solução**:
```bash
# Use --decode ao invés de -d em alguns sistemas
echo $KEYSTORE_BASE64 | base64 --decode > keystore.jks

# Ou use -D no macOS
echo $KEYSTORE_BASE64 | base64 -D > keystore.jks
```

## Segurança

### Boas Práticas

1. **Nunca commite credenciais**:
   - `.gitignore` já está configurado
   - Verifique: `git status` não deve mostrar `key.properties` ou `.jks`

2. **Use variáveis seguras**:
   - Marque todas as variáveis como "Secure" no CodeMagic
   - Elas não aparecerão nos logs

3. **Backup do Keystore**:
   - Guarde o keystore original em local seguro
   - Se perder, não poderá atualizar o app!

4. **Rotação de Credenciais**:
   - Use Google Play App Signing para poder trocar a upload key
   - Documente o processo de recuperação

## Próximos Passos

Após configurar as credenciais:

1. ✅ Configure as credenciais no CodeMagic (Opção 1 ou 2)
2. ✅ Execute o workflow novamente
3. ✅ Verifique se o AAB foi gerado com sucesso
4. ✅ Faça upload para Google Play Console
5. ✅ Configure o deployment automático (opcional)

## Referências

- [CodeMagic Android Code Signing](https://docs.codemagic.io/yaml-code-signing/signing-android/)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
