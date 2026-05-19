// lib/features/clinic_selector/screens/clinic_selector_screen.dart
//
// ATENÇÃO: esta tela existe e está pronta, mas não é exibida enquanto
// AppConstants.showClinicSelector == false. Basta mudar essa flag para true
// quando houver mais de uma clínica ativa.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/clinic_model.dart';

// Dados das clínicas — migrar para Firestore quando tiver múltiplas unidades
final _clinics = [
  const ClinicModel(
    id: 'lauro',
    name: 'BioOdonto',
    isActive: true,
  ),
  // Adicionar novas clínicas aqui
];

class ClinicSelectorScreen extends StatelessWidget {
  const ClinicSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = _clinics.where((c) => c.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.medical_services_outlined,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Selecione sua clínica',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Escolha a unidade que deseja acessar',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.separated(
                  itemCount: active.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ClinicCard(clinic: active[i]),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final ClinicModel clinic;
  const _ClinicCard({required this.clinic});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: () => _select(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: clinic.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            Image.network(clinic.logoUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          clinic.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(clinic.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textHint),
            ]),
          ),
        ),
      );

  Future<void> _select(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.selectedClinicKey, clinic.id);
    if (context.mounted) context.go('/login');
  }
}
