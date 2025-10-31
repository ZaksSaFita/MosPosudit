class ToolInsertRequestDto {
  final String name;
  final String? description;
  final int categoryId;
  final num dailyRate;
  final int quantity;
  final num depositAmount;
  final bool isAvailable;
  final String? imageBase64;

  ToolInsertRequestDto({
    required this.name,
    this.description,
    required this.categoryId,
    required this.dailyRate,
    required this.quantity,
    this.depositAmount = 0,
    this.isAvailable = true,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'dailyRate': dailyRate,
        'quantity': quantity,
        'depositAmount': depositAmount,
        'isAvailable': isAvailable,
        'imageBase64': imageBase64,
      };
}

