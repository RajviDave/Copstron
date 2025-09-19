import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Re-throw the exception so the UI can display the message
      throw e;
    }
  }

  // Register with email & password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        // Once signed in, return the UserCredential
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // If it's a new user, also save their data to Firestore
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await DatabaseService(uid: userCredential.user!.uid).updateUserData(
            userCredential.user!.displayName ?? 'Google User',
            userCredential.user!.email!,
            'Reader', // Default role for Google sign-ups
          );
        }
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      throw e;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}
