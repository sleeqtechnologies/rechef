import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  static const String _googleServerClientId =
      '889706711750-fal61jertrsg6q91o14k8j2kne4o5f0i.apps.googleusercontent.com';
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;

    try {
      await _googleSignIn.initialize(serverClientId: _googleServerClientId);
      _googleSignIn.attemptLightweightAuthentication();
      _googleSignInInitialized = true;
    } catch (e) {
      // Initialization failed, will try again on sign in
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_googleSignInInitialized) {
      await initializeGoogleSignIn();
    }

    if (_googleSignIn.supportsAuthenticate()) {
      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final GoogleSignInClientAuthorization? authorization = await user
          .authorizationClient
          .authorizationForScopes(['openid', 'email', 'profile']);

      if (authorization?.accessToken == null) {
        throw Exception('Failed to get Google access token');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization!.accessToken,
      );

      return _firebaseAuth.signInWithCredential(credential);
    } else {
      final googleProvider = GoogleAuthProvider();
      return _firebaseAuth.signInWithProvider(googleProvider);
    }
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    return _firebaseAuth.signInWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signInAnonymously() async {
    return _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  Future<String?> getIdToken() async {
    return currentUser?.getIdToken();
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user to delete',
      );
    }
    await user.delete();
  }
}
