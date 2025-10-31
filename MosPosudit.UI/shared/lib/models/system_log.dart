class SystemLogModel {
  final int id;
  final DateTime timestamp;
  final String? logLevel;
  final String? action;
  final String? entity;
  final int? entityId;
  final String? message;
  final String? username;
  final String? ipAddress;
  final String? additionalInfo;
  final String? stackTrace;
  final String? details;

  SystemLogModel({
    required this.id,
    required this.timestamp,
    this.logLevel,
    this.action,
    this.entity,
    this.entityId,
    this.message,
    this.username,
    this.ipAddress,
    this.additionalInfo,
    this.stackTrace,
    this.details,
  });

  factory SystemLogModel.fromJson(Map<String, dynamic> json) => SystemLogModel(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        logLevel: json['logLevel'],
        action: json['action'],
        entity: json['entity'],
        entityId: json['entityId'],
        message: json['message'],
        username: json['username'],
        ipAddress: json['ipAddress'],
        additionalInfo: json['additionalInfo'],
        stackTrace: json['stackTrace'],
        details: json['details'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'logLevel': logLevel,
        'action': action,
        'entity': entity,
        'entityId': entityId,
        'message': message,
        'username': username,
        'ipAddress': ipAddress,
        'additionalInfo': additionalInfo,
        'stackTrace': stackTrace,
        'details': details,
      };
}

