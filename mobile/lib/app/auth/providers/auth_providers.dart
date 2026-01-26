import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepository();
  // Initialize Google Sign-In
  repository.initializeGoogleSignIn();
  return repository;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final userModelProvider = Provider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return UserModel.fromFirebaseUser(user);
});
