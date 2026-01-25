# Correção do Erro SQLite na Web - SyncLife App

## Problema Identificado

**Erro**: `databaseFactory not initialized` ao tentar usar SQLite no navegador web.

```
Failed to get tasks: Bad state: databaseFactory not initialized
databaseFactory is only initialized when using sqflite. When using `sqflite_common_ffi`
You must call `databaseFactory = databaseFactoryFfi;` before using global openDatabase API
```

## Causa Raiz

O app estava tentando usar o `OfflineTaskService` que depende do SQLite local em **todas as plataformas**, incluindo web. No entanto:

- **SQLite não funciona nativamente no navegador web**
- O `sqflite` é específico para mobile (Android/iOS)
- Para web, seria necessário usar `sqflite_common_ffi` com configuração específica

## Solução Implementada

### ✅ **Detecção de Plataforma nos Providers**

Modificado `lib/src/core/sync/providers/sync_providers.dart` para usar serviços diferentes baseados na plataforma:

```dart
import 'package:flutter/foundation.dart'; // ← ADICIONADO

/// Provider for offline-first task service
final offlineTaskServiceProvider = Provider<TaskService>((ref) {
  final remoteTaskService = ref.read(remoteTaskServiceProvider);
  
  // For web platform, use Firebase service directly (no local database)
  if (kIsWeb) {
    return remoteTaskService;  // ← USA FIREBASE DIRETAMENTE NA WEB
  }
  
  // For mobile platforms, use offline-first service
  final localDatabase = ref.read(localDatabaseServiceProvider);
  final syncService = ref.read(syncServiceProvider);

  return OfflineTaskService(
    remoteTaskService: remoteTaskService,
    localDatabase: localDatabase,
    syncService: syncService,
  );
});
```

### ✅ **Inicialização Condicional do Sync**

```dart
/// Provider for initializing sync services
final syncInitializationProvider = FutureProvider<void>((ref) async {
  // For web platform, skip sync service initialization (no local database)
  if (kIsWeb) {
    return;  // ← PULA INICIALIZAÇÃO NA WEB
  }
  
  // For mobile platforms, initialize sync service
  final syncService = ref.read(syncServiceProvider);
  await syncService.initialize();
});
```

## Comportamento por Plataforma

### 🌐 **Web (Chrome/Firefox/Safari)**
- **Task Service**: `FirebaseTaskService` (direto, sem cache local)
- **Sync Service**: Desabilitado (não inicializado)
- **Banco Local**: Não usado
- **Funcionalidade**: Online-only, dados sempre do Firestore

### 📱 **Mobile (Android/iOS)**
- **Task Service**: `OfflineTaskService` (com cache SQLite local)
- **Sync Service**: Habilitado e inicializado
- **Banco Local**: SQLite via `sqflite`
- **Funcionalidade**: Offline-first, sincronização automática

## Vantagens da Solução

### ✅ **Compatibilidade Total**
- Web funciona sem SQLite
- Mobile mantém funcionalidade offline
- Mesmo código base para ambas plataformas

### ✅ **Performance Otimizada**
- Web: Acesso direto ao Firestore (mais rápido)
- Mobile: Cache local para uso offline

### ✅ **Manutenibilidade**
- Lógica centralizada nos providers
- Fácil de modificar comportamento por plataforma
- Não quebra funcionalidades existentes

## Arquivos Modificados

- ✅ `lib/src/core/sync/providers/sync_providers.dart`
  - Adicionado import `package:flutter/foundation.dart`
  - Modificado `offlineTaskServiceProvider` com detecção de plataforma
  - Modificado `syncInitializationProvider` para pular web

## Teste da Correção

### 🧪 **Como Testar**

1. **Web**: Acessar tarefas deve funcionar sem erro SQLite
2. **Mobile**: Funcionalidade offline deve continuar funcionando
3. **Ambos**: Criar/editar/deletar tarefas deve funcionar

### 📊 **Resultados Esperados**

- ❌ **Antes**: Erro SQLite na web, app não carrega tarefas
- ✅ **Depois**: Web funciona com Firebase direto, mobile mantém offline

## Próximos Passos

1. **Testar funcionalidade de tarefas** na web
2. **Verificar se não há outros erros** no console
3. **Confirmar que mobile ainda funciona** (quando testado)

---

## Status

✅ **CORREÇÃO APLICADA** - App deve funcionar na web sem erros SQLite

O erro `databaseFactory not initialized` foi resolvido usando Firebase diretamente na web e mantendo SQLite apenas no mobile.