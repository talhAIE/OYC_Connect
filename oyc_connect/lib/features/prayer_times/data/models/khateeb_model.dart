class Khateeb {
  final int id;
  final String name;

  Khateeb({required this.id, required this.name});

  factory Khateeb.fromJson(Map<String, dynamic> json) {
    return Khateeb(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
