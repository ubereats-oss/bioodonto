// lib/features/auth/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _method = 'email'; // 'email' | 'phone'
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _clinicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.selectedClinicKey) ??
        AppConstants.defaultClinicId;
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _fbError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await _clinicId();
      await ref.read(authServiceProvider).signInWithGoogle(clinicId: id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = await _clinicId();
      await ref.read(authServiceProvider).signInWithApple(clinicId: id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fbError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Conta desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde.';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                ),
              ),

              const SizedBox(height: 32),

              const AuthHeader(
                title: 'Entrar na conta',
                subtitle: 'Acesse sua conta BioOdonto',
              ),

              const SizedBox(height: 28),

              // Toggle email / telefone
              _MethodToggle(
                selected: _method,
                onChanged: (v) => setState(() => _method = v),
              ),

              const SizedBox(height: 24),

              if (_method == 'email') ...[
                Form(
                  key: _formKey,
                  child: Column(children: [
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
                    PasswordField(
                      controller: _passwordController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a senha';
                        return null;
                      },
                    ),
                  ]),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _error!),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _loginEmail,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Entrar'),
                ),
              ] else ...[
                const _PhoneForm(clinicId: AppConstants.defaultClinicId),
              ],

              const SizedBox(height: 24),
              const OrDivider(),
              const SizedBox(height: 16),

              SocialLoginButton(
                label: 'Continuar com Google',
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 22),
                ),
                onTap: _loading ? null : _loginGoogle,
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                label: 'Continuar com Apple',
                icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                onTap: _loading ? null : _loginApple,
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem conta? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Criar conta'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle email/telefone ────────────────────────────────────────────────────

class _MethodToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MethodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _Tab(
                label: 'E-mail',
                active: selected == 'email',
                onTap: () => onChanged('email')),
            _Tab(
                label: 'Telefone',
                active: selected == 'phone',
                onTap: () => onChanged('phone')),
          ],
        ),
      );
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1))
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}

// ─── Formulário de telefone + OTP ─────────────────────────────────────────────

class _PhoneForm extends ConsumerStatefulWidget {
  final String clinicId;
  const _PhoneForm({required this.clinicId});

  @override
  ConsumerState<_PhoneForm> createState() => _PhoneFormState();
}

class _PhoneFormState extends ConsumerState<_PhoneForm> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  String? _verificationId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = '+55${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
    setState(() {
      _loading = true;
      _error = null;
    });

    await ref.read(authServiceProvider).sendOtp(
          phoneNumber: phone,
          onAutoVerified: (cred) =>
              FirebaseAuth.instance.signInWithCredential(cred),
          onFailed: (e) {
            if (mounted) setState(() => _error = 'Erro ao enviar código.');
          },
          onCodeSent: (vid, _) {
            if (mounted) {
              setState(() {
                _verificationId = vid;
                _codeSent = true;
              });
            }
          },
        );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 6) {
      setState(() => _error = 'Digite os 6 dígitos do código.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).verifyOtp(
            verificationId: _verificationId!,
            smsCode: _otpController.text,
            clinicId: widget.clinicId,
          );
    } on FirebaseAuthException catch (_) {
      if (mounted) setState(() => _error = 'Código inválido ou expirado.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_codeSent) {
      return Column(children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: const InputDecoration(
            labelText: 'Celular (DDD + número)',
            prefixText: '+55 ',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AuthErrorBanner(message: _error!),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _sendCode,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Enviar código'),
        ),
      ]);
    }

    return Column(children: [
      const Text('Digite o código recebido por SMS',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
        decoration: const InputDecoration(counterText: '', hintText: '------'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        AuthErrorBanner(message: _error!),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _loading ? null : _verify,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Verificar código'),
      ),
      TextButton(
        onPressed: () => setState(() {
          _codeSent = false;
          _error = null;
        }),
        child: const Text('Reenviar código'),
      ),
    ]);
  }
}
