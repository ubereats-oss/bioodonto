// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/clinic/providers/appointments_provider.dart';
import '../../../features/patient/screens/patient_profile_screen.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/user_model.dart';

// ─── Shell principal ──────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(currentUserProvider).value?.role ?? UserRole.pacienteComum;
    final tabs = _buildTabs(role);
    final count = tabs.length;
    final index = _selectedIndex.clamp(0, count - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: tabs.map((t) => t.destination).toList(),
      ),
    );
  }

  List<_Tab> _buildTabs(UserRole role) {
    final inicio = _Tab(
      screen: const _InicioTab(),
      destination: const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.primary),
        label: 'Início',
      ),
    );
    final painel = _Tab(
      screen: const _PainelTab(),
      destination: const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
        label: 'Painel',
      ),
    );
    final agenda = _Tab(
      screen: const _PlaceholderTab(
          icon: Icons.calendar_month_outlined, label: 'Agenda'),
      destination: const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
        label: 'Agenda',
      ),
    );
    final financeiro = _Tab(
      screen: const _PlaceholderTab(
          icon: Icons.payments_outlined, label: 'Financeiro'),
      destination: const NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments, color: AppColors.primary),
        label: 'Financeiro',
      ),
    );
    final admin = _Tab(
      screen: _AdminTab(
        onNavigateToPainel: () => setState(() => _selectedIndex = 1),
      ),
      destination: const NavigationDestination(
        icon: Icon(Icons.admin_panel_settings_outlined),
        selectedIcon:
            Icon(Icons.admin_panel_settings, color: AppColors.primary),
        label: 'Admin',
      ),
    );
    final perfil = _Tab(
      screen: const PatientProfileScreen(),
      destination: const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: 'Perfil',
      ),
    );

    switch (role) {
      case UserRole.pacienteComum:
      case UserRole.pacientePremium:
        return [inicio, agenda, financeiro, perfil];
      case UserRole.administrativo:
        return [inicio, painel, perfil];
      case UserRole.direcao:
        return [inicio, painel, financeiro, perfil];
      case UserRole.adminApp:
        return [inicio, painel, admin, perfil];
    }
  }
}

class _Tab {
  final Widget screen;
  final NavigationDestination destination;
  const _Tab({required this.screen, required this.destination});
}

// ─── Aba: Início (visão pessoal — igual para todos) ───────────────────────────

