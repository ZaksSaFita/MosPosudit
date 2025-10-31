class ToolModel {
  final int id;
  final String? name;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final int? conditionId;
  final num? dailyRate;
  final int? quantity;
  final DateTime? createdAt;
  final bool? isAvailable;
  final num? depositAmount;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String? imageBase64; // For uploaded data: base64 encoded image (null for seeded data - Flutter will load from assets based on name)

  ToolModel({
    required this.id,
    this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    this.conditionId,
    this.dailyRate,
    this.quantity,
    this.createdAt,
    this.isAvailable,
    this.depositAmount,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.imageBase64,
  });

  factory ToolModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return ToolModel(
      id: (json['id'] ?? json['Id']) as int,
      name: json['name'] ?? json['Name'],
      description: json['description'] ?? json['Description'],
      categoryId: json['categoryId'] ?? json['CategoryId'],
      categoryName: json['categoryName'] ?? json['CategoryName'],
      conditionId: json['conditionId'] ?? json['ConditionId'],
      dailyRate: json['dailyRate'] ?? json['DailyRate'],
      quantity: json['quantity'] ?? json['Quantity'],
      createdAt: parseDateTime(json['createdAt'] ?? json['CreatedAt']),
      isAvailable: json['isAvailable'] ?? json['IsAvailable'],
      depositAmount: json['depositAmount'] ?? json['DepositAmount'],
      lastMaintenanceDate: parseDateTime(json['lastMaintenanceDate'] ?? json['LastMaintenanceDate']),
      nextMaintenanceDate: parseDateTime(json['nextMaintenanceDate'] ?? json['NextMaintenanceDate']),
      imageBase64: json['imageBase64'] ?? json['ImageBase64'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'conditionId': conditionId,
        'dailyRate': dailyRate,
        'quantity': quantity,
        'createdAt': createdAt?.toIso8601String(),
        'isAvailable': isAvailable,
        'depositAmount': depositAmount,
        'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
        'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
        'imageBase64': imageBase64,
      };
}

