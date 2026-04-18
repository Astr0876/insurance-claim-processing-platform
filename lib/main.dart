import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/neubrut_tokens.dart';
import 'core/utils/constants.dart';
import 'app/app_shell.dart';
import 'features/study_hub/services/hub_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: NBColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LuminaApp());
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // DEV TIP: Change this to 'true' to skip the splash screen entirely
    const bool skipSplash = false;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..initialize()),
        ChangeNotifierProvider(create: (_) => HubService()),
      ],
      child: MaterialApp(
        title: 'LockIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: skipSplash ? const AppShell() : const SplashScreen(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Neubrutalism Splash Screen
// ─────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const AppShell(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo box ────────────────────────────────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: NBColors.primary,
                        border: Border.all(color: NBColors.black, width: 3),
                        borderRadius: NBRadius.softAll,
                        boxShadow: NBShadows.large,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: NBColors.black,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: NBSpacing.xl),

                    // ── App name ─────────────────────────────────────
                    Text(
                      'LUMINA',
                      style: NBText.heading1.copyWith(letterSpacing: 6),
                    ),
                    const SizedBox(height: NBSpacing.sm),

                    // ── Tagline ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NBSpacing.md,
                        vertical: NBSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: NBColors.primary,
                        border: Border.all(color: NBColors.black, width: 2),
                        borderRadius: NBRadius.softAll,
                      ),
                      child: Text(
                        'Your Proactive Student Sidekick',
                        style: NBText.label.copyWith(
                          color: NBColors.black,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: NBSpacing.xxl),

                    // ── Loading dots ─────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i % 2 == 0 ? NBColors.black : NBColors.primary,
                            border: Border.all(color: NBColors.black, width: 2),
                            borderRadius: NBRadius.softAll,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
