# 📘 Documento de Visão do Produto (PRD) - SyncLife

## 1. Visão Geral do Produto
**Nome:** SyncLife
**Conceito:** Um aplicativo de tarefas colaborativo que transforma a organização da rotina em um "jogo cooperativo". Focado em casais, amigos e grupos que desejam harmonia e menos cobranças.
**Plataformas:** Android, iOS e Web (Site).
**Diferencial:** Gamificação profunda (RPG da vida real) e sistema de recompensas para usuários gratuitos fiéis.

---

## 2. Experiência do Usuário (UI/UX) e Design

### Identidade Visual
* **Estilo:** Minimalista (*Clean*), com foco em espaços em branco para reduzir ansiedade.
* **Menu "Escondido":** Não haverá botão de menu tradicional. No canto superior esquerdo, haverá um **símbolo estilizado**. Ao clicar, o menu lateral desliza.
* **Temas:** Suporte nativo a **Modo Claro** e **Modo Escuro**.
    * *Automático:* Segue o sistema do celular.
    * *Manual:* Configurável pelo usuário.
* **Onboarding (Tour):** No primeiro acesso, o fundo escurece e balões de diálogo explicam os elementos principais (Menu, Lista do Dia, Botão Adicionar).

### Localização e Idioma
* **Detecção Automática:** O app identifica a região/GPS do usuário para configurar idioma e fuso horário.
* **Ajuste Manual:** Opção nas configurações para alterar o idioma, independente da região.

---

## 3. Funcionalidades Principais

### A. Gestão de Tarefas
* **Categorias de Recorrência:**
    * Diárias, Semanais, Mensais.
    * Ocasionais (data específica).
    * **Inbox (Bloco de Notas):** Área para anotar ideias rápidas sem data definida, que podem ser convertidas em tarefas depois.
* **Interação:** Gestos de deslizar (*swipe*) para concluir ou adiar.

### B. Quadros (Workspaces)
* **Quadro Privado:** Visível apenas para o usuário.
* **Quadros Compartilhados:** Espaços colaborativos (ex: "Casa", "Viagem", "Trabalho").
    * **Chat por Tarefa:** Campo de comentários dentro de cada tarefa.
    * **Atribuição:** Definir quem é o responsável ou se é "Livre".
* **Segurança:** Possibilidade de tarefas "Ocultas/Surpresa" dentro de quadros compartilhados.

### C. Sistema de Convites
* **Métodos:**
    * **Link de Convite:** Gera uma URL única. Se o convidado não tiver o app, leva à loja.
    * **Busca Interna:** Convidar usuários que já possuem conta através de ID ou E-mail.
* **Bônus:** O usuário que convida ganha recompensas (Moedas/XP). Se o convidado for novo, o bônus é validado após ele completar 5 tarefas (anti-fraude).

---

## 4. Gamificação e Economia (O Motor do App)

### Streaks (Sequências)
* **Streak Individual:** Dias seguidos cumprindo metas pessoais.
* **Streak Coletivo (O Diferencial):** Só avança se **todos** os membros do quadro compartilhado cumprirem suas tarefas essenciais. Incentiva a cobrança positiva e ajuda mútua.

### XP e Níveis (Processamento Diário)
* **Regra de Ouro:** O XP e as Moedas **NÃO** são somados instantaneamente.
* **Fechamento do Dia:** O processamento ocorre via servidor à meia-noite (ou horário definido pelo usuário).
    * Isso evita processamento desnecessário se o usuário marcar/desmarcar tarefas várias vezes.
    * Cria um evento de "Resumo do Dia".

### Loja de Regalias (FluxoCoins)
* Usuários ganham moedas por consistência.
* **Itens da Loja:**
    * **Funcionais:** Desbloquear +1 Quadro, +1 Membro no grupo (para usuários Free).
    * **Visuais:** Temas, Ícones de Avatar, Sons de Conquista.
    * **Utilitários:** "Congelar Streak" (proteção contra falha de um dia).

### Feedback Sensorial
* **Auditivo:** Som de "Conquista" (estilo videogame) ao concluir tarefas.
* **Visual:** Animação de confetes ou brilho na tela.

---

## 5. Notificações e Comunicação
* **Resumo Matinal:** Push notification com o planejado para o dia.
* **Avisos de Conclusão:** "Fulano completou a tarefa X".
* **Resumo Noturno:** Relatório de desempenho e atualização do Streak.
* **Reações:** Permitir enviar emojis rápidos via notificação.

---

## 6. Modelo de Negócio (Monetização)

### Plano Free (Básico)
* Limite de tarefas ativas e número de quadros.
* Anúncios discretos.
* **Sistema de Fidelidade:** Pode desbloquear recursos Premium temporários ou permanentes usando a Loja de Regalias (engajamento).

### Plano Premium (Assinatura)
* Tudo ilimitado (Quadros, Membros).
* Backup avançado e histórico completo.
* Sem anúncios.
* Integração com calendários externos.
* Temas exclusivos.

---

## 7. Requisitos Técnicos
* **Sincronização:** Tempo real (Websocket/Database Realtime).
* **Offline First:** Permite criar/editar sem internet; sincroniza ao reconectar.
* **Backend:** Lógica robusta para processamento em lote (Batch) à meia-noite.


1. Regra Estrita de Bônus por Convite (Growth Hacking)

Para evitar fraudes e focar no crescimento real da base de usuários.

    Convite para Usuário Existente: Se eu convido alguém que já tem conta no SyncLife (via busca ou link), a conexão é feita, mas NÃO há geração de bônus. O benefício é apenas a funcionalidade de compartilhar.

    Convite para Novo Usuário: O bônus (Moedas/XP) é gerado APENAS quando o convite resulta em um novo cadastro (New Sign-up).

        Validação: O bônus fica "Pendente" e só é liberado para o convidador após o novo usuário completar suas primeiras 5 tarefas (evita criação de contas falsas apenas para farmar moedas).

2. Lógica de "Desmarcar" Tarefa (Undo)

Conforme definido para economizar banco de dados e evitar frustração.

    Cenário: O usuário marca uma tarefa como concluída (ouve o som, vê o confete), mas percebe que errou e desmarca 10 minutos depois.

    Ação do Sistema:

        Visualmente: A tarefa volta a ficar pendente.

        XP/Moedas: O sistema não faz nada no banco de dados de saldo. Como o processamento do XP só ocorre à meia-noite, não precisamos "tirar" pontos que tecnicamente ainda não foram creditados na conta final. Isso simplifica drasticamente a programação e o uso de servidor.

3. Categorização de XP (O Toque RPG)

Para incentivar diversidade nas tarefas.

    As tarefas podem ter "Tags de Categoria" (Saúde, Casa, Finanças, Trabalho).

    Ao processar o dia, o app mostra não só o XP total, mas a evolução nas áreas: "Hoje você foi um Mestre da Saúde (+50XP) e Líder do Lar (+30XP)".

4. Mecânica do Inbox (Drag-and-Drop)

    Para facilitar o fluxo de "lembrei agora, faço depois":

    O usuário deve poder arrastar um item da lista "Inbox" e soltá-lo sobre uma data no calendário ou na lista "Hoje", transformando a nota automaticamente em uma tarefa agendada.