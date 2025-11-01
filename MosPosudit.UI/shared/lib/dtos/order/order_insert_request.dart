class OrderInsertRequest {
  final int userId;
  final DateTime startDate;
  final DateTime endDate;
  final bool termsAccepted;
  final List<OrderItemInsertRequest> orderItems;

  OrderInsertRequest({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.termsAccepted,
    required this.orderItems,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'termsAccepted': termsAccepted,
        'orderItems': orderItems.map((item) => item.toJson()).toList(),
      };
}

class OrderItemInsertRequest {
  final int toolId;
  final int quantity;

  OrderItemInsertRequest({
    required this.toolId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'quantity': quantity,
      };
}

