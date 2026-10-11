import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase-only auth. Supports email/password + Google (google_sign_in v7 API).
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    // google_sign_in v7: singleton + initialize() + authenticate()
    await GoogleSignIn.instance.initialize();
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;
    final String? idToken = auth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google Sign-In did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignore if Google was never initialized
    }
    await _auth.signOut();
  }

  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'That email is already registered.';
        case 'weak-password':
          return 'Password is too weak (min 6 characters).';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'missing-id-token':
          return e.message ?? 'Google sign-in failed.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    return e.toString();
  }
}
