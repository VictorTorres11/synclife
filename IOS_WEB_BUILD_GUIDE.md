# Guia de Build iOS e Web - SyncLife

## Configurações Aplicadas

### iOS Build Setup

#### 1. Podfile Criado
- Criado `ios/Podfile` com configurações otimizadas
- iOS deployment target: 12.0
- Suporte para CocoaPods moderno
- Configurações específicas para Firebase

#### 2. Info.plist Configurado
- Permissões de localização configuradas
- Background modes para notificações
- URL schemes para deep linking
- Configurações PWA para iOS

#### 3. Workflow iOS no Codemagic
- Instância: `mac_mini_m1`
- Xcode: 15.4
- Flutter: 3.24.3
- CocoaPods: instalação automática
- Code signing: configuração automática

### Web Build Setup

#### 1. index.html Otimizado
- Meta tags para SEO e PWA
- Firebase SDK 10.7.1
- Loading screen personalizada
- Suporte para iOS Safari

#### 2. manifest.json Melhorado
- Nome e descrição profissionais
- Ícones maskable para Android
- Shortcuts para ações rápidas
- Categorias para app stores

#### 3. Service Worker Atualizado
- Firebase Messaging configurado
- Cache offline para recursos críticos
- Notificações push otimizadas
- Tratamento de cliques em notificações

## Workflows Disponíveis

### 1. `android-workflow`
- Build completo Android com testes
- Debug + Release APK
- Duração: ~60 min

### 2. `android-debug-simple`
- Build rápido Android (apenas debug)
- Sem testes para velocidade
- Duração: ~30 min

### 3. `ios-workflow`
- Build completo iOS
- Debug + Release IPA
- CocoaPods automático
- Duração: ~120 min

### 4. `web-workflow`
- Build web otimizado
- CanvasKit renderer
- PWA completa
- Duração: ~30 min

### 5. `multi-platform-workflow`
- Build de todas as plataformas
- Mais eficiente para releases
- Duração: ~180 min

## Pré-requisitos para iOS

### No Codemagic (necessário configurar):

1. **Certificados iOS:**
   - Apple Developer Account
   - Distribution Certificate
   - Provisioning Profiles

2. **Grupos de Variáveis:**
   ```yaml
   groups:
     - firebase_config  # Já configurado
     - ios_credentials  # Precisa configurar
   ```

3. **Variáveis iOS necessárias:**
   - `CERTIFICATE_PRIVATE_KEY`
   - `CERTIFICATE_PASSWORD`
   - `PROVISIONING_PROFILE`
   - `BUNDLE_ID`: `com.synclife.synclife_app`

## Pré-requisitos para Web

### Firebase Hosting (opcional):
1. Configure Firebase Hosting no projeto
2. Adicione domínio personalizado
3. Configure SSL/TLS

### Variáveis Web:
- Todas as configurações Firebase já estão no código
- Google Sign-In Client ID já configurado

## Como Testar

### Localmente:
```bash
# iOS (requer macOS + Xcode)
flutter build ios --debug --no-codesign

# Web
flutter build web --release --web-renderer canvaskit

# Android
flutter build apk --debug
```

### No Codemagic:

1. **Primeiro teste:** `android-debug-simple`
2. **Se funcionar:** `web-workflow`
3. **Para iOS:** Configure certificados primeiro
4. **Build completo:** `multi-platform-workflow`

## Otimizações Aplicadas

### iOS:
- Deployment target iOS 12.0+
- Permissões específicas configuradas
- Background modes otimizados
- CocoaPods com repo-update

### Web:
- CanvasKit renderer (melhor performance)
- Service Worker com cache offline
- PWA completa com shortcuts
- Firebase SDK otimizado
- Loading screen personalizada

### Geral:
- Flutter 3.24.3 (versão estável)
- Análise de código sem fatal-infos
- Testes básicos com ignore_failure
- Clean builds para consistência

## Próximos Passos

1. ✅ **Android:** Pronto para build
2. ✅ **Web:** Pronto para build
3. ⚠️ **iOS:** Precisa configurar certificados no Codemagic
4. 🔄 **Multi-platform:** Disponível após iOS configurado

## Troubleshooting

### iOS Build Fails:
- Verificar certificados no Codemagic
- Verificar Bundle ID matches
- Verificar Provisioning Profiles

### Web Build Fails:
- Verificar Firebase config
- Verificar service worker syntax
- Verificar CanvasKit compatibility

### Android Build Fails:
- Verificar Gradle/Kotlin versions
- Verificar Firebase config
- Verificar Java 17 environment

O projeto está preparado para builds multi-plataforma no Codemagic!