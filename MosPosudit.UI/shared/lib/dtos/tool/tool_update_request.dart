class ToolUpdateRequestDto {
  final String? name;
  final String? description;
  final int? categoryId;
  final num? dailyRate;
  final int? quantity;
  final num? depositAmount;
  final bool? isAvailable;
  final String? imageBase64;

  ToolUpdateRequestDto({
    this.name,
    this.description,
    this.categoryId,
    this.dailyRate,
    this.quantity,
    this.depositAmount,
    this.isAvailable,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (categoryId != null) json['categoryId'] = categoryId;
    if (dailyRate != null) json['dailyRate'] = dailyRate;
    if (quantity != null) json['quantity'] = quantity;
    if (depositAmount != null) json['depositAmount'] = depositAmount;
    if (isAvailable != null) json['isAvailable'] = isAvailable;
    if (imageBase64 != null) json['imageBase64'] = imageBase64;
    return json;
  }
}

