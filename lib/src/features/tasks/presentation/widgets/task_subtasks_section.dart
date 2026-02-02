import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/subtask.dart';
import '../../domain/models/create_subtask_request.dart';
import '../providers/subtask_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TaskSubtasksSection extends ConsumerStatefulWidget {
  const TaskSubtasksSection({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<TaskSubtasksSection> createState() => _TaskSubtasksSectionState();
}

class _TaskSubtasksSectionState extends ConsumerState<TaskSubtasksSect