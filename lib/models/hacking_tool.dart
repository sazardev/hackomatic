class HackingTool {
  final String id;
  final String name;
  final String description;
  final String category;
  final String iconName; // Changed from iconPath to iconName for Material Icons
  final List<ToolParameter> parameters;
  final String command;
  final bool requiresRoot;
  final bool isInstalled;

  HackingTool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconName,
    required this.parameters,
    required this.command,
    this.requiresRoot = false,
    this.isInstalled = false,
  });

  factory HackingTool.fromJson(Map<String, dynamic> json) {
    return HackingTool(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      iconName: json['iconName'] ?? 'build',
      parameters: (json['parameters'] as List)
          .map((p) => ToolParameter.fromJson(p))
          .toList(),
      command: json['command'],
      requiresRoot: json['requiresRoot'] ?? false,
      isInstalled: json['isInstalled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconName': iconName,
      'parameters': parameters.map((p) => p.toJson()).toList(),
      'command': command,
      'requiresRoot': requiresRoot,
      'isInstalled': isInstalled,
    };
  }
}

class ToolParameter {
  final String name;
  final String label;
  final String type; // text, number, boolean, select
  final bool required;
  final String? defaultValue;
  final List<String>? options; // for select type
  final String? placeholder;

  ToolParameter({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.options,
    this.placeholder,
  });

  factory ToolParameter.fromJson(Map<String, dynamic> json) {
    return ToolParameter(
      name: json['name'],
      label: json['label'],
      type: json['type'],
      required: json['required'] ?? false,
      defaultValue: json['defaultValue'],
      options: json['options']?.cast<String>(),
      placeholder: json['placeholder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type,
      'required': required,
      'defaultValue': defaultValue,
      'options': options,
      'placeholder': placeholder,
    };
  }
}
