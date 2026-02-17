# 🚨 CORREÇÃO URGENTE: Chave de Assinatura Incorreta

## Situação Atual

O Google Play Console está rejeitando seus uploads porque cada build usa uma chave diferente:

- **Esperada**: `F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7`
- **Build 1**: `C6:8C:C0:17:C1:8C:5D:F8:15:35:57:88:64:20:AF:16:52:EE:8D:AC`
- **Build 2**: `EE:10:B1:D0:05:FD:9C:44:33:4B:97:2C:D4:60:41:9B:ED:FE:DA:5A`

**Causa**: O CodeMagic está gerando um keystore novo a cada build.

## ✅ Solução Definitiva (Escolha UMA)

### Opção 1: App Nunca Foi Publicado (MAIS FÁCIL) ⭐

Se o app está apenas em teste interno e nunca foi publicado para usuários:

#### Passo 1: Limpar o Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app
3. Vá para **Versões** → **Produção** (ou Testing)
4. **Delete TODAS as versões** do app
5. **Aguarde 2-4 horas** para o sistema processar

#### Passo 2: Gerar Keystore Permanente

No seu computador local:

```bash
# Tornar o script executável
chmod +x scripts/setup_keystore_codemagic.sh

# Executar o script
bash scripts/setup_keystore_codemagic.sh
```

O script irá:
- ✅ Gerar um keystore permanente
- ✅ Mostrar a impressão digital SHA1
- ✅ Converter para base64 para o CodeMagic
- ✅ Fornecer as variáveis de ambiente

#### Passo 3: Configurar no CodeMagic

