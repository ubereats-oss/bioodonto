// lib/features/clinic/services/clinicorp_service.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/appointment_model.dart';

class ClinicorpService {
  static const _baseUrl =
      'https://southamerica-east1-bio-odonto.cloudfunctions.net';

  Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return (await user.getIdToken()) ?? '';
  }

  Future<http.Response> _get(String path) async {
    final token = await _idToken();
    return http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<AppointmentModel>> getAppointments({
    required String from,
    required String to,
  }) async {
    final res = await _get('/getAppointments?from=$from&to=$to');
    _checkStatus(res, 'getAppointments');
    final list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromClinicorp(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppointmentModel>> getPatientAppointments(
      String patientId) async {
    final res = await _get('/getPatientAppointments?patientId=$patientId');
    _checkStatus(res, 'getPatientAppointments');
    final list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromClinicorp(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    final res = await _get('/getPatient?patientId=$patientId');
    _checkStatus(res, 'getPatient');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<dynamic> getFinancialSummary({
    required String from,
    required String to,
  }) async {
    final res = await _get('/getFinancialSummary?from=$from&to=$to');
    _checkStatus(res, 'getFinancialSummary');
    return json.decode(res.body);
  }

  Future<dynamic> getAnalytics({
    required String from,
    required String to,
  }) async {
    final res = await _get('/getAnalytics?from=$from&to=$to');
    _checkStatus(res, 'getAnalytics');
    return json.decode(res.body);
  }

  void _checkStatus(http.Response res, String endpoint) {
    if (res.statusCode != 200) {
      throw Exception('[$endpoint] HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
