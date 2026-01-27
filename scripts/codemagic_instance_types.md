# 🖥️ Tipos de Instância Codemagic - Planos e Disponibilidade

## 📋 Plano Gratuito (500 min/mês)

### ✅ Instâncias Disponíveis:
- `mac_mini_m1` - **Recomendado para Flutter**
  - CPU: Apple M1 (8 cores)
  - RAM: 8GB
  - Suporta: Android + iOS builds
  - Velocidade: Rápida

- `linux` - Básico Linux
  - CPU: 2 cores
  - RAM: 4GB
  - Suporta: Apenas Android
  - Velocidade: Mais lenta

### ❌ Não Disponíveis (Planos Pagos):
- `linux_x2` - Linux com mais recursos
- `mac_pro` - Mac Pro com mais poder
- `windows` - Instâncias Windows

## 🎯 Configuração Otimizada (Gratuito)

### Para Android Builds:
```yaml
instance_type: mac_mini_m1  # Melhor opção gratuita
environment:
  flutter: 3.38.7
  java: 17
```

### Vantagens do Mac Mini M1:
- ✅ Builds Android mais rápidos
- ✅ Suporte completo ao Flutter
- ✅ Pode fazer iOS também
- ✅ Incluído no plano gratuito
- ✅ Apple Silicon (M1) é muito rápido

## ⏱️ Tempos de Build Estimados

### Mac Mini M1:
- **Debug APK**: ~8-12 minutos
- **Release APK**: ~15-20 minutos
- **iOS Debug**: ~10-15 minutos

### Linux Básico:
- **Debug APK**: ~15-20 minutos
- **Release APK**: ~25-35 minutos
- **iOS**: ❌ Não suportado

## 💡 Dicas de Otimização

### 1. Usar Cache
```yaml
cache:
  cache_paths:
    - $FLUTTER_ROOT/.pub-cache
    - $HOME/.gradle/caches
```

### 2. Builds Paralelos
```yaml
# Não executar todos workflows ao mesmo tempo
# Use triggers específicos por branch
```

### 3. Monitorar Uso
- 500 minutos gratuitos/mês
- Mac Mini M1 consome ~15-20 min por build
- ~25-30 builds por mês no gratuito

## 🔄 Alternativas se Esgotar Minutos

### 1. Builds Locais
```bash
# Para desenvolvimento diário
flutter build apk --debug
```

### 2. Builds Seletivos
```yaml
triggering:
  events:
    - push
  branch_patterns:
    - pattern: 'main'
      include: true
    # Não buildar em todas as branches
```

### 3. Upgrade Temporário
- Plano Pro: $28/mês
- Mais instâncias disponíveis
- Mais minutos incluídos

## 📊 Comparação de Performance

| Instância | CPU | RAM | Android | iOS | Velocidade |
|-----------|-----|-----|---------|-----|------------|
| mac_mini_m1 | M1 8-core | 8GB | ✅ | ✅ | 🚀🚀🚀 |
| linux | 2-core | 4GB | ✅ | ❌ | 🚀 |
| linux_x2 | 4-core | 8GB | ✅ | ❌ | 🚀🚀 (Pago) |

## 🎯 Recomendação Atual

### ✅ Use `mac_mini_m1` porque:
1. **Incluído no gratuito**
2. **Melhor performance**
3. **Suporta Android + iOS**
4. **Apple M1 é muito rápido**
5. **Mesmo que você usava antes**

### 📝 Configuração Aplicada:
```yaml
instance_type: mac_mini_m1  # ✅ Disponível no gratuito
max_build_duration: 30      # ✅ Suficiente para a maioria
```

---

**🎉 Agora seus builds devem funcionar no plano gratuito!**