enum TaskStatus { pending, running, completed, failed }

class HackingTask {
  final String id;
  final String name;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? toolId;
  final String? scriptId;
  final Map<String, dynamic> parameters;
  final String? output;
  final String? errorMessage;
  final int progress; // 0-100

  HackingTask({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.toolId,
    this.scriptId,
    required this.parameters,
    this.output,
    this.errorMessage,
    this.progress = 0,
  });

  factory HackingTask.fromJson(Map<String, dynamic> json) {
    return HackingTask(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      toolId: json['toolId'],
      scriptId: json['scriptId'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      output: json['output'],
      errorMessage: json['errorMessage'],
      progress: json['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'toolId': toolId,
      'scriptId': scriptId,
      'parameters': parameters,
      'output': output,
      'errorMessage': errorMessage,
      'progress': progress,
    };
  }

  HackingTask copyWith({
    String? id,
    String? name,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? toolId,
    String? scriptId,
    Map<String, dynamic>? parameters,
    String? output,
    String? errorMessage,
    int? progress,
  }) {
    return HackingTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      toolId: toolId ?? this.toolId,
      scriptId: scriptId ?? this.scriptId,
      parameters: parameters ?? this.parameters,
      output: output ?? this.output,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}
