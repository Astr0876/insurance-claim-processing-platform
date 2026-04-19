import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/constants.dart';
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
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
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

  void _enterDemoMode() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
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

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Sign up and auto-sign-in
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: AppConstants.supabaseAuthRedirectUrl,
        );

        // If email confirmation is required, the session may be null
        // In that case, try signing in directly
        if (response.session == null && response.user != null) {
          // Try immediate sign in (works if email confirmation is disabled)
          try {
            await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account created! Check your email to confirm, or use Demo Mode.',
                  ),
                  backgroundColor: NBColors.blue,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: NBColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: NBColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              const SizedBox(height: 40),
              // Logo
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
              const SizedBox(height: 24),
              Text(
                'LUMINA',
                textAlign: TextAlign.center,
                style: NBText.heading1.copyWith(letterSpacing: 4),
              ),
              const SizedBox(height: 4),
              Text(
                'The Proactive Engineering Sidekick',
                textAlign: TextAlign.center,
                style: NBText.bodySmall.copyWith(
                  color: const Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Welcome back! Let\'s lock in.'
                    : 'Create an account to start.',
                textAlign: TextAlign.center,
                style: NBText.body,
              ),
              const SizedBox(height: 32),

              // Inputs
              Text('EMAIL', style: NBText.label),
              const SizedBox(height: 8),
              NBInput(
                controller: _emailController,
                hintText: 'student@university.edu',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              Text('PASSWORD', style: NBText.label),
              const SizedBox(height: 8),
              NBInput(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 28),

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

              const SizedBox(height: 16),

              // Toggle sign in / sign up
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
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

              const SizedBox(height: 32),

              // ── DEMO MODE ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NBColors.purple.withValues(alpha: 0.1),
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                ),
                child: Column(
                  children: [
                    Text(
                      'HACKATHON DEMO',
                      style: NBText.label.copyWith(
                        fontSize: 10,
                        color: NBColors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skip login and explore all features with sample data',
                      textAlign: TextAlign.center,
                      style: NBText.bodySmall.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _enterDemoMode,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: NBColors.purple,
                          border: Border.all(color: NBColors.black, width: 2),
                          borderRadius: NBRadius.softAll,
                          boxShadow: NBShadows.small,
                        ),
                        child: Center(
                          child: Text(
                            '⚡ ENTER DEMO MODE',
                            style: NBText.label.copyWith(
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
