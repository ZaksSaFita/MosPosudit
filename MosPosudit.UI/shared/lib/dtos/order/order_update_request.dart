class OrderUpdateRequest {
  final DateTime? startDate;
  final DateTime? endDate;
  final num? totalAmount;
  final bool? isReturned;
  final DateTime? returnDate;

  OrderUpdateRequest({
    this.startDate,
    this.endDate,
    this.totalAmount,
    this.isReturned,
    this.returnDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    if (totalAmount != null) json['totalAmount'] = totalAmount;
    if (isReturned != null) json['isReturned'] = isReturned;
    if (returnDate != null) json['returnDate'] = returnDate!.toIso8601String();
    return json;
  }
}

