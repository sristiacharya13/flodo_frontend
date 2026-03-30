class Task {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedById;
  final int position;
  final bool isRecurring;
  final String? recurringType;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    required this.position,
    required this.isRecurring,
    this.recurringType,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      blockedById: json['blocked_by_id'],
      position: json['position'],
      isRecurring: json['is_recurring'],
      recurringType: json['recurring_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'blocked_by_id': blockedById,
      'position': position,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
    };
  }
}