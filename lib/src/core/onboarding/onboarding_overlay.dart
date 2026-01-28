import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_components.dart';
import '../layout/safe_area_wrapper.dart';

/// Onboarding overlay that provides guided tour with contextual explanations
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  final List<OnboardingStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            child: Stack(
              children: [
                // Background tap to skip
                GestureDetector(
                  onTap: _skipOnboarding,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),

                // Highlight area (if specified)
                if (step.targetKey != null) _buildHighlight(step.targetKey!),

                // Tooltip/Explanation
                _buildTooltip(step),

                // Navigation controls
                _buildNavigationControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlight(GlobalKey targetKey) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final RenderBox? renderBox =
            targetKey.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox == null) {
          return const SizedBox.shrink();
        }

        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        return Positioned(
          left: position.dx - 8,
          top: position.dy - 8,
          child: Container(
            width: size.width + 16,
            height: size.height + 16,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTooltip(OnboardingStep step) {
    return Positioned(
      left: AppTheme.spacingMd,
      right: AppTheme.spacingMd,
      bottom: 120 + context.bottomSafeArea, // Add safe area padding
      child: AppComponents.card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacing2xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '${_currentStep + 1}/${widget.steps.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (step.icon != null)
                  Icon(
                    step.icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Title
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Description
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutralGray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Positioned(
      left: AppTheme.spacingMd,
      right: AppTheme.spacingMd,
      bottom:
          AppTheme.spacingMd + context.bottomSafeArea, // Add safe area padding
      child: Row(
        children: [
          // Skip button
          AppComponents.textButton(
            text: 'Pular',
            onPressed: _skipOnboarding,
          ),

          const Spacer(),

          // Previous button
          if (_currentStep > 0)
            AppComponents.secondaryButton(
              text: 'Anterior',
              onPressed: _previousStep,
            ),

          if (_currentStep > 0) const SizedBox(width: AppTheme.spacingSm),

          // Next/Finish button
          AppComponents.primaryButton(
            text: _currentStep == widget.steps.length - 1
                ? 'Finalizar'
                : 'Próximo',
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _skipOnboarding() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    _animationController.reverse().then((_) {
      widget.onComplete();
    });
  }
}

/// Represents a single step in the onboarding process
class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.icon,
  });

  final String title;
  final String description;
  final GlobalKey? targetKey;
  final IconData? icon;
}

/// Predefined onboarding steps for SyncLife
class SyncLifeOnboardingSteps {
  // Global keys for targeting specific UI elements
  static final GlobalKey menuButtonKey = GlobalKey();
  static final GlobalKey addTaskButtonKey = GlobalKey();
  static final GlobalKey taskListKey = GlobalKey();
  static final GlobalKey inboxTabKey = GlobalKey();
  static final GlobalKey notificationButtonKey = GlobalKey();
  static final GlobalKey syncStatusKey = GlobalKey();

  static List<OnboardingStep> get defaultSteps => [
        const OnboardingStep(
          title: 'Bem-vindo ao SyncLife!',
          description: 'Transforme sua rotina em um jogo cooperativo. '
              'Organize tarefas, colabore com outros e ganhe recompensas por completar suas atividades diárias.',
          icon: Icons.celebration,
        ),
        OnboardingStep(
          title: 'Menu Principal',
          description:
              'Toque neste ícone para acessar todas as funcionalidades: '
              'suas tarefas, quadros compartilhados, gamificação e configurações.',
          targetKey: menuButtonKey,
          icon: Icons.menu,
        ),
        OnboardingStep(
          title: 'Notificações',
          description: 'Aqui você vê suas notificações e atividades da equipe. '
              'O número indica quantas notificações não lidas você tem.',
          targetKey: notificationButtonKey,
          icon: Icons.notifications,
        ),
        OnboardingStep(
          title: 'Status de Sincronização',
          description:
              'Este indicador mostra o status da sincronização dos seus dados. '
              'Verde significa que tudo está sincronizado, amarelo indica sincronização em andamento.',
          targetKey: syncStatusKey,
          icon: Icons.sync,
        ),
        OnboardingStep(
          title: 'Criar Nova Tarefa',
          description: 'Use este botão para criar novas tarefas rapidamente. '
              'Você pode definir recorrência, datas e categorias.',
          targetKey: addTaskButtonKey,
          icon: Icons.add_task,
        ),
        OnboardingStep(
          title: 'Suas Tarefas',
          description: 'Aqui estão todas as suas tarefas organizadas por data. '
              'Deslize para a direita para marcar como concluída (✓), '
              'ou para a esquerda para adiar para o próximo período.',
          targetKey: taskListKey,
          icon: Icons.task_alt,
        ),
        OnboardingStep(
          title: 'Inbox Rápido',
          description:
              'Use a aba Inbox para anotar ideias e pensamentos rapidamente. '
              'Depois, arraste os itens para uma data específica para transformá-los em tarefas.',
          targetKey: inboxTabKey,
          icon: Icons.inbox,
        ),
        const OnboardingStep(
          title: 'Sistema de Gamificação',
          description: 'Complete tarefas para ganhar XP e FluxoCoins! '
              'Mantenha streaks diários, desbloqueie conquistas e troque moedas por benefícios na loja.',
          icon: Icons.emoji_events,
        ),
        const OnboardingStep(
          title: 'Colaboração em Equipe',
          description:
              'Crie quadros compartilhados e convide amigos, família ou colegas. '
              'Trabalhem juntos para manter streaks coletivos e se motivarem mutuamente.',
          icon: Icons.group,
        ),
        const OnboardingStep(
          title: 'Pronto para começar!',
          description: 'Agora você está pronto para transformar sua rotina! '
              'Comece criando sua primeira tarefa e descubra como o SyncLife pode tornar sua vida mais organizada e divertida.',
          icon: Icons.rocket_launch,
        ),
      ];

  /// Contextual onboarding for specific features
  static List<OnboardingStep> get taskManagementSteps => [
        const OnboardingStep(
          title: 'Gestos de Tarefa',
          description: 'Deslize para a direita para completar uma tarefa, '
              'ou para a esquerda para adiá-la. Toque para ver detalhes.',
          icon: Icons.swipe,
        ),
        const OnboardingStep(
          title: 'Filtros e Categorias',
          description: 'Use os filtros para ver apenas tarefas pendentes, '
              'concluídas, atrasadas ou de categorias específicas.',
          icon: Icons.filter_list,
        ),
      ];

  static List<OnboardingStep> get gamificationSteps => [
        const OnboardingStep(
          title: 'Sistema de XP',
          description: 'Ganhe pontos de experiência completando tarefas. '
              'Diferentes categorias (Saúde, Trabalho, Casa) têm valores diferentes.',
          icon: Icons.trending_up,
        ),
        const OnboardingStep(
          title: 'Streaks e Conquistas',
          description: 'Mantenha sequências diárias para ganhar bônus. '
              'Desbloqueie conquistas especiais por marcos importantes.',
          icon: Icons.local_fire_department,
        ),
        const OnboardingStep(
          title: 'Loja FluxoCoins',
          description: 'Use suas moedas virtuais para comprar temas, '
              'proteção de streak, quadros extras e outras funcionalidades.',
          icon: Icons.store,
        ),
      ];

  static List<OnboardingStep> get boardCollaborationSteps => [
        const OnboardingStep(
          title: 'Criando Quadros',
          description:
              'Crie quadros privados para organizar suas tarefas pessoais '
              'ou compartilhados para colaborar com outros.',
          icon: Icons.dashboard,
        ),
        const OnboardingStep(
          title: 'Convites e Colaboração',
          description:
              'Gere links de convite únicos ou busque usuários por email '
              'para adicionar membros aos seus quadros.',
          icon: Icons.person_add,
        ),
        const OnboardingStep(
          title: 'Atividade em Tempo Real',
          description: 'Veja quando outros membros estão online e '
              'acompanhe as atividades do quadro em tempo real.',
          icon: Icons.visibility,
        ),
      ];

  static List<OnboardingStep> get notificationSteps => [
        const OnboardingStep(
          title: 'Resumo Matinal',
          description: 'Receba um resumo personalizado das suas tarefas '
              'do dia logo pela manhã.',
          icon: Icons.wb_sunny,
        ),
        const OnboardingStep(
          title: 'Atividade da Equipe',
          description: 'Seja notificado quando membros da sua equipe '
              'completarem tarefas ou precisarem de ajuda.',
          icon: Icons.group_work,
        ),
        const OnboardingStep(
          title: 'Reações Rápidas',
          description: 'Use emojis para reagir rapidamente às notificações '
              'e manter a comunicação fluida com sua equipe.',
          icon: Icons.emoji_emotions,
        ),
      ];

  static List<OnboardingStep> get storeSteps => [
        const OnboardingStep(
          title: 'Ganhando FluxoCoins',
          description: 'Complete tarefas, mantenha streaks e convide amigos '
              'para ganhar moedas virtuais.',
          icon: Icons.monetization_on,
        ),
        const OnboardingStep(
          title: 'Itens Funcionais',
          description: 'Compre quadros extras, aumente o limite de membros '
              'ou desbloqueie funcionalidades premium.',
          icon: Icons.extension,
        ),
        const OnboardingStep(
          title: 'Personalização',
          description: 'Adquira temas exclusivos, ícones de avatar '
              'e sons de conquista personalizados.',
          icon: Icons.palette,
        ),
      ];
}