class _InicioTab extends ConsumerWidget {
  const _InicioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Olá';

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
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                  'Bem-vindo ao BioOdonto',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),

                _InicioSection(
                  icon: Icons.calendar_month_outlined,
                  title: 'Próximo agendamento',
                  message: 'Seus agendamentos aparecerão aqui em breve.',
                ),
                const SizedBox(height: 16),
                _InicioSection(
                  icon: Icons.history,
                  title: 'Histórico de consultas',
                  message: 'Seu histórico aparecerá aqui em breve.',
                ),
                const SizedBox(height: 16),
                _InicioSection(
                  icon: Icons.payments_outlined,
                  title: 'Financeiro',
                  message: 'Seu resumo financeiro aparecerá aqui em breve.',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InicioSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InicioSection({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.textHint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba: Painel (agenda da clínica — staff e admin) ─────────────────────────

class _PainelTab extends ConsumerStatefulWidget {
  const _PainelTab();

  @override
  ConsumerState<_PainelTab> createState() => _PainelTabState();
}

class _PainelTabState extends ConsumerState<_PainelTab> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _goToPrevWeek() {
    final newStart = _weekStart.subtract(const Duration(days: 7));
    setState(() {
      _weekStart = newStart;
      _selectedDate = newStart;
    });
    ref.read(appointmentsProvider.notifier).setRange(
          newStart,
          newStart.add(const Duration(days: 6)),
        );
  }

  void _goToNextWeek() {
    final newStart = _weekStart.add(const Duration(days: 7));
    setState(() {
      _weekStart = newStart;
      _selectedDate = newStart;
    });
    ref.read(appointmentsProvider.notifier).setRange(
          newStart,
          newStart.add(const Duration(days: 6)),
        );
  }

  int _toAtomic(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final selectedAtomic = _toAtomic(_selectedDate);
    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return SafeArea(
      child: Column(
        children: [
          // ── App bar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 28),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  tooltip: 'Atualizar',
                  onPressed: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),

          // ── Navegação de semana ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _goToPrevWeek,
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Text(
                    _weekLabel(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _goToNextWeek,
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Chips dos dias ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = weekDays[i];
                  final isSelected = _toAtomic(day) == _toAtomic(_selectedDate);
                  final isToday = _toAtomic(day) ==
                      _toAtomic(DateTime.now());
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday && !isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E', 'pt_BR')
                                .format(day)
                                .substring(0, 3)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Lista de agendamentos ──────────────────────────────────────────
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => _PainelErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.read(appointmentsProvider.notifier).refresh(),
              ),
              data: (appointments) {
                final dayList = appointments
                    .where((a) => a.atomicDate == selectedAtomic)
                    .toList()
                  ..sort((a, b) => a.fromTime.compareTo(b.fromTime));

                final dayLabel = DateFormat(
                  "EEEE, dd 'de' MMMM",
                  'pt_BR',
                ).format(_selectedDate);

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        dayLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayList.isEmpty
                            ? 'Nenhum agendamento'
                            : '${dayList.length} agendamento${dayList.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (dayList.isEmpty)
                        const _PainelEmptyView()
                      else
                        ...dayList.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AppointmentCard(appointment: a),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _weekLabel() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'pt_BR');
    return '${fmt.format(_weekStart)} – ${fmt.format(weekEnd)}';
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _parseHex(appointment.statusColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.procedures,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (appointment.dentistName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    appointment.dentistName!,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${appointment.fromTime} — ${appointment.toTime}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.warning;
    }
  }
}

class _PainelEmptyView extends StatelessWidget {
  const _PainelEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'Nenhum agendamento para hoje',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainelErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PainelErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar agendamentos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Aba: Admin (opções de administração — adminApp) ─────────────────────────

class _AdminTab extends ConsumerWidget {
  final VoidCallback onNavigateToPainel;
  const _AdminTab({required this.onNavigateToPainel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final firstName = user?.displayName?.split(' ').first ?? 'Admin';

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
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Olá, $firstName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Painel de administração',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),

                _SectionLabel(label: 'Clínica'),
                const SizedBox(height: 12),
                _AdminOptionCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Agendamentos',
                  subtitle: 'Ver agenda do dia e da semana',
                  onTap: onNavigateToPainel,
                ),
                const SizedBox(height: 10),
                _AdminOptionCard(
                  icon: Icons.payments_outlined,
                  title: 'Financeiro',
                  subtitle: 'Resumo financeiro da clínica',
                  onTap: () {},
                  comingSoon: true,
                ),
                const SizedBox(height: 10),
                _AdminOptionCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Relatórios',
                  subtitle: 'Analíticos e desempenho',
                  onTap: () {},
                  comingSoon: true,
                ),

                const SizedBox(height: 24),

                _SectionLabel(label: 'Gestão'),
                const SizedBox(height: 12),
                _AdminOptionCard(
                  icon: Icons.people_outline,
                  title: 'Usuários',
                  subtitle: 'Gerenciar pacientes e equipe',
                  onTap: () {},
                  comingSoon: true,
                ),
                const SizedBox(height: 10),
                _AdminOptionCard(
                  icon: Icons.business_outlined,
                  title: 'Clínicas',
                  subtitle: 'Dados e configurações da clínica',
                  onTap: () {},
                  comingSoon: true,
                ),
                const SizedBox(height: 10),
                _AdminOptionCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notificações',
                  subtitle: 'Enviar comunicados aos pacientes',
                  onTap: () {},
                  comingSoon: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool comingSoon;

  const _AdminOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: comingSoon
                    ? AppColors.surfaceVariant
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: comingSoon ? AppColors.textHint : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: comingSoon
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'em breve',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────

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
                  color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
