enum Priority { low, medium, high }

class Todo {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? deadline;
  final Priority priority;
  final String category;
  final String? notes;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.deadline,
    this.priority = Priority.medium,
    this.category = 'General',
    this.notes,
  });
  // CopyWith method for immutable updates
  Todo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? deadline,
    Priority? priority,
    String? category,
    String? notes,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  // Serialization methods
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: Priority.values[json['priority'] as int],
      category: json['category'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.index,
      'category': category,
      'notes': notes,
    };
  }

  // Additional serialization helper
  String toStorageString() {
    return '$id|||$title|||$isCompleted|||${deadline?.toIso8601String() ?? ""}|||'
        '${priority.index}|||$category|||${notes ?? ""}';
  }

  // Factory constructor from storage string
  factory Todo.fromStorageString(String str) {
    final parts = str.split('|||');
    return Todo(
      id: parts[0],
      title: parts[1],
      isCompleted: parts[2] == 'true',
      deadline: parts[3].isNotEmpty ? DateTime.parse(parts[3]) : null,
      priority: Priority.values[int.parse(parts[4])],
      category: parts[5],
      notes: parts[6].isNotEmpty ? parts[6] : null,
    );
  }
  // Operator overrides
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, isCompleted: $isCompleted, '
        'deadline: $deadline, priority: $priority, '
        'category: $category, notes: ${notes ?? "none"}}';
  }

  // Utility methods
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return deadline!.isBefore(DateTime.now());
  }

  String get formattedDeadline {
    if (deadline == null) return 'No deadline';
    final now = DateTime.now();
    final difference = deadline!.difference(now);

    if (difference.isNegative) return 'Overdue';
    if (difference.inDays > 0) return '${difference.inDays}d left';
    if (difference.inHours > 0) return '${difference.inHours}h left';
    return '${difference.inMinutes}m left';
  }

  Priority get effectivePriority {
    if (isOverdue) return Priority.high;
    return priority;
  }

  bool matchesSearch(String query) {
    final searchQuery = query.toLowerCase();
    return title.toLowerCase().contains(searchQuery) ||
        category.toLowerCase().contains(searchQuery) ||
        (notes?.toLowerCase().contains(searchQuery) ?? false);
  }

  // Comparison methods for sorting
  int compareByDeadline(Todo other) {
    if (deadline == null && other.deadline == null) return 0;
    if (deadline == null) return 1;
    if (other.deadline == null) return -1;
    return deadline!.compareTo(other.deadline!);
  }

  int compareByPriority(Todo other) {
    return priority.index.compareTo(other.priority.index);
  }
}
