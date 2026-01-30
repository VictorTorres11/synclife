import '../domain/models/models.dart';

/// Predefined catalog of store items for the FluxoCoins store
class StoreCatalog {
  static const List<StoreItem> defaultItems = [
    // ========== FUNCTIONAL ITEMS ==========
    
    // Board Management
    StoreItem(
      id: 'additional_board',
      name: 'Quadro Adicional',
      description: 'Desbloqueie um quadro extra para organizar mais projetos',
      category: StoreItemCategory.functional,
      price: 500,
      type: StoreItemType.upgrade,
      iconPath: 'assets/store/additional_board.png',
      isAvailable: true,
      metadata: {'maxPurchases': 5},
    ),
    
    StoreItem(
      id: 'premium_board_templates',
      name: 'Templates de Quadro Premium',
      description: 'Modelos profissionais para diferentes tipos de projeto',
      category: StoreItemCategory.functional,
      price: 350,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/board_templates.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'board_automation',
      name: 'Automação de Quadro',
      description: 'Automatize tarefas repetitivas com regras personalizadas',
      category: StoreItemCategory.functional,
      price: 800,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/automation.png',
      isAvailable: true,
    ),

    // Team & Collaboration
    StoreItem(
      id: 'group_member_slot',
      name: 'Slot de Membro',
      description: 'Adicione mais um membro aos seus quadros compartilhados',
      category: StoreItemCategory.functional,
      price: 300,
      type: StoreItemType.upgrade,
      iconPath: 'assets/store/group_member.png',
      isAvailable: true,
      metadata: {'maxPurchases': 10},
    ),

    StoreItem(
      id: 'team_analytics',
      name: 'Análises de Equipe',
      description: 'Relatórios detalhados de produtividade da equipe',
      category: StoreItemCategory.functional,
      price: 600,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/team_analytics.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'video_calls_integration',
      name: 'Integração de Videochamadas',
      description: 'Inicie reuniões diretamente das tarefas',
      category: StoreItemCategory.functional,
      price: 450,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/video_calls.png',
      isAvailable: true,
    ),

    // Task Management
    StoreItem(
      id: 'task_templates',
      name: 'Pacote de Templates',
      description: 'Templates prontos para rotinas comuns',
      category: StoreItemCategory.functional,
      price: 200,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/task_templates.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'advanced_recurring_tasks',
      name: 'Tarefas Recorrentes Avançadas',
      description: 'Padrões complexos de recorrência e dependências',
      category: StoreItemCategory.functional,
      price: 400,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/recurring_advanced.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'task_dependencies',
      name: 'Dependências de Tarefas',
      description: 'Crie fluxos de trabalho com tarefas dependentes',
      category: StoreItemCategory.functional,
      price: 550,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/dependencies.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'bulk_task_operations',
      name: 'Operações em Lote',
      description: 'Edite múltiplas tarefas simultaneamente',
      category: StoreItemCategory.functional,
      price: 300,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/bulk_operations.png',
      isAvailable: true,
    ),

    // Data & Export
    StoreItem(
      id: 'advanced_export',
      name: 'Exportação Avançada',
      description: 'Exporte dados em PDF, Excel e outros formatos',
      category: StoreItemCategory.functional,
      price: 250,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/export.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'calendar_sync_pro',
      name: 'Sincronização de Calendário Pro',
      description: 'Sincronize com Google, Outlook e Apple Calendar',
      category: StoreItemCategory.functional,
      price: 350,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/calendar_sync.png',
      isAvailable: true,
    ),

    // ========== VISUAL ITEMS ==========
    
    // Themes
    StoreItem(
      id: 'dark_theme_premium',
      name: 'Tema Escuro Premium',
      description: 'Tema escuro elegante com cores personalizadas',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/dark_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'nature_theme',
      name: 'Tema Natureza',
      description: 'Tema verde calmante inspirado na natureza',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/nature_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'ocean_theme',
      name: 'Tema Oceano',
      description: 'Tema azul relaxante com vibes do oceano',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/ocean_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'sunset_theme',
      name: 'Tema Pôr do Sol',
      description: 'Cores quentes de laranja e rosa do entardecer',
      category: StoreItemCategory.visual,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/sunset_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'cyberpunk_theme',
      name: 'Tema Cyberpunk',
      description: 'Tema futurista com neon e cores vibrantes',
      category: StoreItemCategory.visual,
      price: 200,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/cyberpunk_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'minimalist_theme',
      name: 'Tema Minimalista',
      description: 'Design limpo e minimalista para foco máximo',
      category: StoreItemCategory.visual,
      price: 120,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/minimalist_theme.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'seasonal_themes_pack',
      name: 'Pacote Temas Sazonais',
      description: 'Temas especiais para cada estação do ano',
      category: StoreItemCategory.visual,
      price: 300,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/seasonal_themes.png',
      isAvailable: true,
    ),

    // Sounds & Effects
    StoreItem(
      id: 'achievement_sounds_pack',
      name: 'Pacote de Sons de Conquista',
      description: 'Coleção de sons satisfatórios para conclusões',
      category: StoreItemCategory.visual,
      price: 100,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/sounds_pack.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'notification_sounds_premium',
      name: 'Sons de Notificação Premium',
      description: 'Sons únicos e personalizáveis para notificações',
      category: StoreItemCategory.visual,
      price: 80,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/notification_sounds.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'ambient_focus_sounds',
      name: 'Sons Ambientes para Foco',
      description: 'Ruído branco e sons da natureza para concentração',
      category: StoreItemCategory.visual,
      price: 120,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/ambient_sounds.png',
      isAvailable: true,
    ),

    // Customization
    StoreItem(
      id: 'avatar_icons_pack',
      name: 'Pacote de Ícones de Avatar',
      description: 'Ícones únicos para personalizar seu perfil',
      category: StoreItemCategory.visual,
      price: 75,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/avatar_pack.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'custom_task_icons',
      name: 'Ícones Personalizados de Tarefas',
      description: 'Centenas de ícones para categorizar suas tarefas',
      category: StoreItemCategory.visual,
      price: 90,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/task_icons.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'animated_backgrounds',
      name: 'Fundos Animados',
      description: 'Fundos sutilmente animados para uma experiência dinâmica',
      category: StoreItemCategory.visual,
      price: 180,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/animated_bg.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'custom_fonts_pack',
      name: 'Pacote de Fontes Personalizadas',
      description: 'Fontes exclusivas para personalizar a interface',
      category: StoreItemCategory.visual,
      price: 130,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/custom_fonts.png',
      isAvailable: true,
    ),

    // ========== UTILITY ITEMS ==========
    
    // Productivity Boosters
    StoreItem(
      id: 'streak_freeze',
      name: 'Congelamento de Sequência',
      description: 'Proteja sua sequência por um dia se perder tarefas',
      category: StoreItemCategory.utility,
      price: 50,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/streak_freeze.png',
      isAvailable: true,
      metadata: {'maxQuantity': 5},
    ),

    StoreItem(
      id: 'double_xp_boost',
      name: 'Impulso de XP Duplo',
      description: 'Ganhe XP duplo por 24 horas',
      category: StoreItemCategory.utility,
      price: 100,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/xp_boost.png',
      isAvailable: true,
      metadata: {'duration': '24h'},
    ),

    StoreItem(
      id: 'triple_fluxocoins_boost',
      name: 'Impulso Triplo de FluxoCoins',
      description: 'Ganhe 3x mais FluxoCoins por 12 horas',
      category: StoreItemCategory.utility,
      price: 150,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/fluxocoins_boost.png',
      isAvailable: true,
      metadata: {'duration': '12h'},
    ),

    StoreItem(
      id: 'productivity_multiplier',
      name: 'Multiplicador de Produtividade',
      description: 'Todas as recompensas aumentadas em 50% por 48h',
      category: StoreItemCategory.utility,
      price: 200,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/productivity_boost.png',
      isAvailable: true,
      metadata: {'duration': '48h'},
    ),

    // Time Management
    StoreItem(
      id: 'task_reminder_plus',
      name: 'Lembretes Plus',
      description: 'Sistema avançado de lembretes com notificações personalizadas',
      category: StoreItemCategory.utility,
      price: 250,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/reminder_plus.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'pomodoro_timer_pro',
      name: 'Timer Pomodoro Pro',
      description: 'Timer avançado com estatísticas e personalização',
      category: StoreItemCategory.utility,
      price: 180,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/pomodoro_pro.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'smart_scheduling',
      name: 'Agendamento Inteligente',
      description: 'IA que sugere os melhores horários para suas tarefas',
      category: StoreItemCategory.utility,
      price: 400,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/smart_schedule.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'deadline_guardian',
      name: 'Guardião de Prazos',
      description: 'Alertas inteligentes que se adaptam à urgência das tarefas',
      category: StoreItemCategory.utility,
      price: 220,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/deadline_guardian.png',
      isAvailable: true,
    ),

    // Analytics & Insights
    StoreItem(
      id: 'personal_analytics_pro',
      name: 'Análises Pessoais Pro',
      description: 'Relatórios detalhados de produtividade e hábitos',
      category: StoreItemCategory.utility,
      price: 300,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/analytics_pro.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'habit_tracker_advanced',
      name: 'Rastreador de Hábitos Avançado',
      description: 'Monitore e analise seus hábitos com gráficos detalhados',
      category: StoreItemCategory.utility,
      price: 280,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/habit_tracker.png',
      isAvailable: true,
    ),

    StoreItem(
      id: 'mood_productivity_tracker',
      name: 'Rastreador de Humor e Produtividade',
      description: 'Correlacione seu humor com sua produtividade',
      category: StoreItemCategory.utility,
      price: 200,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/mood_tracker.png',
      isAvailable: true,
    ),

    // Support & Services
    StoreItem(
      id: 'priority_support',
      name: 'Suporte Prioritário',
      description: 'Atendimento prioritário por 30 dias',
      category: StoreItemCategory.utility,
      price: 200,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/priority_support.png',
      isAvailable: true,
      metadata: {'duration': '30d'},
    ),

    StoreItem(
      id: 'personal_productivity_coach',
      name: 'Coach de Produtividade Pessoal',
      description: 'Consultoria personalizada para otimizar sua produtividade',
      category: StoreItemCategory.utility,
      price: 500,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/productivity_coach.png',
      isAvailable: true,
      metadata: {'duration': '7d'},
    ),

    StoreItem(
      id: 'data_backup_premium',
      name: 'Backup Premium de Dados',
      description: 'Backup automático e restauração de todos os seus dados',
      category: StoreItemCategory.utility,
      price: 150,
      type: StoreItemType.permanent,
      iconPath: 'assets/store/data_backup.png',
      isAvailable: true,
    ),

    // Special & Limited
    StoreItem(
      id: 'lucky_fluxocoins_box',
      name: 'Caixa Sortuda de FluxoCoins',
      description: 'Ganhe entre 50-500 FluxoCoins aleatoriamente!',
      category: StoreItemCategory.utility,
      price: 100,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/lucky_box.png',
      isAvailable: true,
      metadata: {'maxQuantity': 3, 'minReward': 50, 'maxReward': 500},
    ),

    StoreItem(
      id: 'mystery_productivity_pack',
      name: 'Pacote Mistério de Produtividade',
      description: 'Receba 3 itens aleatórios de utilidade!',
      category: StoreItemCategory.utility,
      price: 250,
      type: StoreItemType.consumable,
      iconPath: 'assets/store/mystery_pack.png',
      isAvailable: true,
      metadata: {'maxQuantity': 2},
    ),
  ];

