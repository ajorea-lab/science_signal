import 'package:science_signal/screens/sign_in_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ScienceSignalApp(),
  );
}
class ScienceSignalApp extends StatelessWidget {
  const ScienceSignalApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'Science Quiz',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 160, 101, 13),
        useMaterial3: true,
      ),
      home:const SignInScreen(),
    );
  }
}