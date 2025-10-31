class RoleModel {
  final int id;
  final String? name;
  final String? description;

  RoleModel({required this.id, this.name, this.description});

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

