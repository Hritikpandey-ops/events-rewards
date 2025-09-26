class UIConfigModel {
  final List<UIModule> modules;
  final Map<String, dynamic> globalConfig;
  final DateTime lastUpdated;

  UIConfigModel({
    required this.modules,
    this.globalConfig = const {},
    required this.lastUpdated,
  });

  // Factory constructor from JSON
  factory UIConfigModel.fromJson(Map<String, dynamic> json) {
    return UIConfigModel(
      modules: (json['modules'] as List<dynamic>? ?? [])
          .map((moduleJson) => UIModule.fromJson(moduleJson as Map<String, dynamic>))
          .toList(),
      globalConfig: json['global_config'] as Map<String, dynamic>? ?? {},
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'modules': modules.map((module) => module.toJson()).toList(),
      'global_config': globalConfig,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UIConfigModel(modules: ${modules.length}, lastUpdated: $lastUpdated)';
  }
}

class UIModule {
  final String id;
  final String type;
  final String title;
  final String? description;
  final bool isVisible;
  final int? order;
  final Map<String, dynamic> config;

  UIModule({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.isVisible = true,
    this.order,
    this.config = const {},
  });

  // Factory constructor from JSON
  factory UIModule.fromJson(Map<String, dynamic> json) {
    return UIModule(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      order: json['order'] as int?,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'is_visible': isVisible,
      'order': order,
      'config': config,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIModule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UIModule(id: $id, type: $type, title: $title, isVisible: $isVisible)';
  }
}