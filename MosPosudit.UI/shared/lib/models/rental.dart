class RentalModel {
  final int id;
  final int userId;
  final DateTime startDate;
  final DateTime endDate;
  final int statusId;
  final num totalPrice;
  final DateTime createdAt;
  final String? notes;
  final int? toolId; // Optional, since rental can have multiple tools via items
  final bool isReturned;
  final DateTime? returnDate;
  final String? returnNotes;
  final num totalAmount;
  final DateTime? updatedAt;
  final String? userName;
  final String? statusName;
  final List<RentalItemModel>? items;

  RentalModel({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.statusId,
    required this.totalPrice,
    required this.createdAt,
    required this.isReturned,
    required this.totalAmount,
    this.toolId,
    this.notes,
    this.returnDate,
    this.returnNotes,
    this.updatedAt,
    this.userName,
    this.statusName,
    this.items,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
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

    List<RentalItemModel>? items;
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => RentalItemModel.fromJson(item))
          .toList();
    }

    return RentalModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      startDate: parseDateTime(json['startDate']) ?? DateTime.now(),
      endDate: parseDateTime(json['endDate']) ?? DateTime.now(),
      statusId: json['statusId'] as int,
      totalPrice: (json['totalPrice'] ?? 0) as num,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      notes: json['notes'],
      toolId: json['toolId'] as int?,
      isReturned: json['isReturned'] ?? false,
      returnDate: parseDateTime(json['returnDate']),
      returnNotes: json['returnNotes'],
      totalAmount: (json['totalAmount'] ?? 0) as num,
      updatedAt: parseDateTime(json['updatedAt']),
      userName: json['userName'],
      statusName: json['statusName'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'statusId': statusId,
        'totalPrice': totalPrice,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'toolId': toolId,
        'isReturned': isReturned,
        'returnDate': returnDate?.toIso8601String(),
        'returnNotes': returnNotes,
        'totalAmount': totalAmount,
        'updatedAt': updatedAt?.toIso8601String(),
        'userName': userName,
        'statusName': statusName,
        'items': items?.map((item) => item.toJson()).toList(),
      };
}

class RentalItemModel {
  final int id;
  final int rentalId;
  final int toolId;
  final int quantity;
  final num dailyRate;
  final String? notes;
  final String? toolName;

  RentalItemModel({
    required this.id,
    required this.rentalId,
    required this.toolId,
    required this.quantity,
    required this.dailyRate,
    this.notes,
    this.toolName,
  });

  factory RentalItemModel.fromJson(Map<String, dynamic> json) => RentalItemModel(
        id: json['id'],
        rentalId: json['rentalId'],
        toolId: json['toolId'],
        quantity: json['quantity'],
        dailyRate: json['dailyRate'],
        notes: json['notes'],
        toolName: json['toolName'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rentalId': rentalId,
        'toolId': toolId,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'notes': notes,
        'toolName': toolName,
      };
}