  /// Gets items by category
  static List<StoreItem> getItemsByCategory(StoreItemCategory category) {
    return defaultItems.where((item) => item.category == category).toList();
  }

  /// Gets functional items (boards, members, etc.)
  static List<StoreItem> get functionalItems => 
      getItemsByCategory(StoreItemCategory.functional);

  /// Gets visual items (themes, sounds, avatars)
  static List<StoreItem> get visualItems => 
      getItemsByCategory(StoreItemCategory.visual);

  /// Gets utility items (streak freeze, boosts, etc.)
  static List<StoreItem> get utilityItems => 
      getItemsByCategory(StoreItemCategory.utility);

  /// Gets items by price range
  static List<StoreItem> getItemsByPriceRange(int minPrice, int maxPrice) {
    return defaultItems
        .where((item) => item.price >= minPrice && item.price <= maxPrice)
        .toList();
  }

  /// Gets affordable items for a given FluxoCoins balance
  static List<StoreItem> getAffordableItems(int fluxoCoinsBalance) {
    return defaultItems
        .where((item) => item.price <= fluxoCoinsBalance)
        .toList();
  }

  /// Gets premium/expensive items (above 300 FluxoCoins)
  static List<StoreItem> get premiumItems => 
      defaultItems.where((item) => item.price >= 300).toList();

  /// Gets budget items (below 150 FluxoCoins)
  static List<StoreItem> get budgetItems => 
      defaultItems.where((item) => item.price < 150).toList();
}