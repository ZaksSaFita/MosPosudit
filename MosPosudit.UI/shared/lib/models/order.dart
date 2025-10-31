class OrderModel {
  final int id;
  final int userId;
  final DateTime orderDate;
  final DateTime startDate;
  final DateTime endDate;
  final num totalAmount;
  final int statusId;
  final int paymentMethodId;
  final String? orderNumber;
  final String? notes;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderDate,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.statusId,
    required this.paymentMethodId,
    this.orderNumber,
    this.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        userId: json['userId'],
        orderDate: DateTime.parse(json['orderDate']),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        totalAmount: json['totalAmount'],
        statusId: json['statusId'],
        paymentMethodId: json['paymentMethodId'],
        orderNumber: json['orderNumber'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'orderDate': orderDate.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalAmount': totalAmount,
        'statusId': statusId,
        'paymentMethodId': paymentMethodId,
        'orderNumber': orderNumber,
        'notes': notes,
      };
}

