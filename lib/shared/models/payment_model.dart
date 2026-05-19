// lib/shared/models/payment_model.dart

enum PaymentStatus {
  pago,
  pendente,
  vencido;

  String get label {
    switch (this) {
      case PaymentStatus.pago:
        return 'Pago';
      case PaymentStatus.pendente:
        return 'Pendente';
      case PaymentStatus.vencido:
        return 'Vencido';
    }
  }
}

class PaymentModel {
  final String id;
  final String patientId;
  final String description;
  final double value;
  final DateTime dueDate;
  final DateTime? paidAt;
  final PaymentStatus status;

  const PaymentModel({
    required this.id,
    required this.patientId,
    required this.description,
    required this.value,
    required this.dueDate,
    this.paidAt,
    required this.status,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      description: map['description'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      paidAt: map['paidAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paidAt'])
          : null,
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pendente,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'description': description,
        'value': value,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'paidAt': paidAt?.millisecondsSinceEpoch,
        'status': status.name,
      };
}
