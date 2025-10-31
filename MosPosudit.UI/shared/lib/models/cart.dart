class CartModel {
  final int id;
  final int userId;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final String? notes;

  CartModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.lastModifiedAt,
    this.notes,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
        id: json['id'],
        userId: json['userId'],
        createdAt: DateTime.parse(json['createdAt']),
        lastModifiedAt: json['lastModifiedAt'] != null ? DateTime.parse(json['lastModifiedAt']) : null,
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'notes': notes,
      };
}

class CartItemModel {
  final int id;
  final int cartId;
  final int toolId;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final num dailyRate;
  final String? notes;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.toolId,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    this.notes,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id'],
        cartId: json['cartId'],
        toolId: json['toolId'],
        quantity: json['quantity'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        dailyRate: json['dailyRate'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cartId': cartId,
        'toolId': toolId,
        'quantity': quantity,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dailyRate': dailyRate,
        'notes': notes,
      };
}

