import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDraft {
  final String title;
  final String description;
  final DateTime? dueDate;
  final String status;
  final int? blockedById;
  final String? recurrenceInterval;

  TaskDraft({
    this.title = '',
    this.description = '',
    this.dueDate,
    this.status = 'To-Do',
    this.blockedById,
    this.recurrenceInterval,
  });

  TaskDraft copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedById,
    String? recurrenceInterval,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById == -1 ? null : (blockedById ?? this.blockedById),
      recurrenceInterval: recurrenceInterval == 'None' ? null : (recurrenceInterval ?? this.recurrenceInterval),
    );
  }
}

class DraftNotifier extends Notifier<TaskDraft> {
  @override
  TaskDraft build() => TaskDraft();

  void updateDraft(TaskDraft draft) {
    state = draft;
  }

  void clearDraft() {
    state = TaskDraft();
  }
}

final draftProvider = NotifierProvider<DraftNotifier, TaskDraft>(DraftNotifier.new);
