// lib/shared/models/appointment_model.dart

enum AppointmentStatus {
  agendado,
  confirmado,
  concluido,
  cancelado;

  String get label {
    switch (this) {
      case AppointmentStatus.agendado:
        return 'Agendado';
      case AppointmentStatus.confirmado:
        return 'Confirmado';
      case AppointmentStatus.concluido:
        return 'Concluído';
      case AppointmentStatus.cancelado:
        return 'Cancelado';
    }
  }
}

class AppointmentModel {
  final String id;
  final String patientName;
  final String? mobilePhone;
  final String? email;
  final String procedures;
  final String fromTime; // "HH:mm"
  final String toTime; // "HH:mm"
  final DateTime date; // meia-noite no horário local (Brasília)
  final int atomicDate; // YYYYMMDD — útil para filtros sem comparar DateTime
  final String statusColor; // hex: "#66bb6a"
  final String? notes;
  final String? categoryDescription;
  final String? categoryColor;
  final bool deleted;
  final String? dentistPersonId;
  final String clinicBusinessId;

  const AppointmentModel({
    required this.id,
    required this.patientName,
    this.mobilePhone,
    this.email,
    required this.procedures,
    required this.fromTime,
    required this.toTime,
    required this.date,
    required this.atomicDate,
    required this.statusColor,
    this.notes,
    this.categoryDescription,
    this.categoryColor,
    this.deleted = false,
    this.dentistPersonId,
    required this.clinicBusinessId,
  });

  /// Combina [date] + [fromTime] em um único DateTime para exibição na UI.
  DateTime get dateTimeFrom {
    final parts = fromTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  /// Mapeia a cor hex do Clinicorp para o enum de status usado nos widgets.
  AppointmentStatus get status {
    switch (statusColor.toLowerCase()) {
      case '#66bb6a':
      case '#4caf50':
        return AppointmentStatus.confirmado;
      case '#ef5350':
      case '#e53935':
      case '#f44336':
        return AppointmentStatus.cancelado;
      case '#9e9e9e':
      case '#bdbdbd':
      case '#757575':
        return AppointmentStatus.concluido;
      default:
        return AppointmentStatus.agendado;
    }
  }

  factory AppointmentModel.fromClinicorp(Map<String, dynamic> json) {
    // A API retorna UTC: "2025-05-02T03:00:00.000Z" = meia-noite em Brasília (UTC-3).
    // Convertemos para local e pegamos só a data (sem hora) para evitar drift de fuso.
    final rawDate = json['date'] as String? ?? json['Date'] as String? ?? '';
    DateTime localMidnight;
    try {
      final utc = DateTime.parse(rawDate);
      final brt = utc.toLocal();
      localMidnight = DateTime(brt.year, brt.month, brt.day);
    } catch (_) {
      localMidnight = DateTime.now();
    }

    return AppointmentModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      patientName: json['PatientName'] as String? ?? '',
      mobilePhone: json['MobilePhone'] as String?,
      email: json['Email'] as String?,
      procedures: json['Procedures'] as String? ?? '',
      fromTime: json['fromTime'] as String? ?? '',
      toTime: json['toTime'] as String? ?? '',
      date: localMidnight,
      atomicDate: (json['AtomicDate'] as num?)?.toInt() ?? 0,
      statusColor: json['StatusColor'] as String? ?? '#ffa726',
      notes: json['Notes'] as String?,
      categoryDescription: json['CategoryDescription'] as String?,
      categoryColor: json['CategoryColor'] as String?,
      deleted: (json['Deleted'] as String? ?? '') == 'X',
      dentistPersonId: json['Dentist_PersonId']?.toString(),
      clinicBusinessId: (json['Clinic_BusinessId'] ?? '').toString(),
    );
  }
}
