class Profession {
  final String id;
  final String name;
  final String? description;

  /// İçerik, quiz ve proje bakımından hazır mı? Hazır değilse "Yakında"
  /// olarak gösterilir ve seçilemez.
  final bool isAvailable;

  Profession({
    required this.id,
    required this.name,
    this.description,
    this.isAvailable = true,
  });

  factory Profession.fromJson(Map<String, dynamic> json) {
    return Profession(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      // Alan yoksa (eski API) meslek seçilebilir sayılır.
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : true,
    );
  }
}
