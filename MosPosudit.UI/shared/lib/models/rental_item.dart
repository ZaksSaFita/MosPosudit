class RentalItemModel {
  final int id;
  final int rentalId;
  final int toolId;
  final int quantity;
  final num dailyRate;
  final String? notes;

  RentalItemModel({
    required this.id,
    required this.rentalId,
    required this.toolId,
    required this.quantity,
    required this.dailyRate,
    this.notes,
  });

  factory RentalItemModel.fromJson(Map<String, dynamic> json) => RentalItemModel(
        id: json['id'],
        rentalId: json['rentalId'],
        toolId: json['toolId'],
        quantity: json['quantity'],
        dailyRate: json['dailyRate'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rentalId': rentalId,
        'toolId': toolId,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'notes': notes,
      };
}