1. Acesse [CodeMagic Dashboard](https://codemagic.io)
2. Selecione seu app
3. Vá para **App settings** → **Environment variables**
4. Adicione as variáveis fornecidas pelo script:
   - `KEYSTORE_BASE64` (marque como Secure)
   - `KEYSTORE_PASSWORD` (marque como Secure)
   - `KEY_ALIAS` (marque como Secure)
   - `KEY_PASSWORD` (marque como Secure)
5. Salve

#### Passo 4: Criar Grupo de Variáveis (Opcional mas Recomendado)

1. No CodeMagic, vá para **Teams** → **Environment variables**
2. Crie um grupo chamado `keystore_credentials`
3. Adicione as 4 variáveis acima ao grupo
4. No `codemagic.yaml`, o workflow já está configurado para usar este grupo

#### Passo 5: Executar Build

1. No CodeMagic, execute o workflow **Android AAB Release (Google Play)**
2. Verifique nos logs a impressão SHA1 do keystore usado
3. Faça download do AAB gerado

#### Passo 6: Upload para Play Console

1. Faça upload do novo AAB
2. O Play Console registrará esta nova chave
3. Todos os uploads futuros devem usar a mesma chave (agora configurada no CodeMagic)

---

### Opção 2: Você Tem o Keystore Original

Se você fez um upload anterior de outro lugar e tem o keystore original:

#### Passo 1: Localizar o Keystore Original

Procure por um arquivo `.jks` ou `.keystore` que tenha a impressão:
```
SHA1: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7
```

Locais comuns:
- `android/app/`
- `android/keystore/`
- Seu computador pessoal
- Backups em nuvem
- Outro servidor CI/CD

#### Passo 2: Verificar o Keystore

```bash
# Verificar impressão digital
keytool -list -v -keystore caminho/para/seu-keystore.jks

# Procure por:
# SHA1: F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7
```

#### Passo 3: Converter para Base64

```bash
# No Linux/Mac
base64 -i seu-keystore.jks -o keystore.base64.txt

# No Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("seu-keystore.jks")) > keystore.base64.txt
```

#### Passo 4: Configurar no CodeMagic

Siga os mesmos passos da Opção 1, Passo 3.

---

### Opção 3: App Já Publicado e Keystore Perdido ⚠️

**SITUAÇÃO CRÍTICA**: Se o app já foi publicado e você perdeu o keystore:

#### Consequências
- ❌ Não pode atualizar o app existente
- ❌ Precisa publicar como novo app (novo package name)
- ❌ Perde todos os usuários, reviews, estatísticas

#### Última Tentativa de Recuperação

1. **Procure em TODOS os lugares**:
   - Backups do Time Machine (Mac)
   - Histórico de arquivos (Windows)
   - Commits antigos do Git (mesmo que no .gitignore)
   - Outros computadores
   - Servidores antigos
   - Pergunte a outros desenvolvedores do projeto

2. **Verifique o Google Play App Signing**:
   - Se você ativou o App Signing gerenciado pelo Google
   - Você pode gerar uma nova "upload key"
   - Vá para Play Console → App integrity → Upload key
   - Siga as instruções para gerar nova upload key

3. **Entre em contato com o Google**:
   - Suporte do Google Play Console
   - Explique a situação
   - Eles podem ajudar em casos específicos

---

## 🔍 Como Verificar Qual Opção Usar

### Verificar se o App Foi Publicado

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app
3. Vá para **Versões** → **Produção**
4. Verifique o status:
   - **"Rascunho"** ou **"Teste interno/fechado"**: Use Opção 1
   - **"Publicado"** ou **"Em análise"**: Use Opção 2 ou 3

### Verificar se Tem o Keystore Original

Execute no seu computador:

```bash
# Procurar por keystores
find ~ -name "*.jks" -o -name "*.keystore" 2>/dev/null

# Para cada keystore encontrado, verificar impressão
keytool -list -v -keystore caminho/para/keystore.jks | grep SHA1
```

---

## 📋 Checklist de Resolução

### Para Opção 1 (App Novo)
- [ ] Confirmei que o app nunca foi publicado
- [ ] Deletei todas as versões no Play Console
- [ ] Aguardei 2-4 horas
- [ ] Executei `scripts/setup_keystore_codemagic.sh`
- [ ] Configurei as variáveis no CodeMagic
- [ ] Executei novo build
- [ ] Verifiquei a impressão SHA1 nos logs
- [ ] Fiz upload do AAB
- [ ] Upload aceito pelo Play Console ✅

### Para Opção 2 (Keystore Original)
- [ ] Encontrei o keystore original
- [ ] Verifiquei a impressão SHA1 (deve ser F0:A3:DC:4F:37:1D:C0:27:7D:20:A5:E8:00:79:CF:25:AE:98:D0:F7)
- [ ] Converti para base64
- [ ] Configurei as variáveis no CodeMagic
- [ ] Executei novo build
- [ ] Verifiquei a impressão SHA1 nos logs
- [ ] Fiz upload do AAB
- [ ] Upload aceito pelo Play Console ✅

---

## 🛡️ Prevenção Futura

### 1. Backup do Keystore

Após resolver, faça backup IMEDIATAMENTE:

```bash
# Backup local
cp android/keystore/synclife-release-key.jks ~/Backups/

# Backup em nuvem (use criptografia!)
# - Google Drive (em pasta criptografada)
# - 1Password / LastPass (como arquivo anexo)
# - Dropbox (em pasta criptografada)
```

### 2. Documentar Credenciais

Salve em local seguro:
- Senha do keystore
- Senha da chave
- Alias da chave
- Impressão SHA1
- Data de criação

### 3. Ativar Google Play App Signing

No próximo upload:
1. Play Console oferecerá ativar App Signing
2. **ACEITE** - Permite trocar a upload key se perder
3. Google gerencia a chave de produção

---

## 🆘 Precisa de Ajuda?

### Logs Úteis

No CodeMagic, verifique nos logs do build:

```
🔐 Keystore SHA1 fingerprint:
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Esta impressão DEVE ser sempre a mesma em todos os builds.

### Comandos de Verificação

```bash
# Ver impressão do keystore local
keytool -list -v -keystore android/keystore/synclife-release-key.jks

# Ver impressão do AAB gerado
unzip -p build/app/outputs/bundle/release/app-release.aab META-INF/CERT.RSA | keytool -printcert | grep SHA1

# Comparar (devem ser iguais)
```

---

## ⏱️ Tempo Estimado

- **Opção 1**: 30 minutos + 2-4 horas de espera
- **Opção 2**: 15 minutos (se tiver o keystore)
- **Opção 3**: Dias/semanas (recuperação complexa)

---

## 🎯 Próximo Passo

**Qual opção se aplica ao seu caso?**

1. App nunca foi publicado → Use **Opção 1**
2. Tenho o keystore original → Use **Opção 2**
3. App publicado e keystore perdido → Use **Opção 3**

Escolha a opção e siga os passos detalhados acima.
