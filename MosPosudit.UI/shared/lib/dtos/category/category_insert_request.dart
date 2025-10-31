class CategoryInsertRequestDto {
  final String name;
  final String? description;
  final String? imageBase64;

  CategoryInsertRequestDto({
    required this.name,
    this.description,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'imageBase64': imageBase64,
      };
}

