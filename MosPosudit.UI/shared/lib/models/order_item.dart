class OrderItemModel {
  final int id;
  final int orderId;
  final int toolId;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final num dailyRate;
  final String? notes;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.toolId,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'],
        orderId: json['orderId'],
        toolId: json['toolId'],
        quantity: json['quantity'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        dailyRate: json['dailyRate'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'toolId': toolId,
        'quantity': quantity,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dailyRate': dailyRate,
        'notes': notes,
      };
}

