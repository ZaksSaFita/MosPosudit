class MaintenanceLogModel {
  final int id;
  final int toolId;
  final int maintenanceTypeId;
  final DateTime maintenanceDate;
  final String description;
  final num cost;
  final String? notes;
  final String? performedBy;
  final DateTime? nextMaintenanceDate;

  MaintenanceLogModel({
    required this.id,
    required this.toolId,
    required this.maintenanceTypeId,
    required this.maintenanceDate,
    required this.description,
    required this.cost,
    this.notes,
    this.performedBy,
    this.nextMaintenanceDate,
  });

  factory MaintenanceLogModel.fromJson(Map<String, dynamic> json) => MaintenanceLogModel(
        id: json['id'],
        toolId: json['toolId'],
        maintenanceTypeId: json['maintenanceTypeId'],
        maintenanceDate: DateTime.parse(json['maintenanceDate']),
        description: json['description'],
        cost: json['cost'],
        notes: json['notes'],
        performedBy: json['performedBy'],
        nextMaintenanceDate: json['nextMaintenanceDate'] != null ? DateTime.parse(json['nextMaintenanceDate']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'maintenanceTypeId': maintenanceTypeId,
        'maintenanceDate': maintenanceDate.toIso8601String(),
        'description': description,
        'cost': cost,
        'notes': notes,
        'performedBy': performedBy,
        'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
      };
}

class ToolMaintenanceScheduleModel {
  final int id;
  final int toolId;
  final DateTime plannedDate;
  final int maintenanceTypeId;
  final int? assignedToId;
  final String? notes;
  final DateTime createdAt;

  ToolMaintenanceScheduleModel({
    required this.id,
    required this.toolId,
    required this.plannedDate,
    required this.maintenanceTypeId,
    this.assignedToId,
    this.notes,
    required this.createdAt,
  });

  factory ToolMaintenanceScheduleModel.fromJson(Map<String, dynamic> json) => ToolMaintenanceScheduleModel(
        id: json['id'],
        toolId: json['toolId'],
        plannedDate: DateTime.parse(json['plannedDate']),
        maintenanceTypeId: json['maintenanceTypeId'],
        assignedToId: json['assignedToId'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'plannedDate': plannedDate.toIso8601String(),
        'maintenanceTypeId': maintenanceTypeId,
        'assignedToId': assignedToId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}

