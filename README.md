# BioOdonto — Flutter App

## Estrutura

```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart     ← feature flags e IDs
│   ├── router/app_router.dart           ← navegação + proteção por perfil
│   └── theme/app_theme.dart             ← cores e tema global
├── features/
│   ├── auth/
│   │   ├── providers/auth_provider.dart ← Firebase Auth (todos os métodos)
│   │   ├── screens/
│   │   │   ├── login_screen.dart        ← email/senha + telefone OTP
│   │   │   ├── register_screen.dart     ← cadastro de paciente
│   │   │   └── forgot_password_screen.dart
│   │   └── widgets/auth_widgets.dart    ← widgets reutilizáveis
│   └── clinic_selector/
│       └── screens/clinic_selector_screen.dart  ← pronta, desativada por flag
└── shared/
    └── models/
        ├── user_model.dart   ← UserModel + UserRole enum (5 perfis)
        └── clinic_model.dart
```

## Setup

```bash
# 1. Dependências
flutter pub get

# 2. Configurar Firebase (precisa do projeto criado no console)
dart pub global activate flutterfire_cli
flutterfire configure
# → gera lib/firebase_options.dart → descomente o import no main.dart

# 3. No Firebase Console, habilitar:
#    Authentication → Sign-in method:
#    ✅ Email/senha  ✅ Telefone  ✅ Google  ✅ Apple

# 4. Rodar
flutter run
```

## Perfis de usuário

| Perfil | Home | Pode criar |
|---|---|---|
| pacienteComum | /home | — |
| pacientePremium | /home | — |
| administrativo | /clinic | — |
| direcao | /clinic | administrativo, direção |
| adminApp | /admin | todos |

## Feature flag — seletor de clínicas

```dart
// lib/core/constants/app_constants.dart
static const bool showClinicSelector = false; // ← mudar para true quando ativo
```

Enquanto `false`: app vai direto para `/login` com `defaultClinicId`.
A tela `ClinicSelectorScreen` já existe e funciona, só não é exibida.

## CPF

Não é usado como credencial. Salvo no Firestore apenas para identificação
(cruzamento com dados do Clinicorp). Login é por email, telefone, Google ou Apple.
