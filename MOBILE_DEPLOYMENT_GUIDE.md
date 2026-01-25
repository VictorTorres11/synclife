# Guia de Deploy Mobile - SyncLife

## 📱 Pré-requisitos

### Para Android:
- ✅ Flutter SDK instalado
- ✅ Android Studio com SDK configurado
- ✅ Dispositivo Android ou emulador
- ✅ Cabo USB (para dispositivo físico)

### Para iOS:
- ❌ macOS com Xcode (apenas no Mac)
- ❌ Conta de desenvolvedor Apple
- ❌ Dispositivo iOS ou simulador

## 🔧 Configuração Inicial

### 1. Configurar Android SDK
```bash
# Execute o script de configuração
scripts/setup_android.bat

# Ou configure manualmente:
# 1. Instale Android Studio
# 2. Configure ANDROID_HOME
# 3. Aceite as licenças: flutter doctor --android-licenses
```

### 2. Verificar Configuração
```bash
flutter doctor
```

## 📦 Compilação

### Android

#### APK Debug (Teste Rápido)
```bash
flutter build apk --debug
# Localização: build/app/outputs/flutter-apk/app-debug.apk
```

#### APK Release (Distribuição)
```bash
flutter build apk --release
# Localização: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (Google Play)
```bash
flutter build appbundle --release
# Localização: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Apenas no macOS)
```bash
# Para simulador
flutter build ios --simulator

# Para dispositivo
flutter build ios --release
```

## 📲 Instalação no Dispositivo

### Android

#### 1. Habilitar Depuração USB
1. Vá em **Configurações > Sobre o telefone**
2. Toque 7 vezes em **Número da versão**
3. Vá em **Configurações > Opções do desenvolvedor**
4. Ative **Depuração USB**

#### 2. Conectar e Instalar
```bash
# Verificar dispositivos
flutter devices

# Instalar diretamente
flutter install

# Ou executar em tempo real
flutter run --release
```

#### 3. Instalar APK Manualmente
1. Transfira o APK para o dispositivo
2. Abra o arquivo no dispositivo
3. Permita instalação de fontes desconhecidas
4. Instale o aplicativo

### iOS

#### 1. Conectar Dispositivo
1. Conecte iPhone via USB
2. Confie no computador
3. Execute: `flutter devices`

#### 2. Instalar
```bash
flutter run --release
```

## 🛠️ Scripts Disponíveis

### Windows
- `scripts/build_android.bat` - Build interativo para Android
- `scripts/build_ios.bat` - Referência para iOS
- `scripts/test_device.bat` - Teste no dispositivo
- `scripts/setup_android.bat` - Configuração do Android

### Comandos Diretos
```bash
# Build rápido para teste
flutter run --debug

# Build otimizado
flutter run --release

# Apenas instalar
flutter install

# Ver logs
flutter logs
```

## 🔍 Troubleshooting

### Problemas Comuns

#### "No devices found"
- Verifique se a depuração USB está ativa
- Reconecte o cabo USB
- Execute: `flutter devices`

#### "Android toolchain not found"
- Execute: `scripts/setup_android.bat`
- Configure ANDROID_HOME
- Execute: `flutter doctor --android-licenses`

#### "Build failed"
- Execute: `flutter clean && flutter pub get`
- Verifique se todas as dependências estão atualizadas
- Verifique os logs de erro

#### APK não instala
- Ative "Fontes desconhecidas" nas configurações
- Verifique se há espaço suficiente
- Desinstale versões anteriores

## 📊 Tamanhos de Build

### Android
- **APK Debug**: ~50-80 MB
- **APK Release**: ~25-40 MB
- **App Bundle**: ~20-30 MB

### Otimizações
- Use `--split-per-abi` para APKs menores
- Use App Bundle para Google Play
- Remova recursos não utilizados

## 🚀 Deploy para Lojas

### Google Play Store
1. Use App Bundle (`.aab`)
2. Configure assinatura no Play Console
3. Siga as diretrizes do Google Play

### Apple App Store
1. Use Xcode para criar IPA
2. Configure certificados de desenvolvedor
3. Siga as diretrizes da App Store

## 📝 Checklist de Deploy

- [ ] Testes funcionais completos
- [ ] Verificação de performance
- [ ] Teste em diferentes dispositivos
- [ ] Configuração de Firebase
- [ ] Ícones e splash screens
- [ ] Permissões necessárias
- [ ] Versioning correto
- [ ] Assinatura de release