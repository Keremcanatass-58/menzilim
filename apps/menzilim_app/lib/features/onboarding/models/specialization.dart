class Specialization {
  final String id;
  final String name;
  final String? description;

  Specialization({
    required this.id,
    required this.name,
    this.description,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
    );
  }
}