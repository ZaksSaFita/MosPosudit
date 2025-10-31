class RentalUpdateRequestDto {
  final DateTime startDate;
  final DateTime endDate;
  final int statusId;
  final String? notes;

  RentalUpdateRequestDto({
    required this.startDate,
    required this.endDate,
    required this.statusId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'statusId': statusId,
        'notes': notes,
      };
}

