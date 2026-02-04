class PermissionName {
  final String id;
  final String name;
  final String role;
  final String type;

  PermissionName({
    required this.id,
    required this.name,
    required this.role,
    required this.type,
  });

  factory PermissionName.fromMap(Map<dynamic, dynamic> m) {
    final dynamic rawId = m['id'] ?? m['uuid'] ?? m['NameID'] ?? m['ID'] ?? m['name_id'];
    return PermissionName(
      id: rawId?.toString() ?? '',
      name: (m['name'] ?? '').toString(),
      role: (m['role'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'type': type,
  };

  @override
  String toString() => 'PermissionName(id: $id, name: $name, role: $role, type: $type)';
}
