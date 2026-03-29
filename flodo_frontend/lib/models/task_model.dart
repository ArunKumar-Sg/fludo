class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedById;
  final String? recurrenceInterval;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    this.recurrenceInterval,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      blockedById: json['blocked_by_id'],
      recurrenceInterval: json['recurrence_interval'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'blocked_by_id': blockedById,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedById,
    String? recurrenceInterval,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      // Use -1 to represent nullification of blockedById during update if needed
      blockedById: blockedById == -1 ? null : (blockedById ?? this.blockedById),
      recurrenceInterval: recurrenceInterval == 'None' ? null : (recurrenceInterval ?? this.recurrenceInterval),
    );
  }
}
