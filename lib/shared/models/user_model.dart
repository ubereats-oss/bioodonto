// lib/shared/models/user_model.dart

enum UserRole {
  pacienteComum,
  pacientePremium,
  administrativo,
  direcao,
  adminApp;

  String get label {
    switch (this) {
      case UserRole.pacienteComum:
        return 'Paciente';
      case UserRole.pacientePremium:
        return 'Paciente Premium';
      case UserRole.administrativo:
        return 'Administrativo';
      case UserRole.direcao:
        return 'Direção';
      case UserRole.adminApp:
        return 'Admin App';
    }
  }

  bool get isClinicStaff =>
      this == UserRole.administrativo ||
      this == UserRole.direcao ||
      this == UserRole.adminApp;

  /// Perfis que este usuário pode criar
  List<UserRole> get canCreateRoles {
    switch (this) {
      case UserRole.adminApp:
        return UserRole.values;
      case UserRole.direcao:
        return [UserRole.direcao, UserRole.administrativo];
      default:
        return [];
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String? phone;
  final String? cpf;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final String clinicId;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    this.phone,
    this.cpf,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.clinicId,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      phone: map['phone'],
      cpf: map['cpf'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.pacienteComum,
      ),
      clinicId: map['clinicId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'phone': phone,
        'cpf': cpf,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'clinicId': clinicId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isActive': isActive,
      };

  UserModel copyWith({
    String? displayName,
    String? phone,
    String? cpf,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        phone: phone ?? this.phone,
        cpf: cpf ?? this.cpf,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        clinicId: clinicId,
        createdAt: createdAt,
        isActive: isActive ?? this.isActive,
      );
}
