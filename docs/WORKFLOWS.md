# Workflows do Projeto

Este documento descreve todos os workflows disponíveis no projeto, incluindo GitHub Actions e Codemagic.

## 🚀 Plataformas de CI/CD

### GitHub Actions
- Integração nativa com GitHub
- Workflows em `.github/workflows/`
- Grátis: 2000 minutos/mês

### Codemagic  
- Especializado em Flutter
- Configuração em `codemagic.yaml`
- Grátis: 500 minutos/mês
- **Recomendado para AAB builds**

## GitHub Actions Workflows

### 1. CI/CD Pipeline (`ci.yml`)

**Trigger:** Push ou Pull Request para `main` ou `develop`

**Funcionalidades:**
- ✅ Executa testes automatizados
- ✅ Análise de código com Flutter Analyze
- ✅ Build APK para Android (apenas branch main)
- ✅ Build iOS sem assinatura (apenas branch main)
- ✅ Build e deploy Web para Firebase Hosting (apenas branch main)
- ✅ Upload de coverage para Codecov

### 2. Android Release AAB (`android-release.yml`)

**Trigger:** Manual (workflow_dispatch)

**Funcionalidades:**
- 🚀 Build Android App Bundle (AAB) para release
- 🔐 Keystore automático ou personalizado
- 📦 Upload automático de artifacts
- 🏷️ Criação automática de release no GitHub
- 📝 Versionamento automático

## Codemagic Workflows

### 1. Android Debug APK (`android-debug`)
- Build APK debug rápido
- Para testes internos

### 2. Android Release APK (`android-release`)  
- Build APK release
- Para distribuição direta

### 3. **Android AAB Minimal (`android-aab-minimal`) ⭐ NOVO**
- **Build AAB otimizado para Google Play**
- **90 minutos timeout (vs 60 min)**
- **Cache do Gradle para builds mais rápidos**
- **Keystore gerado diretamente no workflow**
- **Recomendado para releases**

### 4. **Android AAB Release (`android-aab-release`)**
- Build AAB para Google Play
- Keystore via variáveis de ambiente
- Para configurações avançadas

### 5. Code Analysis (`code-analysis`)
- Análise de código em PRs
- Não bloqueia builds

### 5. iOS Debug (`ios-debug`)
- Build iOS debug
- Sem code signing

## 🎯 Qual Usar?

### Para AAB (Google Play) - **Codemagic Recomendado**

**Vantagens do Codemagic:**
- ✅ Keystore gerado automaticamente
- ✅ Setup mais simples (zero configuração)
- ✅ Especializado em Flutter
- ✅ Build mais rápido (~5-10 min)
- ✅ Funciona imediatamente

**Como usar:**
1. Acesse Codemagic Dashboard
2. Selecione "Android AAB Minimal (Google Play)" ⭐ NOVO
3. Execute build (90 min timeout)
4. Baixe AAB dos artifacts

**Melhorias do workflow minimal:**
- ✅ Timeout estendido (90 min vs 60 min)
- ✅ Cache do Gradle e Flutter dependencies
- ✅ Keystore gerado diretamente (sem scripts)
- ✅ Tratamento robusto de erros
- ✅ Verificação aprimorada do AAB

### Para APK/Web/iOS - GitHub Actions

**Vantagens do GitHub Actions:**
- ✅ Integração nativa com GitHub
- ✅ Mais minutos grátis
- ✅ Melhor para automação completa
- ✅ Deploy automático web

## Como Usar os Workflows

### Codemagic AAB (Recomendado)

1. **Primeira vez:**
   - Acesse [Codemagic](https://codemagic.io)
   - Conecte seu repositório GitHub
   - Não precisa configurar nada!

2. **Build:**
   - Dashboard > Seu projeto
   - Workflow: "Android AAB Minimal (Google Play)" ⭐ RECOMENDADO
   - "Start new build"

3. **Download:**
   - Aguarde build completar
   - Baixe AAB dos artifacts
   - Upload para Google Play Console

### GitHub Actions AAB

1. **Configuração (opcional):**
   - Configure secrets para keystore personalizado
   - Ou use keystore automático

2. **Build:**
   - Actions > "Android Release AAB"
   - "Run workflow"
   - Preencha versão e notas

### Configuração de Secrets

#### GitHub Actions (Opcional)
- `KEYSTORE_BASE64`: Keystore em base64
- `KEYSTORE_PASSWORD`: Senha do keystore  
- `KEY_PASSWORD`: Senha da chave
- `KEY_ALIAS`: Alias da chave

#### Codemagic (Opcional)
- Grupo: `keystore_credentials`
- Mesmas variáveis do GitHub Actions
- **Se não configurar, keystore é gerado automaticamente**

## Artifacts Gerados

### GitHub Actions
- `android-release-aab-v{version}`: AAB assinado
- `generated-keystore-v{version}`: Keystore (se gerado)

### Codemagic
- `app-release.aab`: AAB assinado
- `synclife-release-key.jks`: Keystore
- `mapping.txt`: Para debugging

## 🛠️ Troubleshooting

### Codemagic Build Falha
1. Verifique logs no dashboard
2. Confirme que código compila localmente
3. Verifique dependências no pubspec.yaml

### GitHub Actions Falha
1. Verifique logs na aba Actions
2. Confirme secrets (se usando keystore personalizado)
3. Teste build local primeiro

### Keystore Issues
- **Codemagic**: Use keystore automático (não configure variáveis)
- **GitHub Actions**: Use keystore automático ou configure secrets

## 📊 Comparação Detalhada

| Aspecto | Codemagic AAB | GitHub Actions AAB |
|---------|---------------|-------------------|
| **Setup** | Zero config | Config opcional |
| **Keystore** | Automático | Automático ou manual |
| **Build time** | 5-10 min | 10-15 min |
| **Facilidade** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Flexibilidade** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Minutos grátis** | 500/mês | 2000/mês |

## 🎯 Recomendação Final

**Para começar rapidamente com AAB:**
1. ✅ Use Codemagic `android-aab-minimal` ⭐ NOVO
2. ✅ Não configure nada (keystore automático)
3. ✅ Execute build (90 min timeout)
4. ✅ Baixe AAB dos artifacts
5. ✅ Upload para Google Play Console

**⚠️ Problema Resolvido:**
- **Erro anterior**: Build timeout durante download de dependências
- **Solução**: Workflow `android-aab-minimal` com cache e timeout estendido
- **Verificação**: Logs mostram cache hits e keystore gerado

**Para automação completa:**
1. ✅ Use GitHub Actions para CI/CD geral
2. ✅ Use Codemagic para releases AAB
3. ✅ Combine ambos conforme necessário

## Documentação Relacionada

- [CODEMAGIC_AAB_SETUP.md](./CODEMAGIC_AAB_SETUP.md): Setup detalhado Codemagic
- [ANDROID_RELEASE_SETUP.md](./ANDROID_RELEASE_SETUP.md): Setup GitHub Actions
- [SETUP.md](./SETUP.md): Configuração inicial do projeto