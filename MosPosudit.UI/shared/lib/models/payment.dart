class PaymentModel {
  final int id;
  final int orderId;
  final num amount;
  final bool isCompleted;
  final String? transactionId;
  final DateTime paymentDate;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.isCompleted,
    this.transactionId,
    required this.paymentDate,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return PaymentModel(
      id: json['id'] ?? json['Id'] ?? 0,
      orderId: json['orderId'] ?? json['OrderId'] ?? 0,
      amount: json['amount'] ?? json['Amount'] ?? 0,
      isCompleted: json['isCompleted'] ?? json['IsCompleted'] ?? false,
      transactionId: json['transactionId'] ?? json['TransactionId'],
      paymentDate: parseDateTime(json['paymentDate'] ?? json['PaymentDate']),
      createdAt: parseDateTime(json['createdAt'] ?? json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'amount': amount,
        'isCompleted': isCompleted,
        'transactionId': transactionId,
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

