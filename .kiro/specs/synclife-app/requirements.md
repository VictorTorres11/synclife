# Requirements Document - SyncLife

## Introduction

SyncLife é um aplicativo de tarefas colaborativo que transforma a organização da rotina em um "jogo cooperativo". Focado em casais, amigos e grupos que desejam harmonia e menos cobranças através de gamificação profunda (RPG da vida real) e sistema de recompensas.

## Glossary

- **SyncLife_System**: O aplicativo completo incluindo mobile, web e backend
- **User**: Pessoa que utiliza o aplicativo
- **Task**: Atividade que pode ser marcada como concluída
- **Board**: Espaço de trabalho que pode ser privado ou compartilhado
- **Streak**: Sequência de dias consecutivos cumprindo metas
- **XP**: Pontos de experiência ganhos por completar tarefas
- **FluxoCoins**: Moeda virtual do sistema para compras na loja
- **Inbox**: Área para anotações rápidas sem data definida
- **Daily_Processing**: Processamento automático que ocorre à meia-noite

## Requirements

### Requirement 1: User Authentication and Profile Management

**User Story:** As a user, I want to create and manage my account, so that I can access my tasks and collaborate with others.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time, THE SyncLife_System SHALL provide social login options (Google/Apple) and email registration
2. WHEN a user registers, THE SyncLife_System SHALL automatically detect their region and timezone based on GPS location
3. WHEN a user completes registration, THE SyncLife_System SHALL create a default private board for them
4. THE SyncLife_System SHALL allow users to manually change language settings regardless of detected region
5. WHEN a user logs in, THE SyncLife_System SHALL synchronize their data across all devices

### Requirement 2: Task Management Core

**User Story:** As a user, I want to create and manage tasks with different recurrence patterns, so that I can organize my routine effectively.

#### Acceptance Criteria

1. WHEN a user creates a task, THE SyncLife_System SHALL allow setting recurrence as daily, weekly, monthly, or specific date
2. WHEN a user swipes right on a task, THE SyncLife_System SHALL mark it as completed
3. WHEN a user swipes left on a task, THE SyncLife_System SHALL postpone it to the next occurrence
4. THE SyncLife_System SHALL provide an Inbox area for quick notes without defined dates
5. WHEN a user drags an item from Inbox to a date, THE SyncLife_System SHALL convert it to a scheduled task
6. WHEN a user marks a task as complete, THE SyncLife_System SHALL play a success sound and show visual feedback

### Requirement 3: Board and Collaboration System

**User Story:** As a user, I want to create shared boards and invite others, so that we can collaborate on tasks and maintain accountability.

#### Acceptance Criteria

1. THE SyncLife_System SHALL allow users to create private boards visible only to themselves
2. THE SyncLife_System SHALL allow users to create shared boards for collaboration
3. WHEN a user creates an invite link, THE SyncLife_System SHALL generate a unique URL that opens the app or app store
4. WHEN a user searches for another user by ID or email, THE SyncLife_System SHALL allow sending direct invitations
5. WHEN a user joins a shared board, THE SyncLife_System SHALL enable real-time synchronization of tasks and updates
6. THE SyncLife_System SHALL allow tasks to be assigned to specific users or marked as "free for anyone"
7. THE SyncLife_System SHALL provide a comment system within each task for communication

### Requirement 4: Gamification and XP System

**User Story:** As a user, I want to earn XP and maintain streaks, so that I stay motivated to complete my tasks consistently.

#### Acceptance Criteria

1. WHEN Daily_Processing runs at midnight, THE SyncLife_System SHALL calculate XP based on completed tasks
2. WHEN Daily_Processing runs, THE SyncLife_System SHALL update individual streaks for users who completed their essential tasks
3. WHEN Daily_Processing runs for shared boards, THE SyncLife_System SHALL update collective streaks only if ALL members completed their essential tasks
4. THE SyncLife_System SHALL categorize XP by task tags (Health, Home, Finance, Work) and show progress in each area
5. WHEN a user completes tasks consistently, THE SyncLife_System SHALL award FluxoCoins based on performance
6. IF a user marks and unmarks a task before Daily_Processing, THE SyncLife_System SHALL not process intermediate state changes

