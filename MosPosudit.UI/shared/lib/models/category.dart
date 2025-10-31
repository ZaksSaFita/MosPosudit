class CategoryModel {
  final int id;
  final String? name;
  final String? description;
  final String? imageBase64; // For uploaded data: base64 encoded image (null for seeded data - Flutter will load from assets based on name)

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

