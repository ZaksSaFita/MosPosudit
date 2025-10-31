class ToolDamageReportModel {
  final int id;
  final int toolId;
  final int rentalId;
  final int reportedById;
  final DateTime damageDate;
  final String? damageDescription;
  final int severityLevel;
  final num? repairCost;
  final int repairStatusId;
  final DateTime createdAt;

  ToolDamageReportModel({
    required this.id,
    required this.toolId,
    required this.rentalId,
    required this.reportedById,
    required this.damageDate,
    this.damageDescription,
    required this.severityLevel,
    this.repairCost,
    required this.repairStatusId,
    required this.createdAt,
  });

  factory ToolDamageReportModel.fromJson(Map<String, dynamic> json) => ToolDamageReportModel(
        id: json['id'],
        toolId: json['toolId'],
        rentalId: json['rentalId'],
        reportedById: json['reportedById'],
        damageDate: DateTime.parse(json['damageDate']),
        damageDescription: json['damageDescription'],
        severityLevel: json['severityLevel'],
        repairCost: json['repairCost'],
        repairStatusId: json['repairStatusId'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'rentalId': rentalId,
        'reportedById': reportedById,
        'damageDate': damageDate.toIso8601String(),
        'damageDescription': damageDescription,
        'severityLevel': severityLevel,
        'repairCost': repairCost,
        'repairStatusId': repairStatusId,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ToolImageModel {
  final int id;
  final int toolId;
  final String? imageUrl;
  final bool isPrimary;
  final DateTime createdAt;

  ToolImageModel({
    required this.id,
    required this.toolId,
    this.imageUrl,
    required this.isPrimary,
    required this.createdAt,
  });

  factory ToolImageModel.fromJson(Map<String, dynamic> json) => ToolImageModel(
        id: json['id'],
        toolId: json['toolId'],
        imageUrl: json['imageUrl'],
        isPrimary: json['isPrimary'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'imageUrl': imageUrl,
        'isPrimary': isPrimary,
        'createdAt': createdAt.toIso8601String(),
      };
}

