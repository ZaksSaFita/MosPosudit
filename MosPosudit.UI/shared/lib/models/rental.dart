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
    List<RentalItemModel>? items;
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => RentalItemModel.fromJson(item))
          .toList();
    }

    return RentalModel(
      id: json['id'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      statusId: json['statusId'],
      totalPrice: json['totalPrice'],
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
      toolId: json['toolId'],
      isReturned: json['isReturned'] ?? false,
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
      returnNotes: json['returnNotes'],
      totalAmount: json['totalAmount'] ?? 0,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
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

