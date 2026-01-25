# 🚀 Guia de Configuração Codemagic - SyncLife

## 📋 Pré-requisitos

- [ ] Conta no GitHub/GitLab/Bitbucket
- [ ] Projeto commitado no repositório
- [ ] Arquivo `google-services.json` configurado
- [ ] Firebase configurado

## 🔧 Configuração Inicial

### 1. Criar Conta no Codemagic
1. Acesse [codemagic.io](https://codemagic.io)
2. Faça login com sua conta Git
3. **500 minutos grátis por mês** - sem cartão de crédito

### 2. Conectar Repositório
1. Clique em "Add application"
2. Selecione seu repositório SyncLife
3. Escolha "Flutter App"
4. Codemagic detectará automaticamente o `codemagic.yaml`

### 3. Configurar Variáveis de Ambiente

#### Variáveis Obrigatórias:
```
FIREBASE_API_KEY = sua_api_key_do_firebase
FIREBASE_PROJECT_ID = seu_project_id
FIREBASE_APP_ID = seu_app_id
```

#### Para Builds de Release:
```
KEYSTORE_PASSWORD = senha_do_keystore
KEY_ALIAS = alias_da_chave
KEY_PASSWORD = senha_da_chave
```

### 4. Upload do google-services.json
1. Vá em "Environment variables"
2. Adicione como "Secure file"
3. Nome: `google-services.json`
4. Upload do arquivo do Firebase

## 🏗️ Workflows Disponíveis

### 1. **android-debug** (Desenvolvimento)
- ⚡ Build rápido (30-60 min)
- 📱 APK debug para testes
- 🔄 Sem assinatura necessária
- 📧 Notificação por email

### 2. **android-release** (Produção)
- 🏭 Build completo com testes
- 📦 APK + App Bundle
- 🔐 Assinatura de release
- 📊 Análise de código

## 🚀 Como Executar um Build

### Método 1: Push Automático
```bash
git add .
git commit -m "feat: nova funcionalidade"
git push origin main
```
O build inicia automaticamente!

### Método 2: Build Manual
1. Acesse o dashboard do Codemagic
2. Selecione o workflow desejado
3. Clique em "Start new build"
4. Escolha a branch

## 📱 Testando no Dispositivo

### Opção 1: Download Direto
1. Build completo → Email com link
2. Abra o link no celular
3. Baixe e instale o APK

### Opção 2: QR Code
1. Codemagic gera QR code
2. Escaneie com o celular
3. Instalação direta

### Opção 3: Distribuição
- **Firebase App Distribution**
- **Google Play Internal Testing**
- **TestFlight** (iOS)

## ⚙️ Configurações Avançadas

### Build Triggers
```yaml
triggering:
  events:
    - push
    - tag
    - pull_request
  branch_patterns:
    - pattern: 'main'
      include: true
    - pattern: 'develop'
      include: true
```

### Notificações
```yaml
publishing:
  email:
    recipients:
      - dev@synclife.app
      - team@synclife.app
  slack:
    channel: '#builds'
    notify_on_build_start: true
```

### Cache para Builds Mais Rápidos
```yaml
cache:
  cache_paths:
    - $FLUTTER_ROOT/.pub-cache
    - $HOME/.gradle/caches
```

## 🐛 Troubleshooting

### Build Falha - Dependências
```bash
# No script de build
flutter clean
flutter pub get
flutter pub deps
```

### Erro de Assinatura
1. Verifique `key.properties`
2. Confirme variáveis de ambiente
3. Teste keystore localmente

### Timeout de Build
- Use `linux_x2` para builds mais rápidos
- Aumente `max_build_duration`
- Otimize dependências

## 📊 Monitoramento

### Métricas Importantes
- ⏱️ Tempo de build
- 📦 Tamanho do APK
- 🧪 Cobertura de testes
- 🚀 Taxa de sucesso

### Logs e Debug
- Logs completos no dashboard
- Download de artifacts
- Histórico de builds

## 💡 Dicas de Otimização

### 1. Builds Mais Rápidos
```yaml
instance_type: linux_x2  # Mais CPU/RAM
cache: true              # Cache de dependências
```

### 2. Menor Uso de Minutos
- Use `android-debug` para desenvolvimento
- `android-release` apenas para produção
- Configure triggers específicos

### 3. Melhor Experiência
- Configure notificações Slack
- Use Firebase App Distribution
- Automatize testes

## 🔄 Fluxo de Trabalho Recomendado

1. **Desenvolvimento Local**
   ```bash
   flutter run --debug
   ```

2. **Push para Teste**
   ```bash
   git push origin develop
   # Trigger: android-debug
   ```

3. **Release Candidate**
   ```bash
   git push origin main
   # Trigger: android-release
   ```

4. **Distribuição**
   - APK → Testes internos
   - AAB → Google Play Store

## 📞 Suporte

- 📚 [Documentação Codemagic](https://docs.codemagic.io)
- 💬 [Community Slack](https://codemagic.io/slack)
- 📧 [Suporte](mailto:support@codemagic.io)

---

**🎉 Pronto! Seu projeto SyncLife está configurado para builds automáticos na nuvem!**