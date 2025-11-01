class OrderItemModel {
  final int id;
  final int orderId;
  final int toolId;
  final String? toolName;
  final int quantity;
  final num dailyRate;
  final num totalPrice;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.toolId,
    this.toolName,
    required this.quantity,
    required this.dailyRate,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] ?? json['Id'] ?? 0,
        orderId: json['orderId'] ?? json['OrderId'] ?? 0,
        toolId: json['toolId'] ?? json['ToolId'] ?? 0,
        toolName: json['toolName'] ?? json['ToolName'],
        quantity: json['quantity'] ?? json['Quantity'] ?? 0,
        dailyRate: json['dailyRate'] ?? json['DailyRate'] ?? 0,
        totalPrice: json['totalPrice'] ?? json['TotalPrice'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'toolId': toolId,
        'toolName': toolName,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'totalPrice': totalPrice,
      };
}

