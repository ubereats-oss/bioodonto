// lib/features/patient/screens/patient_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/widgets/auth_widgets.dart';
import '../../../shared/models/user_model.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    _nameController.text = user.displayName ?? '';
    _phoneController.text = user.phone ?? '';
    _cpfController.text = user.cpf ?? '';
  }

  Future<void> _save(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        'cpf': _cpfController.text.isEmpty ? null : _cpfController.text,
      });
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameController.text.trim());
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      setState(() => _error = 'Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    await ref.read(authServiceProvider).sendPasswordResetEmail(user!.email!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link de redefinição enviado para seu e-mail'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair da conta',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Deseja realmente sair?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, s) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Erro ao carregar perfil')),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        // Popula campos apenas uma vez
        if (_nameController.text.isEmpty) _populateFields(user);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Meu perfil'),
            actions: [
              if (!_editing)
                TextButton(
                  onPressed: () => setState(() => _editing = true),
                  child: const Text('Editar'),
                )
              else
                TextButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _populateFields(user);
                  }),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Avatar ──
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                (user.displayName ?? 'P')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      if (_editing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.black),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Badge de perfil
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Campos ──
                  _Field(
                    label: 'Nome completo',
                    controller: _nameController,
                    enabled: _editing,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Informe o nome';
                      if (v.trim().split(' ').length < 2)
                        return 'Informe nome e sobrenome';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'E-mail',
                    value: user.email,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'Telefone',
                    controller: _phoneController,
                    enabled: _editing,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMask],
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'CPF',
                    controller: _cpfController,
                    enabled: _editing,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cpfMask],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AuthErrorBanner(message: _error!),
                  ],

                  if (_editing) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : () => _save(user),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Ações ──
                  _ActionTile(
                    icon: Icons.lock_outline,
                    label: 'Alterar senha',
                    onTap: _changePassword,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.logout,
                    label: 'Sair da conta',
                    onTap: _signOut,
                    danger: true,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? value;
  final bool enabled;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<dynamic> inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    this.controller,
    this.value,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters = const [],
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters.cast<TextInputFormatter>(),
        validator: validator,
        style: TextStyle(
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        decoration: InputDecoration(
          labelText: label,
          fillColor: enabled ? AppColors.surfaceVariant : AppColors.surface,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value ?? '—',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: danger
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                )),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
