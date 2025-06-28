class Category {
  final String name;
  final int color;

  Category({
    required this.name,
    this.color = 0xFFFFFFFF, // Default to white
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      color: json['color'] as int? ?? 0xFFFFFFFF, // Default to white if null
    );
  }
}
