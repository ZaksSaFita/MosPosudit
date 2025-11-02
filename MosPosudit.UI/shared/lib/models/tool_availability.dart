class ToolAvailabilityModel {
  final int toolId;
  final int totalQuantity;
  final Map<String, int> dailyAvailability; // Key: "YYYY-MM-DD", Value: available quantity

  ToolAvailabilityModel({
    required this.toolId,
    required this.totalQuantity,
    required this.dailyAvailability,
  });

  factory ToolAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final dailyAvailMap = <String, int>{};
    if (json['dailyAvailability'] != null) {
      final dailyAvailJson = json['dailyAvailability'] as Map<String, dynamic>;
      dailyAvailJson.forEach((key, value) {
        dailyAvailMap[key] = value as int;
      });
    }

    return ToolAvailabilityModel(
      toolId: (json['toolId'] ?? json['ToolId']) as int,
      totalQuantity: (json['totalQuantity'] ?? json['TotalQuantity']) as int,
      dailyAvailability: dailyAvailMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'totalQuantity': totalQuantity,
        'dailyAvailability': dailyAvailability,
      };

  /// Get available quantity for a specific date
  /// Returns null if date is not in the range
  int? getAvailableQuantityForDate(DateTime date) {
    final dateKey = _formatDate(date);
    return dailyAvailability[dateKey];
  }

  /// Get available quantity for a date string (YYYY-MM-DD)
  int? getAvailableQuantityForDateString(String dateString) {
    return dailyAvailability[dateString];
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

