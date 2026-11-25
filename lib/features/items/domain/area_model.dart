class AreaModel {
  const AreaModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
