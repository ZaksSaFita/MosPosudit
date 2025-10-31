class RentalModel {
  final int id;
  final int userId;
  final DateTime startDate;
  final DateTime endDate;
  final int statusId;
  final num totalPrice;
  final DateTime createdAt;
  final String? notes;
  final int toolId;
  final bool isReturned;
  final DateTime? returnDate;
  final String? returnNotes;
  final num totalAmount;
  final DateTime? updatedAt;

  RentalModel({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.statusId,
    required this.totalPrice,
    required this.createdAt,
    required this.toolId,
    required this.isReturned,
    required this.totalAmount,
    this.notes,
    this.returnDate,
    this.returnNotes,
    this.updatedAt,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) => RentalModel(
        id: json['id'],
        userId: json['userId'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        statusId: json['statusId'],
        totalPrice: json['totalPrice'],
        createdAt: DateTime.parse(json['createdAt']),
        notes: json['notes'],
        toolId: json['toolId'],
        isReturned: json['isReturned'] ?? false,
        returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
        returnNotes: json['returnNotes'],
        totalAmount: json['totalAmount'] ?? 0,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'statusId': statusId,
        'totalPrice': totalPrice,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'toolId': toolId,
        'isReturned': isReturned,
        'returnDate': returnDate?.toIso8601String(),
        'returnNotes': returnNotes,
        'totalAmount': totalAmount,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