### Requirement 5: Rewards Store and Economy

**User Story:** As a user, I want to spend earned FluxoCoins on useful features and customizations, so that I can enhance my app experience.

#### Acceptance Criteria

1. THE SyncLife_System SHALL provide a store where users can spend FluxoCoins
2. WHEN a user purchases functional items, THE SyncLife_System SHALL unlock features like additional boards or group members
3. WHEN a user purchases visual items, THE SyncLife_System SHALL unlock themes, avatar icons, and achievement sounds
4. WHEN a user purchases utility items, THE SyncLife_System SHALL provide benefits like "Streak Freeze" protection
5. THE SyncLife_System SHALL validate purchases by deducting the correct amount of FluxoCoins from user balance

### Requirement 6: Invitation and Growth System

**User Story:** As a user, I want to earn rewards for inviting others, so that I'm incentivized to grow the community while preventing abuse.

#### Acceptance Criteria

1. WHEN a user invites someone who already has an account, THE SyncLife_System SHALL connect them but not award bonus coins
2. WHEN a user invites someone who creates a new account, THE SyncLife_System SHALL mark the bonus as pending
3. WHEN a new user completes their first 5 tasks, THE SyncLife_System SHALL award the referral bonus to the inviter
4. THE SyncLife_System SHALL track invitation sources to prevent fraudulent account creation

### Requirement 7: Notification System

**User Story:** As a user, I want to receive timely notifications about my tasks and team progress, so that I stay informed and engaged.

#### Acceptance Criteria

1. WHEN morning arrives (user-configurable time), THE SyncLife_System SHALL send a daily summary notification
2. WHEN a team member completes a task, THE SyncLife_System SHALL notify other board members
3. WHEN Daily_Processing completes, THE SyncLife_System SHALL send a night summary with performance and streak updates
4. THE SyncLife_System SHALL allow users to send quick emoji reactions via notifications
5. THE SyncLife_System SHALL respect user notification preferences and quiet hours

### Requirement 8: Offline Functionality and Synchronization

**User Story:** As a user, I want to use the app without internet connection, so that I can manage tasks anywhere and sync when connection is restored.

#### Acceptance Criteria

1. WHEN the device is offline, THE SyncLife_System SHALL allow creating and editing tasks locally
2. WHEN internet connection is restored, THE SyncLife_System SHALL synchronize local changes with the server
3. WHEN sync conflicts occur, THE SyncLife_System SHALL resolve them using last-write-wins strategy for task completion status
4. THE SyncLife_System SHALL queue notifications and process them when connection is available

### Requirement 9: Monetization and Premium Features

**User Story:** As a user, I want access to premium features through subscription, so that I can unlock advanced functionality while supporting the app development.

#### Acceptance Criteria

1. THE SyncLife_System SHALL limit free users to a specific number of active tasks and boards
2. THE SyncLife_System SHALL display discrete advertisements for free users
3. WHEN a user subscribes to Premium, THE SyncLife_System SHALL remove all limitations and advertisements
4. WHEN a user subscribes to Premium, THE SyncLife_System SHALL enable calendar integration and advanced backup features
5. THE SyncLife_System SHALL allow free users to temporarily unlock premium features using FluxoCoins from the rewards store

### Requirement 10: User Interface and Experience

**User Story:** As a user, I want a clean, intuitive interface that reduces anxiety, so that I can focus on my tasks without distraction.

#### Acceptance Criteria

1. THE SyncLife_System SHALL implement a minimalist design with ample white space
2. THE SyncLife_System SHALL hide the main menu behind a stylized symbol in the top-left corner
3. WHEN a user clicks the menu symbol, THE SyncLife_System SHALL slide out a lateral menu
4. THE SyncLife_System SHALL support both light and dark themes with automatic system detection
5. WHEN a user opens the app for the first time, THE SyncLife_System SHALL provide an onboarding tour with contextual explanations
6. THE SyncLife_System SHALL be accessible across Android, iOS, and Web platforms with consistent functionality