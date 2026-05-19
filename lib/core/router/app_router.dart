// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/clinic/screens/clinic_home_screen.dart';
import '../../features/clinic_selector/screens/clinic_selector_screen.dart';
import '../../features/patient/screens/patient_home_screen.dart';
import '../../shared/models/user_model.dart';
import '../constants/app_constants.dart';

// ─── Router ───────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading || userState.isLoading;
      if (isLoading) return null;

      final isLoggedIn = authState.value != null;
      final user = userState.value;
      final loc = state.matchedLocation;

      final authRoutes = {'/login', '/register', '/forgot-password', '/select-clinic'};

      if (!isLoggedIn) {
        if (authRoutes.contains(loc)) return null;
        return AppConstants.showClinicSelector ? '/select-clinic' : '/login';
      }

      if (user == null) return null;

      // Já logado tentando acessar telas de auth → home
      if (authRoutes.contains(loc) || loc == '/') {
        return _homeFor(user.role);
      }

      // Proteção de rotas por perfil
      if (loc.startsWith('/clinic') && !user.role.isClinicStaff) {
        return _homeFor(user.role);
      }
      if (loc.startsWith('/admin') && user.role != UserRole.adminApp) {
        return _homeFor(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/select-clinic', builder: (_, __) => const ClinicSelectorScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (_, __) => const PatientHomeScreen()),
      GoRoute(path: '/clinic', builder: (_, __) => const ClinicHomeScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Erro: ${state.error}')),
    ),
  );
});

String _homeFor(UserRole role) {
  switch (role) {
    case UserRole.pacienteComum:
    case UserRole.pacientePremium:
      return '/home';
    case UserRole.administrativo:
    case UserRole.direcao:
      return '/clinic';
    case UserRole.adminApp:
      return '/admin';
  }
}
