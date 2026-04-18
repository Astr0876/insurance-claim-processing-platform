import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_button.dart';
import '../../../core/widgets/nb_input.dart';
import '../../../app/app_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;
  
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both email and password.'),
            backgroundColor: NBColors.danger,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
        );
      }
      
      // Navigation to AppShell is handled by onAuthStateChange listener in initState
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.message.toLowerCase().contains('user already exists')) {
          errorMessage = 'User already exists. Please sign in instead.';
        } else if (e.message.toLowerCase().contains('email not confirmed')) {
          errorMessage = 'Login failed: Email not confirmed. Please disable "Confirm email" in your Supabase Dashboard settings.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: NBColors.danger,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred.'),
            backgroundColor: NBColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo or Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NBColors.primary,
                    border: Border.all(color: NBColors.black, width: 3),
                    borderRadius: NBRadius.softAll,
                    boxShadow: NBShadows.large,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: NBColors.black,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'LUMINA',
                textAlign: TextAlign.center,
                style: NBText.heading1.copyWith(letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Welcome back! Let\'s lock in.' : 'Create an account to start.',
                textAlign: TextAlign.center,
                style: NBText.body,
              ),
              const SizedBox(height: 48),

              // Inputs
              Text('EMAIL', style: NBText.label),
              const SizedBox(height: 8),
              NBInput(
                controller: _emailController,
                hintText: 'student@university.edu',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              Text('PASSWORD', style: NBText.label),
              const SizedBox(height: 8),
              NBInput(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: NBColors.primary,
                    strokeWidth: 3,
                  ),
                )
              else
                NBButton(
                  label: _isLogin ? 'SIGN IN' : 'SIGN UP',
                  onTap: _authenticate,
                  fillColor: NBColors.primary,
                  fullWidth: true,
                ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin 
                      ? 'Don\'t have an account? Sign Up' 
                      : 'Already have an account? Sign In',
                  textAlign: TextAlign.center,
                  style: NBText.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
