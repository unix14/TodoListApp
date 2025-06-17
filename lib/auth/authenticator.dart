import 'package:firebase_auth/firebase_auth.dart';

class Authenticator {

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signInWithGoogle() async {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    try {
      UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<dynamic> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        return 'authNoUserFound';
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        return 'authWrongPassword';
      }
      // For other FirebaseAuthException codes
      print('FirebaseAuthException in signIn: ${e.code} - ${e.message}');
      return 'authUnknownError';
    } catch (e) {
      print('Unknown error in signIn: $e');
      return 'authUnknownError';
    }
  }

  static Future<dynamic> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        return 'authWeakPassword';
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        return 'authEmailAlreadyInUse';
      }
      // For other FirebaseAuthException codes
      print('FirebaseAuthException in signUp: ${e.code} - ${e.message}');
      return 'authUnknownError';
    } catch (e) {
      print('Unknown error in signUp: $e');
      return 'authUnknownError';
    }
  }

  //todo complete forgot process
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Stream<User?> get onAuthStateChanged {
    return _auth.authStateChanges();
  }

  static Future<void> deleteCurrentUserAccount() async {
    User? user = _auth.currentUser;

    if (user == null) {
      print('No user is currently signed in.');
      return;
    }

    try {
      await user.delete();
      print('User account deleted successfully.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('This operation is sensitive and requires recent authentication. Please sign in again to delete your account.');
        // In a real app, you would trigger a re-authentication flow here.
      } else {
        print('An error occurred while deleting the user account: ${e.message}');
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
    }
  }
}