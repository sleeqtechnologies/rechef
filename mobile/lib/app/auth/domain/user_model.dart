import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  String get initials {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e[0].toUpperCase();
    return 'AN';
  }
}
