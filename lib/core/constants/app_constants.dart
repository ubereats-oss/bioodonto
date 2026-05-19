// lib/core/constants/app_constants.dart

class AppConstants {
  // Coleções Firestore
  static const String usersCollection = 'users';
  static const String clinicsCollection = 'clinics';

  // Chaves SharedPreferences
  static const String selectedClinicKey = 'selected_clinic_id';

  // Clínica padrão (única ativa no momento)
  static const String defaultClinicId = 'lauro';
  static const String adminClinicId = 'main';

  // Feature flag: mostrar seletor de clínica
  // Mudar para true quando houver mais de uma clínica ativa
  static const bool showClinicSelector = false;

  // Clinicorp / Cloud Functions
  static const String functionsBaseUrl =
      'https://southamerica-east1-bio-odonto.cloudfunctions.net';
  static const String clinicorpBusinessId = '5184665339297792';
  static const String clinicorpSubscriberId = 'bioodontolf';
}
