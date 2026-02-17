# Migração do Google Play Core para Android 14+

## Problema

A biblioteca `com.google.android.play:core:1.10.3` está obsoleta e não é compatível com `targetSdkVersion 34` (Android 14), causando o seguinte erro:

```
O pacote é destinado ao SDK 34, mas usa uma biblioteca Play Core que não pode ser usada com essa versão.
com.google.android.play:core:1.10.3 biblioteca atual não funciona com a targetSdkVersion 34 (Android 14)
```

## Causa

O Android 14 introduziu mudanças incompatíveis com versões anteriores para broadcast receivers, e a biblioteca Play Core antiga não foi atualizada para lidar com essas mudanças.

## Solução Implementada

### 1. Removida a Biblioteca Antiga

❌ **Antes** (`android/app/build.gradle`):
```gradle
implementation 'com.google.android.play:core:1.10.3'
```

✅ **Depois** (`android/app/build.gradle`):
```gradle
// Google Play Core - Updated modular libraries for Android 14+ compatibility
implementation 'com.google.android.play:app-update:2.1.0'
implementation 'com.google.android.play:app-update-ktx:2.1.0'
implementation 'com.google.android.play:review:2.0.1'
implementation 'com.google.android.play:review-ktx:2.0.1'
```

### 2. Adicionada Estratégia de Resolução

No `android/build.gradle`, adicionamos uma estratégia para excluir a biblioteca antiga caso algum plugin tente incluí-la:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    configurations.all {
        resolutionStrategy {
            // Exclude the deprecated Play Core library
            exclude group: 'com.google.android.play', module: 'core'
            
            // Force use of compatible versions
            force 'com.google.android.play:app-update:2.1.0'
            force 'com.google.android.play:review:2.0.1'
        }
    }
}
```

## Bibliotecas Modulares do Play Core

A Google dividiu a biblioteca monolítica `play:core` em bibliotecas modulares:

| Funcionalidade | Biblioteca Antiga | Biblioteca Nova |
|----------------|-------------------|-----------------|
| In-app updates | `play:core` | `play:app-update` |
| In-app reviews | `play:core` | `play:review` |
| Asset delivery | `play:core` | `play:asset-delivery` |
| Feature delivery | `play:core` | `play:feature-delivery` |

### Bibliotecas Incluídas no Projeto

- `com.google.android.play:app-update:2.1.0` - Para atualizações in-app
- `com.google.android.play:app-update-ktx:2.1.0` - Extensões Kotlin
- `com.google.android.play:review:2.0.1` - Para reviews in-app
- `com.google.android.play:review-ktx:2.0.1` - Extensões Kotlin

## Verificação

### 1. Verificar Dependências

Execute o comando para listar todas as dependências e confirmar que a biblioteca antiga não está presente:

```bash
cd android
./gradlew app:dependencies | grep "com.google.android.play"
```

**Resultado esperado**: Deve mostrar apenas as novas bibliotecas modulares, não `play:core:1.10.3`

### 2. Build Local

Teste o build localmente:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### 3. Verificar no Play Console

Após fazer upload do AAB:

1. Acesse Google Play Console
2. Vá para a versão do app
3. Verifique a seção "Avisos" ou "Alertas"
4. Não deve haver avisos sobre Play Core

## Impacto no Código

### Nenhuma Mudança Necessária no Código Dart

As bibliotecas modulares são usadas internamente pelos plugins Flutter. Não é necessário alterar código Dart, pois:

- `in_app_purchase` - Gerencia suas próprias dependências
- `google_mobile_ads` - Gerencia suas próprias dependências

### Se Você Usar APIs Nativas (Kotlin/Java)

Se você tiver código nativo usando Play Core, precisará atualizar os imports:

❌ **Antes**:
```kotlin
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.review.ReviewManager
```

✅ **Depois**:
```kotlin
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.review.ReviewManager
// Os imports permanecem os mesmos, apenas a biblioteca mudou
```

## Plugins Flutter Afetados

Alguns plugins Flutter podem trazer a dependência antiga transitivamente:

### Plugins Comuns que Usavam Play Core

- `in_app_purchase` - Atualizado para usar novas bibliotecas
- `google_mobile_ads` - Atualizado para usar novas bibliotecas
- `app_review` - Pode precisar de atualização

### Como Verificar

```bash
cd android
./gradlew app:dependencies --configuration releaseRuntimeClasspath | grep play
```

## Troubleshooting

### Erro: "Duplicate class found"

Se você receber erro de classe duplicada:

```
Duplicate class com.google.android.play.core.XXX found in modules
```

**Solução**: Adicione exclusões específicas no `android/app/build.gradle`:

```gradle
dependencies {
    implementation('algum.plugin:versao') {
        exclude group: 'com.google.android.play', module: 'core'
    }
}
```

### Erro: "Could not resolve com.google.android.play:app-update"

**Causa**: Repositório Maven não configurado

**Solução**: Verifique que `google()` está nos repositórios:

```gradle
allprojects {
    repositories {
        google()  // ← Necessário
        mavenCentral()
    }
}
```

### Aviso no Play Console Persiste

Se o aviso persistir após o upload:

1. **Limpe o cache do Gradle**:
   ```bash
   cd android
   ./gradlew clean
   rm -rf ~/.gradle/caches/
   ```

2. **Reconstrua o AAB**:
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

3. **Verifique o AAB**:
   ```bash
   # Extrair o AAB
   unzip -l build/app/outputs/bundle/release/app-release.aab | grep play
   ```

4. **Aguarde**: O Play Console pode levar algumas horas para atualizar os avisos

## Referências

- [Google Play Core Library Migration Guide](https://developer.android.com/guide/playcore/migration)
- [In-app Updates API](https://developer.android.com/guide/playcore/in-app-updates)
- [In-app Reviews API](https://developer.android.com/guide/playcore/in-app-review)
- [Android 14 Behavior Changes](https://developer.android.com/about/versions/14/behavior-changes-14)

## Checklist de Migração

- [x] Removida dependência `com.google.android.play:core:1.10.3`
- [x] Adicionadas bibliotecas modulares (`app-update`, `review`)
- [x] Configurada estratégia de resolução para excluir biblioteca antiga
- [x] Testado build local
- [ ] Testado build no CodeMagic
- [ ] Upload para Play Console
- [ ] Verificado que não há avisos no Play Console

## Próximos Passos

1. Execute o build no CodeMagic
2. Faça upload do AAB para Play Console
3. Verifique que não há mais avisos sobre Play Core
4. Se houver avisos, aguarde algumas horas e verifique novamente
