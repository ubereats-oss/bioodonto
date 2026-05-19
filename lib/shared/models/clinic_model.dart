// lib/shared/models/clinic_model.dart

class ClinicModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final bool isActive;
  final String? clinicorpId;

  const ClinicModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.isActive = true,
    this.clinicorpId,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map, String id) =>
      ClinicModel(
        id: id,
        name: map['name'] ?? '',
        logoUrl: map['logoUrl'],
        primaryColor: map['primaryColor'],
        isActive: map['isActive'] ?? true,
        clinicorpId: map['clinicorpId'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'logoUrl': logoUrl,
        'primaryColor': primaryColor,
        'isActive': isActive,
        'clinicorpId': clinicorpId,
      };
}
