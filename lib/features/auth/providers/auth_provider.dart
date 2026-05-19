// lib/features/auth/providers/auth_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';

// ─── Providers base ───────────────────────────────────────────────────────────

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Stream do estado de autenticação Firebase
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Dados completos do usuário no Firestore
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref
          .watch(firestoreProvider)
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()
          .map((snap) =>
              snap.exists ? UserModel.fromMap(snap.data()!, snap.id) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService(
      auth: ref.watch(firebaseAuthProvider),
      firestore: ref.watch(firestoreProvider),
    ));

// ─── AuthService ──────────────────────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _db = firestore;

  // ── Email + senha ─────────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
    required String name,
    required String clinicId,
    String? cpf,
    UserRole role = UserRole.pacienteComum,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name);
    await _saveUser(
      uid: cred.user!.uid,
      email: email.trim(),
      name: name,
      role: role,
      clinicId: clinicId,
      cpf: cpf,
    );
    return cred;
  }

  // ── Telefone + OTP ────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) =>
      _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onAutoVerified,
        verificationFailed: onFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (_) {},
      );

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String clinicId,
  }) async {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    final result = await _auth.signInWithCredential(cred);
    if (result.additionalUserInfo?.isNewUser == true) {
      await _saveUser(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        name: result.user!.displayName ?? '',
        role: UserRole.pacienteComum,
        clinicId: clinicId,
        phone: result.user!.phoneNumber,
      );
    }
    return result;
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle({required String clinicId}) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final result = await _auth.signInWithCredential(cred);
    if (result.additionalUserInfo?.isNewUser == true) {
      await _saveUser(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        name: result.user!.displayName ?? '',
        role: UserRole.pacienteComum,
        clinicId: clinicId,
        photoUrl: result.user!.photoURL,
      );
    }
    return result;
  }

  // ── Apple ─────────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithApple({required String clinicId}) async {
    final apple = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);
    final oauthCred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode);
    final result = await _auth.signInWithCredential(oauthCred);
    if (result.additionalUserInfo?.isNewUser == true) {
      final name =
          '${apple.givenName ?? ''} ${apple.familyName ?? ''}'.trim();
      await _saveUser(
        uid: result.user!.uid,
        email: result.user!.email ?? apple.email ?? '',
        name: name,
        role: UserRole.pacienteComum,
        clinicId: clinicId,
      );
    }
    return result;
  }

  // ── Utilitários ───────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Cria usuário interno via convite (não desloga o criador)
  Future<void> createInternalUser({
    required String email,
    required String name,
    required UserRole role,
    required String clinicId,
  }) async {
    await _db.collection('invites').add({
      'email': email,
      'name': name,
      'role': role.name,
      'clinicId': clinicId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> _saveUser({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    required String clinicId,
    String? phone,
    String? photoUrl,
    String? cpf,
  }) =>
      _db.collection(AppConstants.usersCollection).doc(uid).set(
            UserModel(
              uid: uid,
              email: email,
              displayName: name,
              role: role,
              clinicId: clinicId,
              phone: phone,
              photoUrl: photoUrl,
              cpf: cpf,
              createdAt: DateTime.now(),
            ).toMap(),
          );
}
