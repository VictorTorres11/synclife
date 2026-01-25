# 🛠️ Roadmap de Desenvolvimento: SyncLife

## 📅 FASE 1: Fundação e Design (Mês 1)
*Objetivo: Definir a "cara" e a estrutura técnica do projeto.*

* **[Tarefa 1.1] Identidade Visual & Branding**
    * [ ] Criar logo e ícone do app ("Menino Escondido" - Line Art minimalista).
    * [ ] Definir Paleta de Cores:
        * Fundo Claro: `#F8F9FA` | Fundo Escuro: `#1A1A1B`
        * Ação/Sucesso: `#4ECCA3` (Verde Menta)
    * [ ] Escolher tipografia (Sugestão: Inter ou Roboto).
* **[Tarefa 1.2] Prototipagem (UI/UX)**
    * [ ] Desenhar tela "Meu Dia" (Dashboard).
    * [ ] Desenhar Menu Lateral Oculto (Drawer).
    * [ ] Desenhar Fluxo de Onboarding (Telas com balões de explicação).
* **[Tarefa 1.3] Definição Técnica**
    * [ ] Configurar ambiente de desenvolvimento (Sugestão: Flutter para Mobile, React para Web).
    * [ ] Configurar Banco de Dados (Sugestão: Firebase Firestore).
    * [ ] Estruturar regras de segurança do banco (Privado vs. Público).

## 💻 FASE 2: Desenvolvimento do MVP (Mês 2)
*Objetivo: Ter um app funcional de lista de tarefas compartilhada.*

* **[Tarefa 2.1] Autenticação e Perfil**
    * [ ] Login Social (Google/Apple) e E-mail.
    * [ ] Detecção automática de região/idioma no cadastro.
* **[Tarefa 2.2] Motor de Tarefas (Core)**
    * [ ] CRUD de Tarefas (Criar, Ler, Atualizar, Deletar).
    * [ ] Lógica de recorrência (Diário, Semanal, Mensal).
    * [ ] Implementar "Inbox" (Bloco de Notas).
* **[Tarefa 2.3] Quadros e Colaboração**
    * [ ] Sistema de convite via Link (Deep Linking).
    * [ ] Sistema de busca de usuário por ID.
    * [ ] Separação de visualização por quadros.
    * [ ] Sincronização em tempo real entre dispositivos.

## 🎮 FASE 3: Gamificação e Lógica de Negócio (Mês 3)
*Objetivo: Implementar o diferencial do app.*

* **[Tarefa 3.1] Sistema de Processamento (Backend)**
    * [ ] Criar script (Cloud Function) para rodar à meia-noite.
    * [ ] Lógica: Validar tarefas feitas -> Calcular XP -> Atualizar Streak -> Creditar Moedas.
* **[Tarefa 3.2] Feedback e Sons**
    * [ ] Integrar som de "Conquista" (.wav) ao marcar tarefa.
    * [ ] Implementar animação visual de conclusão.
* **[Tarefa 3.3] Loja de Regalias (Frontend)**
    * [ ] Criar layout da loja.
    * [ ] Implementar lógica de compra (diminuir saldo de moedas -> liberar recurso).

## 🚀 FASE 4: Refinamento e Monetização (Mês 4)
*Objetivo: Preparar para o mercado.*

* **[Tarefa 4.1] Assinaturas e Pagamentos**
    * [ ] Configurar In-App Purchases (iOS/Android).
    * [ ] Criar lógica de verificação (Free vs Premium).
* **[Tarefa 4.2] Notificações Push**
    * [ ] Agendar Resumo Matinal (Local Time).
    * [ ] Agendar Resumo Noturno (Pós-fechamento).
    * [ ] Gatilhos de conclusão de tarefa por terceiros.
* **[Tarefa 4.3] Versão Web**
    * [ ] Adaptar layout para Desktop/Navegador.
    * [ ] Garantir sincronia com o mobile.

## 🏁 FASE 5: Lançamento e Marketing (Mês 5)
*Objetivo: Testar e divulgar.*

* **[Tarefa 5.1] Beta Test (Bug Hunting)**
    * [ ] Liberar para grupo fechado.
    * [ ] Testar "Convite com Bônus" (verificar se crédito cai corretamente).
* **[Tarefa 5.2] Materiais de Loja (ASO)**
    * [ ] Criar Screenshots e Ícone final.
    * [ ] Escrever descrições focadas em palavras-chave (Casais, Organização).
* **[Tarefa 5.3] Criativos de Marketing**
    * [ ] Produzir vídeo "Expectativa vs Realidade".
    * [ ] Produzir vídeo "O Menino Escondido".
* **[Tarefa 5.4] Publicação**
    * [ ] Submissão na Apple App Store e Google Play Store.