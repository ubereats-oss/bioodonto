// lib/features/patient/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/payment_model.dart';
import '../widgets/patient_widgets.dart';
import 'patient_profile_screen.dart';

// ─── Dados mock (substituir por getPatientAppointments) ──────────────────────

AppointmentModel _mockAppt(
  String id,
  String procedures,
  String fromTime,
  String toTime,
  DateTime date,
  String statusColor,
) {
  return AppointmentModel(
    id: id,
    patientName: 'Paciente',
    procedures: procedures,
    fromTime: fromTime,
    toTime: toTime,
    date: DateTime(date.year, date.month, date.day),
    atomicDate: date.year * 10000 + date.month * 100 + date.day,
    statusColor: statusColor,
    clinicBusinessId: '5184665339297792',
  );
}

final _mockAppointments = [
  _mockAppt('1', 'Limpeza e Clareamento', '10:00', '11:00',
      DateTime.now().add(const Duration(days: 3)), '#66bb6a'),
  _mockAppt('2', 'Consulta Ortodôntica', '14:00', '15:00',
      DateTime.now().add(const Duration(days: 15)), '#ffa726'),
  _mockAppt('3', 'Extração', '09:00', '10:00',
      DateTime.now().subtract(const Duration(days: 30)), '#9e9e9e'),
];

final _mockPayments = [
  PaymentModel(
    id: '1',
    patientId: 'mock',
    description: 'Implante Dentário',
    value: 2500.00,
    dueDate: DateTime.now().add(const Duration(days: 10)),
    status: PaymentStatus.pendente,
  ),
  PaymentModel(
    id: '2',
    patientId: 'mock',
    description: 'Limpeza e Clareamento',
    value: 350.00,
    dueDate: DateTime.now().subtract(const Duration(days: 20)),
    paidAt: DateTime.now().subtract(const Duration(days: 22)),
    status: PaymentStatus.pago,
  ),
  PaymentModel(
    id: '3',
    patientId: 'mock',
    description: 'Consulta Ortodôntica',
    value: 180.00,
    dueDate: DateTime.now().subtract(const Duration(days: 5)),
    status: PaymentStatus.vencido,
  ),
];

// ─── Shell com bottom nav ─────────────────────────────────────────────────────

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    _HomeTab(),
    _PlaceholderTab(icon: Icons.calendar_month_outlined, label: 'Agenda'),
    _PlaceholderTab(icon: Icons.payments_outlined, label: 'Financeiro'),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments, color: AppColors.primary),
            label: 'Financeiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── Aba Home ─────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Paciente';

    final upcoming = _mockAppointments
        .where((a) =>
            a.dateTimeFrom.isAfter(DateTime.now()) &&
            a.status != AppointmentStatus.cancelado)
        .toList()
      ..sort((a, b) => a.dateTimeFrom.compareTo(b.dateTimeFrom));

    final past = _mockAppointments
        .where((a) => a.dateTimeFrom.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.dateTimeFrom.compareTo(a.dateTimeFrom));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 32),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                Text(
                  'Olá, $firstName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Veja seus agendamentos e histórico',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (upcoming.isNotEmpty) ...[
                  NextAppointmentCard(appointment: upcoming.first),
                  const SizedBox(height: 24),
                ],

                if (upcoming.length > 1) ...[
                  SectionHeader(
                    title: 'Próximos agendamentos',
                    actionLabel: 'Ver todos',
                    onAction: () {},
                  ),
                  const SizedBox(height: 12),
                  ...upcoming.skip(1).map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppointmentListItem(appointment: a),
                      )),
                  const SizedBox(height: 24),
                ],

                SectionHeader(
                  title: 'Financeiro',
                  actionLabel: 'Ver todos',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                ..._mockPayments.take(3).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PaymentListItem(payment: p),
                    )),

                const SizedBox(height: 24),

                if (past.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Histórico de consultas',
                    actionLabel: 'Ver todos',
                    onAction: () {},
                  ),
                  const SizedBox(height: 12),
                  ...past.take(3).map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppointmentListItem(appointment: a),
                      )),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder para abas ainda não implementadas ────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              '$label — em breve',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
