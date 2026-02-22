class WebApp {
  final String id;
  String title;
  String htmlCode;
  final DateTime createdAt;
  DateTime updatedAt;
  int iconColor;

  WebApp({
    required this.id,
    required this.title,
    this.htmlCode = '',
    required this.createdAt,
    required this.updatedAt,
    this.iconColor = 0xFF00D2FF,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'htmlCode': htmlCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'iconColor': iconColor,
    };
  }

  factory WebApp.fromMap(Map<String, dynamic> map) {
    return WebApp(
      id: map['id'] as String,
      title: map['title'] as String,
      htmlCode: map['htmlCode'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      iconColor: map['iconColor'] as int? ?? 0xFF00D2FF,
    );
  }
}
