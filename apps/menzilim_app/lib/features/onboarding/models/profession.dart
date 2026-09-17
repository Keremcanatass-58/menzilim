class Profession {
  final String id;
  final String name;
  final String? description;

  Profession({
    required this.id,
    required this.name,
    this.description,
  });

  factory Profession.fromJson(Map<String, dynamic> json) {
    return Profession(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
    );
  }
}
