import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential> register(
  String email,
  String password,
) async {
  return FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}

Future<UserCredential> signIn(
  String email,
  String password,
) async {
  return FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}

Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
}