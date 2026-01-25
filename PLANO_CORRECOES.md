# Plano de Correções - SyncLife App

## Problemas Identificados e Soluções

### 1. PROBLEMAS DE PERMISSÃO FIRESTORE
**Status**: ✅ Concluído
**Descrição**: Erros de "missing or insufficient permissions" em várias funcionalidades

#### Tarefas:
- [x] **1.1** Corrigir regras do Firestore para notificações
- [x] **1.2** Corrigir regras do Firestore para device tokens
- [x] **1.3** Corrigir regras do Firestore para criação de quadros
- [x] **1.4** Verificar e corrigir todas as regras de permissão

### 2. PROBLEMAS DE NAVEGAÇÃO E LAYOUT
**Status**: ✅ Concluído
**Descrição**: Botões de menu e navegação inconsistentes

#### Tarefas:
- [x] **2.1** Corrigir tela de notificações - duas versões diferentes
- [x] **2.2** Corrigir menu ausente no Dashboard
- [x] **2.3** Corrigir menu ausente na Loja FluxoCoins
- [x] **2.4** Padronizar uso do MainLayout em todas as telas

### 3. PROBLEMAS DE GLOBALKEY
**Status**: ✅ Concluído
**Descrição**: Multiple widgets usando a mesma GlobalKey

#### Tarefas:
- [x] **3.1** Identificar widgets com GlobalKey duplicadas
- [x] **3.2** Corrigir conflitos de GlobalKey no onboarding
- [x] **3.3** Implementar keys únicas para cada widget

### 4. PROBLEMAS DE ONBOARDING
**Status**: ✅ Concluído
**Descrição**: Onboarding aparece sempre que faz login

#### Tarefas:
- [x] **4.1** Implementar controle de primeiro acesso
- [x] **4.2** Criar sistema de skip onboarding
- [x] **4.3** Melhorar fluxo de onboarding inicial

### 5. DADOS MOCK vs FIREBASE
**Status**: ✅ Concluído
**Descrição**: Várias partes ainda usam dados mock

#### Tarefas:
- [x] **5.1** Substituir dados mock nas notificações
- [x] **5.2** Substituir dados mock no gamification
- [x] **5.3** Substituir dados mock nas recompensas
- [x] **5.4** Verificar todos os providers e services

### 6. FUNCIONALIDADE INBOX
**Status**: ✅ Concluído
**Descrição**: Conversão de inbox para tarefa não funciona

#### Tarefas:
- [x] **6.1** Implementar conversão de inbox para tarefa
- [x] **6.2** Integrar inbox com Firebase
- [x] **6.3** Criar dialog de conversão com opções

### 7. PROBLEMAS DE FIREBASE MESSAGING
**Status**: ✅ Concluído
**Descrição**: Service worker e messaging não funcionam na web

#### Tarefas:
- [x] **7.1** Criar firebase-messaging-sw.js
- [x] **7.2** Configurar service worker para web
- [x] **7.3** Implementar fallback para web messaging

### 8. MELHORIAS DE UX
**Status**: 🟡 Em Progresso
**Descrição**: Melhorias na experiência do usuário

#### Tarefas:
- [ ] **8.1** Criar questionário pós-cadastro
- [ ] **8.2** Implementar criação guiada do primeiro quadro
- [ ] **8.3** Implementar criação guiada da primeira tarefa
- [ ] **8.4** Melhorar feedback visual das ações

## Correções Implementadas

### ✅ Regras do Firestore Atualizadas
- Adicionadas regras para deviceTokens, notifications, notificationReactions
- Adicionadas regras para boardInvitations, boardActivities, userPresence
- Corrigidas permissões para todas as coleções

### ✅ GlobalKeys Corrigidas
- Removidas declarações duplicadas no onboarding_overlay.dart
- Cada GlobalKey agora é única

### ✅ Onboarding Melhorado
- Corrigida lógica para mostrar apenas quando não foi completado
- Sistema de controle de primeiro acesso funcionando

### ✅ Dados Mock Substituídos
- Leaderboard agora usa dados reais do Firebase
- Implementado método getLeaderboard no GamificationService
- Removidos dados hardcoded dos providers

### ✅ Conversão de Inbox para Tarefa
- Implementado dialog completo de conversão
- Integração com Firebase para criação de tarefas
- Remoção automática do item do inbox após conversão

### ✅ Firebase Messaging Web
- Criado service worker firebase-messaging-sw.js
- Configurado para notificações em background
- Implementado tratamento de cliques em notificações

## Próximos Passos
1. Implementar questionário pós-cadastro
2. Criar fluxo guiado para primeiro quadro e tarefa
3. Melhorar feedback visual das ações
4. Testar todas as funcionalidades corrigidas