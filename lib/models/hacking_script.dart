class HackingScript {
  final String id;
  final String name;
  final String description;
  final String category;
  final String scriptPath;
  final List<ScriptParameter> parameters;
  final String author;
  final DateTime createdAt;
  final bool isFavorite;
  final String difficulty;
  final String command;
  final List<String> tags;
  final bool requiresSudo;
  final int? estimatedTime;

  HackingScript({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.scriptPath,
    required this.parameters,
    required this.author,
    required this.createdAt,
    required this.difficulty,
    required this.command,
    required this.tags,
    this.isFavorite = false,
    this.requiresSudo = false,
    this.estimatedTime,
  });

  factory HackingScript.fromJson(Map<String, dynamic> json) {
    return HackingScript(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      scriptPath: json['scriptPath'],
      parameters:
          (json['parameters'] as List?)
              ?.map((p) => ScriptParameter.fromJson(p))
              .toList() ??
          [],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      difficulty: json['difficulty'] ?? 'Beginner',
      command: json['command'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      requiresSudo: json['requiresSudo'] ?? false,
      estimatedTime: json['estimatedTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'scriptPath': scriptPath,
      'parameters': parameters.map((p) => p.toJson()).toList(),
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'command': command,
      'tags': tags,
      'isFavorite': isFavorite,
      'requiresSudo': requiresSudo,
      'estimatedTime': estimatedTime,
    };
  }
}

class ScriptParameter {
  final String name;
  final String label;
  final String type;
  final bool required;
  final String? defaultValue;
  final String? description;

  ScriptParameter({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
  });

  factory ScriptParameter.fromJson(Map<String, dynamic> json) {
    return ScriptParameter(
      name: json['name'],
      label: json['label'],
      type: json['type'],
      required: json['required'] ?? false,
      defaultValue: json['defaultValue'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type,
      'required': required,
      'defaultValue': defaultValue,
      'description': description,
    };
  }
}
