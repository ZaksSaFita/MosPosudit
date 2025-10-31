class RentalInsertRequestDto {
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final List<RentalItemInsertRequestDto> items;
  final bool termsAccepted;

  RentalInsertRequestDto({
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.items,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'notes': notes,
        'items': items.map((item) => item.toJson()).toList(),
        'termsAccepted': termsAccepted,
      };
}

class RentalItemInsertRequestDto {
  final int toolId;
  final int quantity;
  final num dailyRate;
  final String? notes;

  RentalItemInsertRequestDto({
    required this.toolId,
    required this.quantity,
    required this.dailyRate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'notes': notes,
      };
}

