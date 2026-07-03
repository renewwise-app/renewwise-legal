import 'package:google_sign_in/google_sign_in.dart';

/// Lightweight welcome sign-in for first launch (account identification only).
class WelcomeAuthService {
  WelcomeAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
            );

  final GoogleSignIn _googleSignIn;

  Future<WelcomeAuthResult?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final email = account.email.trim();
    if (email.isEmpty) return null;
    return WelcomeAuthResult(email: email, provider: WelcomeAuthProvider.google);
  }
}

enum WelcomeAuthProvider { google, email }

class WelcomeAuthResult {
  const WelcomeAuthResult({
    required this.email,
    required this.provider,
  });

  final String email;
  final WelcomeAuthProvider provider;
}
