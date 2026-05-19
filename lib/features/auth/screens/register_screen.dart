// lib/features/auth/screens/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final clinicId = prefs.getString(AppConstants.selectedClinicKey) ??
          AppConstants.defaultClinicId;

      await ref.read(authServiceProvider).createAccountWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text.trim(),
            clinicId: clinicId,
            cpf: _cpfController.text.isEmpty ? null : _cpfController.text,
          );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _fbError(e.code));
    } catch (_) {
      setState(() => _error = 'Erro ao criar conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fbError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Este e-mail já está cadastrado.';
      case 'invalid-email': return 'E-mail inválido.';
      case 'weak-password': return 'Senha muito fraca. Use ao menos 6 caracteres.';
      default: return 'Erro ao criar conta. Tente novamente.';
    }
  }

  bool _validCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) { sum += int.parse(cpf[i]) * (10 - i); }
    int r = (sum * 10) % 11;
    if (r == 10 || r == 11) r = 0;
    if (r != int.parse(cpf[9])) return false;
    sum = 0;
    for (int i = 0; i < 10; i++) { sum += int.parse(cpf[i]) * (11 - i); }
    r = (sum * 10) % 11;
    if (r == 10 || r == 11) r = 0;
    return r == int.parse(cpf[10]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  title: 'Criar conta',
                  subtitle: 'Preencha os dados para continuar',
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                    if (v.trim().split(' ').length < 2) return 'Informe nome e sobrenome';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // CPF: opcional, só para identificação — não é credencial
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_cpfMask],
                  decoration: const InputDecoration(
                    labelText: 'CPF (opcional)',
                    hintText: '000.000.000-00',
                    helperText: 'Usado apenas para identificação no sistema',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!_validCpf(v)) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                PasswordField(
                  controller: _passwordController,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                PasswordField(
                  controller: _confirmController,
                  label: 'Confirmar senha',
                  validator: (v) {
                    if (v != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: _error!),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Criar conta'),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já tem conta? ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
