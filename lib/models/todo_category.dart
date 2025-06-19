class TodoCategory {
  final String name;
  final int color;

  TodoCategory({required this.name, this.color = 0xFFFFFFFF});

  factory TodoCategory.fromJson(Map<String, dynamic> json) {
    return TodoCategory(
      name: json['name'] as String,
      color: json['color'] as int? ?? 0xFFFFFFFF,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
    };
  }

  TodoCategory copyWith({String? name, int? color}) {
    return TodoCategory(
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
