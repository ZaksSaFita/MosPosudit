class CategoryUpdateRequestDto {
  final String? name;
  final String? description;
  final String? imageBase64;

  CategoryUpdateRequestDto({
    this.name,
    this.description,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (imageBase64 != null) json['imageBase64'] = imageBase64;
    return json;
  }
}

