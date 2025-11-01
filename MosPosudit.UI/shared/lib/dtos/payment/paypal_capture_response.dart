class PayPalCaptureResponse {
  final String orderId;
  final String transactionId;
  final String status;
  final num amount;
  final bool isCompleted;
  final int databasePaymentId;

  PayPalCaptureResponse({
    required this.orderId,
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.isCompleted,
    required this.databasePaymentId,
  });

  factory PayPalCaptureResponse.fromJson(Map<String, dynamic> json) =>
      PayPalCaptureResponse(
        orderId: json['orderId'] ?? json['OrderId'] ?? '',
        transactionId: json['transactionId'] ?? json['TransactionId'] ?? '',
        status: json['status'] ?? json['Status'] ?? '',
        amount: json['amount'] ?? json['Amount'] ?? 0,
        isCompleted: json['isCompleted'] ?? json['IsCompleted'] ?? false,
        databasePaymentId: json['databasePaymentId'] ?? json['DatabasePaymentId'] ?? 0,
      );
}

