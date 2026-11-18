import 'package:science_signal/services/auth_services.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:science_signal/screens/quiz_page.dart';



class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() =>
      _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!_validateInput(email, password)) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await auth.register(
        email,
        password,
      );

      if (!mounted) return;

      _openQuiz();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = _registrationErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Registration failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (loading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!_validateInput(email, password)) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await auth.signIn(
        email,
        password,
      );

      if (!mounted) return;

      _openQuiz();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = _signInErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Sign-in failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  bool _validateInput(
    String email,
    String password,
  ) {
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Enter your email address.';
      });

      return false;
    }

    if (!email.contains('@')) {
      setState(() {
        errorMessage = 'Enter a valid email address.';
      });

      return false;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Enter your password.';
      });

      return false;
    }

    return true;
  }

  String _registrationErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'email-already-in-use':
        return 'An account already exists for this email.';

      case 'operation-not-allowed':
        return 'Email and password registration is not enabled.';

      case 'network-request-failed':
        return 'A network error occurred. Check your connection.';

      case 'too-many-requests':
        return 'Too many requests. Please try again later.';

      default:
        return error.message ?? 'Registration failed.';
    }
  }

  String _signInErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'user-not-found':
        return 'No account was found for this email.';

      case 'wrong-password':
        return 'The email or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled.';

      case 'network-request-failed':
        return 'A network error occurred. Check your connection.';

      case 'too-many-requests':
        return 'Too many sign-in attempts. Please try again later.';

      default:
        return error.message ?? 'Sign-in failed.';
    }
  }

  void _openQuiz() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            const ScienceQuizScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Science Signal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              Icon(
                Icons.science,
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),

              const SizedBox(height: 16),

              Text(
                'Science Signal',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),

              const SizedBox(height: 8),

              const Text(
                'Sign in to begin the science quiz.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              TextField(
                controller: emailController,
                enabled: !loading,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                enabled: !loading,
                obscureText: true,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: loading
                    ? null
                    : (_) => _handleSignIn(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed:
                    loading ? null : _handleRegister,
                child: const Text('Sign Up'),
              ),

              const SizedBox(height: 8),

              OutlinedButton(
                onPressed:
                    loading ? null : _handleSignIn,
                child: const Text('Sign In'),
              ),

              const SizedBox(height: 16),

              if (loading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              if (errorMessage != null) ...[
                if (loading)
                  const SizedBox(height: 16),

                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}