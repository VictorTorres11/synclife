# Correção de Chave de Assinatura Incorreta

## Problema

Ao fazer upload do AAB para Google Play Console, você recebeu o erro:

```
Seu Android App Bundle foi assinado com uma chave incorreta.
Esperado: SHA1: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7
Recebido:  SHA1: C6:8C:C0:17:C1:8C:5D:F8:15:35:57:88:64:20:AF:16:52:EE:8D:AC
```

## Causa

Existem duas possibilidades:

### 1. Primeiro Upload do App (Novo App)
Se este é o primeiro upload, o Google Play Console registrou a primeira chave que você usou. Todos os uploads futuros DEVEM usar a mesma chave.

### 2. App Já Publicado
Se o app já foi publicado anteriormente, você está usando uma chave diferente da original.

## Soluções

### Solução 1: Usar a Chave Correta (Recomendado)

Você precisa encontrar e usar o keystore original que tem a impressão digital esperada.

#### Passo 1: Verificar Keystores Existentes

```bash
# Verificar o keystore atual no CodeMagic (gerado automaticamente)
keytool -list -v -keystore android/keystore/synclife-release-key.jks -alias synclife-key

# Verificar outros keystores que você possa ter
keytool -list -v -keystore caminho/para/seu/keystore.jks
```

#### Passo 2: Encontrar o Keystore Correto

Procure por um keystore que tenha a impressão digital esperada:
```
SHA1: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7
```

Locais comuns:
- `android/app/` (no projeto)
- `android/keystore/` (no projeto)
- Backup em nuvem (Google Drive, Dropbox, etc.)
- Computador pessoal
- Servidor de CI/CD anterior

#### Passo 3: Configurar no CodeMagic

Uma vez encontrado o keystore correto:

**Opção A: Upload Direto no CodeMagic**
1. Acesse CodeMagic Dashboard
2. App settings → Code signing identities → Android
3. Faça upload do keystore correto
4. Configure as credenciais

**Opção B: Usar Variáveis de Ambiente**
```bash
# Converter keystore para base64
base64 -i seu-keystore-correto.jks -o keystore.base64.txt

# No CodeMagic, adicione as variáveis:
# KEYSTORE_BASE64: conteúdo do arquivo keystore.base64.txt
# KEYSTORE_PASSWORD: senha do keystore
# KEY_ALIAS: alias da chave
# KEY_PASSWORD: senha da chave
```

### Solução 2: Resetar a Chave (Apenas para Apps Novos)

⚠️ **ATENÇÃO**: Esta solução só funciona se:
- O app NUNCA foi publicado na Play Store
- Está apenas em teste interno/fechado
- Você pode criar uma nova versão do app

#### Passos:

1. **Delete todas as versões do app no Play Console**:
   - Vá para Release → Production/Testing
   - Delete todas as versões
   - Aguarde algumas horas

2. **Gere um novo AAB com o keystore atual**:
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

3. **Faça upload do novo AAB**:
   - O Play Console registrará a nova chave
   - Todos os uploads futuros devem usar esta chave

### Solução 3: Usar Google Play App Signing (Recomendado para Novos Apps)

Se você ainda não ativou o Google Play App Signing:

1. **No primeiro upload**, o Play Console oferece ativar App Signing
2. **Aceite** - O Google gerenciará a chave de assinatura final
3. **Você usa uma "upload key"** - Pode ser trocada se perdida
4. **Benefícios**:
   - Pode resetar a upload key se perder
   - Google gerencia a chave de produção
   - Mais seguro

## Verificar Impressão Digital do Keystore

### Verificar Keystore Local

```bash
keytool -list -v -keystore android/keystore/synclife-release-key.jks -alias synclife-key
```

Procure por:
```
Certificate fingerprints:
     SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
     SHA256: ...
```

### Verificar AAB Assinado

```bash
# Extrair certificado do AAB
unzip -p build/app/outputs/bundle/release/app-release.aab META-INF/CERT.RSA > cert.rsa

# Ver informações do certificado
keytool -printcert -file cert.rsa
```

## Configuração Correta no CodeMagic

### Atualizar codemagic.yaml

Se você encontrou o keystore correto, atualize o workflow:

