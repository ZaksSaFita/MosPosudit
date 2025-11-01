import 'order_item.dart';
import 'payment.dart';

class OrderModel {
  final int id;
  final int userId;
  final String? userFullName;
  final String? userEmail;
  final DateTime startDate;
  final DateTime endDate;
  final num totalAmount;
  final bool termsAccepted;
  final bool confirmationEmailSent;
  final bool isReturned;
  final DateTime? returnDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> orderItems;
  final List<PaymentModel> payments;

  OrderModel({
    required this.id,
    required this.userId,
    this.userFullName,
    this.userEmail,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.termsAccepted,
    required this.confirmationEmailSent,
    required this.isReturned,
    this.returnDate,
    required this.createdAt,
    this.updatedAt,
    this.orderItems = const [],
    this.payments = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
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

    return OrderModel(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      userFullName: json['userFullName'] ?? json['UserFullName'],
      userEmail: json['userEmail'] ?? json['UserEmail'],
      startDate: parseDateTime(json['startDate'] ?? json['StartDate']) ?? DateTime.now(),
      endDate: parseDateTime(json['endDate'] ?? json['EndDate']) ?? DateTime.now(),
      totalAmount: json['totalAmount'] ?? json['TotalAmount'] ?? 0,
      termsAccepted: json['termsAccepted'] ?? json['TermsAccepted'] ?? false,
      confirmationEmailSent: json['confirmationEmailSent'] ?? json['ConfirmationEmailSent'] ?? false,
      isReturned: json['isReturned'] ?? json['IsReturned'] ?? false,
      returnDate: parseDateTime(json['returnDate'] ?? json['ReturnDate']),
      createdAt: parseDateTime(json['createdAt'] ?? json['CreatedAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt'] ?? json['UpdatedAt']),
      orderItems: (json['orderItems'] ?? json['OrderItems'] ?? []).map<OrderItemModel>((item) => OrderItemModel.fromJson(item)).toList(),
      payments: (json['payments'] ?? json['Payments'] ?? []).map<PaymentModel>((item) => PaymentModel.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userFullName': userFullName,
        'userEmail': userEmail,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalAmount': totalAmount,
        'termsAccepted': termsAccepted,
        'confirmationEmailSent': confirmationEmailSent,
        'isReturned': isReturned,
        'returnDate': returnDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'orderItems': orderItems.map((item) => item.toJson()).toList(),
        'payments': payments.map((item) => item.toJson()).toList(),
      };
}

