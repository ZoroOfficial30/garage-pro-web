enum UserRole { owner, staff }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? staffId;
  final String? avatarBase64;
  final String? designation;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.staffId,
    this.avatarBase64,
    this.designation,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role.name,
        'staffId': staffId,
        'avatarBase64': avatarBase64,
        'designation': designation,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      id: (map['id'] as String?) ?? 'user',
      name: (map['name'] as String?) ?? 'User',
      role: (map['role'] == 'staff') ? UserRole.staff : UserRole.owner,
      staffId: map['staffId'] as String?,
      avatarBase64: map['avatarBase64'] as String?,
      designation: map['designation'] as String?,
    );
  }

  factory AppUser.defaultOwner({String name = 'Apex Auto Workshop'}) {
    return AppUser(
      id: 'owner',
      name: name,
      role: UserRole.owner,
      designation: 'Workshop Owner',
    );
  }
}