```yaml
workflows:
  android-aab-release:
    name: Android AAB Release (Google Play)
    environment:
      groups:
        - keystore_credentials  # Grupo com as variáveis corretas
    scripts:
      - name: Setup keystore
        script: |
          # Usar o keystore correto das variáveis de ambiente
          echo $KEYSTORE_BASE64 | base64 --decode > android/keystore/synclife-release-key.jks
          
          # Verificar impressão digital
          keytool -list -v -keystore android/keystore/synclife-release-key.jks \
            -storepass $KEYSTORE_PASSWORD -alias $KEY_ALIAS | grep SHA1
          
      - name: Create key.properties
        script: |
          cat > android/key.properties << EOF
          storePassword=$KEYSTORE_PASSWORD
          keyPassword=$KEY_PASSWORD
          keyAlias=$KEY_ALIAS
          storeFile=../keystore/synclife-release-key.jks
          EOF
```

## Prevenir Este Problema no Futuro

### 1. Backup do Keystore

```bash
# Fazer backup imediatamente
cp android/keystore/synclife-release-key.jks ~/Backups/
cp android/key.properties ~/Backups/

# Backup em nuvem (criptografado)
# Use um gerenciador de senhas ou serviço de backup seguro
```

### 2. Documentar Credenciais

Crie um arquivo `KEYSTORE_INFO.md` (NÃO commite no git):

```markdown
# Keystore Information

- **File**: synclife-release-key.jks
- **Alias**: synclife-key
- **SHA1**: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7
- **Created**: 2024-XX-XX
- **Validity**: 10000 days
- **Location**: 
  - Production: CodeMagic environment variables
  - Backup 1: Google Drive (encrypted)
  - Backup 2: Password manager
```

### 3. Usar Google Play App Signing

- Ative no primeiro upload
- Permite resetar a upload key
- Google gerencia a chave de produção

## Troubleshooting

### Não Consigo Encontrar o Keystore Original

**Opções**:

1. **Procure em backups**:
   - Time Machine (Mac)
   - Histórico de arquivos (Windows)
   - Backups em nuvem
   - Repositórios Git antigos (se foi commitado por engano)

2. **Verifique outros computadores**:
   - Computador de trabalho
   - Laptop pessoal
   - Servidor de CI/CD antigo

3. **Entre em contato com o Google**:
   - Se o app nunca foi publicado, pode deletar e recriar
   - Se foi publicado, precisará do keystore original

### O Keystore Está Corrompido

```bash
# Tentar recuperar informações
keytool -list -v -keystore keystore.jks

# Se der erro, o arquivo pode estar corrompido
# Tente restaurar de backup
```

### Esqueci a Senha do Keystore

⚠️ **Não há como recuperar a senha de um keystore**

Opções:
1. Procure a senha em:
   - Gerenciador de senhas
   - Arquivos de configuração antigos
   - Notas/documentação
   - Variáveis de ambiente antigas

2. Se não encontrar:
   - Para apps não publicados: Gere novo keystore
   - Para apps publicados: Não há solução (não pode atualizar o app)

## Checklist de Resolução

- [ ] Identifiquei qual keystore o Play Console espera (SHA1)
- [ ] Encontrei o keystore correto OU decidi resetar
- [ ] Verifiquei a impressão digital do keystore
- [ ] Configurei as credenciais no CodeMagic
- [ ] Testei o build localmente
- [ ] Verifiquei a impressão digital do AAB gerado
- [ ] Fiz backup do keystore em local seguro
- [ ] Documentei as credenciais
- [ ] Considerei ativar Google Play App Signing

## Comandos Úteis

```bash
# Ver informações do keystore
keytool -list -v -keystore keystore.jks -alias alias-name

# Ver apenas SHA1
keytool -list -v -keystore keystore.jks -alias alias-name | grep SHA1

# Verificar AAB
jarsigner -verify -verbose -certs app-release.aab

# Extrair e ver certificado do AAB
unzip -p app-release.aab META-INF/CERT.RSA | keytool -printcert

# Comparar impressões digitais
echo "Esperado: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7"
keytool -list -v -keystore keystore.jks -alias alias-name | grep SHA1
```

## Referências

- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Keystore Management](https://developer.android.com/studio/publish/app-signing#secure-key)
