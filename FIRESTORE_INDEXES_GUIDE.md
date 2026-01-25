# Guia de Índices do Firestore - SyncLife App

## Problema
Você está vendo uma opção para criar índices no Firestore mas não consegue clicar nela. Isso acontece porque o Firestore precisa de índices compostos para consultas que combinam `where()` e `orderBy()`.

## Solução

### 1. Índices Automáticos via Arquivo
Já criei o arquivo `firestore.indexes.json` com todos os índices necessários. Para implantá-los:

```bash
# Opção 1: Comando direto
firebase deploy --only firestore:indexes

# Opção 2: Script automatizado
scripts/deploy_indexes.bat
```

### 2. Índices Criados

Os seguintes índices foram configurados para resolver os problemas:

#### Notificações
- `userId` + `createdAt` (descendente)
- `userId` + `isRead`

#### Tarefas
- `boardId` + `createdAt` (descendente)
- `assignedTo` + `createdAt` (descendente)
- `tags` (array) + `createdAt` (descendente)
- `dueDate` + `dueDate` (para consultas de intervalo)

#### Quadros
- `memberIds` (array) + `createdAt` (descendente)

#### Convites de Quadro
- `boardId` + `createdAt` (descendente)
- `inviterId` + `createdAt` (descendente)
- `inviteeEmail` + `createdAt` (descendente)
- `boardId` + `status` + `createdAt` (descendente)

#### Atividades do Quadro
- `boardId` + `timestamp` (descendente)
- `boardId` + `userId` + `timestamp` (descendente)

#### Inbox
- `userId` + `createdAt` (descendente)

#### Loja
- `isAvailable` + `category` + `price`
- `category` + `isAvailable` + `price`

#### Compras
- `userId` + `purchaseDate` (descendente)

#### Convites/Referências
- `inviterId` + `createdAt` (descendente)
- `inviteeEmail` + `createdAt` (descendente)

#### Reações de Notificação
- `notificationId` + `createdAt` (descendente)

#### Integrações de Calendário
- `userId` + `createdAt` (descendente)

#### Tokens de Dispositivo
- `isActive` + `lastUpdated`

### 3. Verificação

Após a implantação, você pode verificar os índices:

1. Acesse o [Console do Firebase](https://console.firebase.google.com)
2. Vá para seu projeto `synclife-e3763`
3. Navegue para **Firestore Database** > **Indexes**
4. Verifique se todos os índices estão listados e com status "Enabled"

### 4. Tempo de Criação

- Índices simples: 1-5 minutos
- Índices complexos: 5-15 minutos
- Grandes volumes de dados: pode levar mais tempo

### 5. Monitoramento

Durante a criação dos índices, você pode ver o progresso no console do Firebase. Os índices aparecerão com status:
- **Building**: Sendo criados
- **Enabled**: Prontos para uso
- **Error**: Problema na criação

## Comandos Úteis

```bash
# Verificar status dos índices
firebase firestore:indexes

# Implantar apenas índices
firebase deploy --only firestore:indexes

# Implantar regras e índices
firebase deploy --only firestore

# Ver logs de implantação
firebase functions:log
```

## Resolução de Problemas

### Se os índices não aparecerem:
1. Verifique se você está logado no Firebase: `firebase login`
2. Confirme o projeto: `firebase use synclife-e3763`
3. Verifique permissões no console do Firebase

### Se houver erros de implantação:
1. Verifique a sintaxe do `firestore.indexes.json`
2. Confirme que o projeto existe e está ativo
3. Verifique se a API do Firestore está habilitada

### Se ainda não conseguir clicar:
1. Aguarde a conclusão da implantação dos índices
2. Recarregue a página do app
3. Verifique o console do navegador para erros

## Próximos Passos

Após a implantação dos índices:
1. ✅ Teste as funcionalidades que estavam com problema
2. ✅ Verifique se as consultas estão funcionando
3. ✅ Monitore o desempenho das consultas
4. ✅ Adicione novos índices conforme necessário

Os índices são essenciais para o desempenho do Firestore e devem resolver completamente o problema que você está enfrentando.