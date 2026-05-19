// lib/features/clinic/providers/appointments_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/appointment_model.dart';
import '../services/clinicorp_service.dart';

class AppointmentsNotifier
    extends AsyncNotifier<List<AppointmentModel>> {
  static final _fmt = DateFormat('yyyy-MM-dd');

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  @override
  Future<List<AppointmentModel>> build() async {
    final now = DateTime.now();
    // Semana atual: segunda-feira até domingo
    final weekday = now.weekday; // 1 = seg, 7 = dom
    _from = now.subtract(Duration(days: weekday - 1));
    _to = _from.add(const Duration(days: 6));
    return _fetch();
  }

  Future<List<AppointmentModel>> _fetch() =>
      ClinicorpService().getAppointments(
        from: _fmt.format(_from),
        to: _fmt.format(_to),
      );

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setRange(DateTime from, DateTime to) async {
    _from = from;
    _to = to;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsNotifier, List<AppointmentModel>>(
  AppointmentsNotifier.new,
);
