# Dashboard Feature

Esta feature implementa a tela principal (dashboard/home) do SyncLife que é exibida após o usuário fazer login.

## Estrutura

### Screens
- `HomeDashboardScreen`: Tela principal com visão geral do app

### Widgets
- `DashboardCard`: Card reutilizável para navegação entre features
- `QuickStatsWidget`: Widget que exibe estatísticas rápidas do usuário
- `RecentActivityWidget`: Widget que mostra atividades recentes

## Funcionalidades

### Tela Principal (HomeDashboardScreen)
- **Mensagem de boas-vindas personalizada** com o nome do usuário
- **Estatísticas rápidas** mostrando FluxoCoins, sequência, XP total e nível
- **Cards de navegação** para as principais features:
  - Minhas Tarefas
  - Quadros
  - Gamificação
  - Loja FluxoCoins
- **Atividade recente** (mockada por enquanto)
- **Ações rápidas** para funcionalidades comuns

### Design
- **Interface moderna** com cards em gradiente
- **Cores temáticas** para cada feature
- **Layout responsivo** com grid de cards
- **Animações suaves** com InkWell
- **Badges opcionais** nos cards para notificações

## Navegação

Após o login, o usuário é redirecionado para `/home` em vez de `/tasks`, proporcionando uma experiência mais rica e intuitiva.

## Integração

A tela integra com:
- **Auth providers** para informações do usuário
- **Gamification providers** para estatísticas
- **Go Router** para navegação entre telas

## Futuras Melhorias

- [ ] Conectar atividade recente com dados reais
- [ ] Adicionar widgets personalizáveis
- [ ] Implementar notificações nos badges
- [ ] Adicionar gráficos de progresso
- [ ] Suporte a temas personalizados