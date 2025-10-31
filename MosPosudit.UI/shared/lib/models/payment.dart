class PaymentTransactionModel {
  final int id;
  final int rentalId;
  final int paymentMethodId;
  final int statusId;
  final num amount;
  final DateTime transactionDate;
  final String? transactionReference;
  final String? notes;
  final String? transactionId;
  final String? paymentReference;
  final String? refundReason;
  final int userId;
  final int orderId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? processedAt;
  final DateTime? refundedAt;
  final String? description;

  PaymentTransactionModel({
    required this.id,
    required this.rentalId,
    required this.paymentMethodId,
    required this.statusId,
    required this.amount,
    required this.transactionDate,
    required this.userId,
    required this.orderId,
    required this.createdAt,
    this.transactionReference,
    this.notes,
    this.transactionId,
    this.paymentReference,
    this.refundReason,
    this.updatedAt,
    this.processedAt,
    this.refundedAt,
    this.description,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) => PaymentTransactionModel(
        id: json['id'],
        rentalId: json['rentalId'],
        paymentMethodId: json['paymentMethodId'],
        statusId: json['statusId'],
        amount: json['amount'],
        transactionDate: DateTime.parse(json['transactionDate']),
        transactionReference: json['transactionReference'],
        notes: json['notes'],
        transactionId: json['transactionId'],
        paymentReference: json['paymentReference'],
        refundReason: json['refundReason'],
        userId: json['userId'],
        orderId: json['orderId'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
        refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rentalId': rentalId,
        'paymentMethodId': paymentMethodId,
        'statusId': statusId,
        'amount': amount,
        'transactionDate': transactionDate.toIso8601String(),
        'transactionReference': transactionReference,
        'notes': notes,
        'transactionId': transactionId,
        'paymentReference': paymentReference,
        'refundReason': refundReason,
        'userId': userId,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'processedAt': processedAt?.toIso8601String(),
        'refundedAt': refundedAt?.toIso8601String(),
        'description': description,
      };
}

class PaymentMethodModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) => PaymentMethodModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class PaymentStatusModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentStatusModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) => PaymentStatusModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

