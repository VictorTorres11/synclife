# Codemagic AAB Setup Guide

Este guia explica como usar o Codemagic para gerar Android App Bundle (AAB) automaticamente.

## 🚀 Workflow Disponível

O workflow `android-aab-release` no Codemagic gera automaticamente:
- ✅ Keystore (se não fornecido)
- ✅ Android App Bundle (AAB) assinado
- ✅ Mapping files para debugging
- ✅ Artifacts prontos para Google Play

## 📋 Configuração no Codemagic

### 1. Variáveis de Ambiente (Opcionais)

No Codemagic, você pode criar um grupo de variáveis chamado `keystore_credentials`:

**Variáveis opcionais:**
- `KEYSTORE_BASE64`: Keystore existente codificado em base64
- `KEYSTORE_PASSWORD`: Senha do keystore (padrão: synclife123)
- `KEY_PASSWORD`: Senha da chave (padrão: synclife123)  
- `KEY_ALIAS`: Alias da chave (padrão: synclife-key)

### 2. Como Configurar Variáveis

1. Acesse Codemagic Dashboard
2. Vá para Team settings > Global variables and secrets
3. Crie um grupo chamado `keystore_credentials`
4. Adicione as variáveis (todas opcionais)

### 3. Keystore Automático

Se você **NÃO** configurar as variáveis, o workflow:
- ✅ Gera keystore automaticamente
- ✅ Usa credenciais padrão seguras
- ✅ Funciona imediatamente sem configuração

## 🚀 Workflows Disponíveis

### **1. Android AAB Simple (Recomendado para começar) ⭐**
- ✅ **Zero configuração** - funciona imediatamente
- ✅ **Keystore automático** - gerado via script
- ✅ **Build rápido** - ~5-10 minutos
- ✅ **Pronto para Google Play** - AAB assinado

### 2. Android AAB Release (Avançado)
- ✅ Keystore personalizado via variáveis
- ✅ Configuração manual de credenciais
- ✅ Controle total sobre assinatura

### Como Usar

**Opção 1: Workflow Simple (Recomendado)**
1. Acesse Codemagic Dashboard
2. Selecione "Android AAB Simple (Google Play)"
3. Execute o build
4. Baixe AAB dos artifacts

**Opção 2: Workflow Release (Avançado)**
1. Configure variáveis no grupo `keystore_credentials`
2. Execute "Android AAB Release (Google Play)"
3. Baixe AAB dos artifacts

## 📦 Artifacts Gerados

Após o build, você terá:

1. **AAB File**: `app-release.aab` - Pronto para Google Play
2. **Keystore**: `synclife-release-key.jks` - Para futuros builds
3. **Mapping**: Para debugging de crashes

## 📱 Upload para Google Play Console

1. Baixe o AAB dos artifacts do Codemagic
2. Acesse [Google Play Console](https://play.google.com/console)
3. Vá para "Release" > "Testing" > "Internal testing"
4. Clique em "Create new release"
5. Upload o arquivo AAB
6. Adicione release notes
7. Publique para testing

## 🔐 Segurança do Keystore

### Keystore Gerado Automaticamente

Se usar keystore automático:
- ✅ Credenciais padrão seguras
- ✅ Keystore salvo nos artifacts
- ✅ Válido por 27 anos
- ⚠️ **IMPORTANTE**: Baixe e guarde o keystore!

### Keystore Personalizado

Para usar seu próprio keystore:

1. Codifique em base64:
```bash
# Linux/Mac
base64 -i seu-keystore.jks

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("seu-keystore.jks"))
```

2. Adicione como `KEYSTORE_BASE64` no Codemagic

## 🛠️ Troubleshooting

### Build Falha - Keystore

**Erro**: "Keystore file not found for signing config 'release'"
- ✅ **Solução**: O workflow agora gera keystore automaticamente
- ✅ **Verificação**: Logs mostram se keystore foi criado
- ✅ **Fallback**: Usa credenciais padrão se variáveis não configuradas

**Erro**: "build_runner failed"
- ✅ Verifique se todas as dependências estão no pubspec.yaml
- ✅ Commit e push todas as mudanças
- ✅ Execute `dart run build_runner build --delete-conflicting-outputs` localmente

### AAB Não Gerado

**Erro**: "AAB not found"
- ✅ Verifique logs do build
- ✅ Confirme que não há erros de compilação
- ✅ Verifique se keystore foi criado corretamente

### Keystore Issues

**Para usar keystore automático (recomendado):**
- ✅ NÃO configure variáveis no Codemagic
- ✅ O workflow gera automaticamente
- ✅ Credenciais padrão: synclife123

**Para usar keystore personalizado:**
- ✅ Configure KEYSTORE_BASE64 no Codemagic
- ✅ Configure KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS
- ✅ Teste localmente primeiro

## 📊 Comparação: Codemagic vs GitHub Actions

| Recurso | Codemagic | GitHub Actions |
|---------|-----------|----------------|
| Keystore automático | ✅ | ✅ |
| Build time | ~5-10 min | ~10-15 min |
| Artifacts | 90 dias | 30 dias |
| Configuração | Mais simples | Mais flexível |
| Custo | Grátis (500 min/mês) | Grátis (2000 min/mês) |

## 🎯 Recomendação

**Para começar rapidamente:**
1. Use o workflow `android-aab-release` no Codemagic
2. NÃO configure variáveis (keystore automático)
3. Execute o build
4. Baixe o AAB e keystore dos artifacts
5. Upload para Google Play Console

**Para produção:**
1. Guarde o keystore gerado em local seguro
2. Configure variáveis personalizadas no Codemagic
3. Use o mesmo keystore para todas as versões futuras

## 📝 Próximos Passos

Após o primeiro build:

1. ✅ Teste o AAB na Google Play Console
2. ✅ Configure internal testing
3. ✅ Adicione testadores
4. ✅ Colete feedback
5. ✅ Promova para produção quando pronto

## 🔗 Links Úteis

- [Codemagic Documentation](https://docs.codemagic.io/)
- [Google Play Console](https://play.google.com/console)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)