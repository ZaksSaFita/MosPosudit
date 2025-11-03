class CategoryModel {
  final int id;
  final String? name;
  final String? description;
  final String? imageBase64;

  CategoryModel({
    required this.id,
    this.name,
    this.description,
    this.imageBase64,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] ?? json['Id']) as int,
        name: json['name'] ?? json['Name'],
        description: json['description'] ?? json['Description'],
        imageBase64: json['imageBase64'] ?? json['ImageBase64'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageBase64': imageBase64,
      };
}

