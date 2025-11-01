class PayPalOrderResponse {
  final String orderId;
  final String approvalUrl;
  final String status;

  PayPalOrderResponse({
    required this.orderId,
    required this.approvalUrl,
    required this.status,
  });

  factory PayPalOrderResponse.fromJson(Map<String, dynamic> json) =>
      PayPalOrderResponse(
        orderId: json['orderId'] ?? json['OrderId'] ?? '',
        approvalUrl: json['approvalUrl'] ?? json['ApprovalUrl'] ?? '',
        status: json['status'] ?? json['Status'] ?? '',
      );
}

