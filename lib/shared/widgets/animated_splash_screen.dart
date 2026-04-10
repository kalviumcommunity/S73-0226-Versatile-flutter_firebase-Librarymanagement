import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../firebase_options.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_wrapper.dart';
import '../../features/books/providers/book_provider.dart';
import '../../features/library/providers/library_provider.dart';
import '../../features/borrow/providers/borrow_provider.dart';
import '../../features/borrow/providers/borrow_transaction_provider.dart';
import '../../features/reservations/providers/reservation_provider.dart';
import '../providers/location_provider.dart';
import '../providers/cross_library_search_provider.dart';
import '../../features/reservations/services/reservation_expiry_service.dart';

/// Animated splash screen that plays immediately on app start.
/// Firebase and auth initialize in the background. Once both the
/// minimum animation time (2.5s) AND Firebase are ready, it
/// navigates to the main app with a fade transition.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  // Logo animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoOpacity;

  // Icon inside logo
  late final Animation<double> _iconSlide;

  // Text animations (staggered)
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  // Loader animation
  late final Animation<double> _loaderOpacity;

  // Decorative particles
  late final Animation<double> _particleOpacity;

  // Continuous pulse on logo
  late final Animation<double> _pulse;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Main entrance animation (2s for smoother stagger)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Continuous pulse (loops)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Shimmer effect on text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _setupAnimations();

    // Start animation on the very next frame to avoid any jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward().then((_) {
        if (mounted) {
          _pulseController.repeat(reverse: true);
          _shimmerController.repeat();
        }
      });
    });

    // Initialize Firebase in background while animation plays
    _initializeAndNavigate();
  }

  /// Run Firebase init and a minimum splash timer in parallel.
  /// Navigate only after BOTH complete.
  Future<void> _initializeAndNavigate() async {
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => BookProvider()),
            ChangeNotifierProvider(create: (_) => LibraryProvider()),
            ChangeNotifierProvider(create: (_) => BorrowProvider()),
            ChangeNotifierProvider(create: (_) => BorrowTransactionProvider()),
            ChangeNotifierProvider(create: (_) => ReservationProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProxyProvider<LocationProvider, CrossLibrarySearchProvider>(
              create: (context) => CrossLibrarySearchProvider(
                Provider.of<LocationProvider>(context, listen: false),
              ),
              update: (context, locationProvider, previous) =>
                  previous ?? CrossLibrarySearchProvider(locationProvider),
            ),
          ],
          child: Builder(
            builder: (context) {
              // Initialize reservation expiry service
              ReservationExpiryService().start();
              
              return MaterialApp(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                themeMode: ThemeMode.dark,
                home: const AuthWrapper(),
              );
            },
          ),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _setupAnimations() {
    // Logo: scale from 0 → overshoot → settle
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));

    // Logo: subtle rotation snap
    _logoRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.03), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    ));

    // Icon slides up inside the logo box
    _iconSlide = Tween(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.05, 0.4, curve: Curves.easeOutCubic),
    ));

    // App name: fade + slide up
    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.28, 0.5, curve: Curves.easeOut),
    ));
    _nameSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.28, 0.55, curve: Curves.easeOutCubic),
    ));

    // Tagline: fade + slide up
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.42, 0.65, curve: Curves.easeOut),
    ));
    _taglineSlide = Tween(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.42, 0.7, curve: Curves.easeOutCubic),
    ));

    // Loader dots: fade in at the end
    _loaderOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.65, 0.9, curve: Curves.easeIn),
    ));

    // Decorative particles
    _particleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    ));

    // Continuous pulse — subtle
    _pulse = Tween(begin: 1.0, end: 1.04).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackground(context);
    final primaryColor = AppColors.getPrimary(context);
    final primaryLightColor = AppColors.getPrimaryLight(context);
    final accentColor = AppColors.getAccent(context);
    final textPrimaryColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _shimmerController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // Background gradient orbs
              _buildBackgroundOrbs(primaryLightColor, accentColor),

              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo ──
                    _buildLogo(primaryColor, accentColor),

                    const SizedBox(height: 28),

                    // ── App Name ──
                    _buildAppName(textPrimaryColor, primaryLightColor),

                    const SizedBox(height: 10),

                    // ── Tagline ──
                    _buildTagline(textSecondaryColor),

                    const SizedBox(height: 48),

                    // ── Loading indicator ──
                    _buildLoader(),
                  ],
                ),
              ),

              // Floating particles
              _buildParticles(primaryLightColor, accentColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundOrbs(Color primaryLightColor, Color accentColor) {
    return Positioned.fill(
      child: Opacity(
        opacity: _particleOpacity.value * 0.5,
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryLightColor.withOpacity(0.15),
                      primaryLightColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Color primaryColor, Color accentColor) {
    return Opacity(
      opacity: _logoOpacity.value,
      child: Transform.scale(
        scale: _logoScale.value * _pulse.value,
        child: Transform.rotate(
          angle: _logoRotation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  accentColor,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 45,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Transform.translate(
              offset: Offset(0, _iconSlide.value),
              child: const Icon(
                Icons.local_library_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName(Color textPrimaryColor, Color primaryLightColor) {
    return SlideTransition(
      position: _nameSlide,
      child: Opacity(
        opacity: _nameOpacity.value,
        child: ShaderMask(
          shaderCallback: (bounds) {
            final shimmerPos = _shimmerController.value * 3 - 1;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                textPrimaryColor,
                primaryLightColor,
                textPrimaryColor,
              ],
              stops: [
                (shimmerPos - 0.3).clamp(0.0, 1.0),
                shimmerPos.clamp(0.0, 1.0),
                (shimmerPos + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
              color: textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(Color textSecondaryColor) {
    return SlideTransition(
      position: _taglineSlide,
      child: Opacity(
        opacity: _taglineOpacity.value,
        child: Text(
          AppStrings.appTagline,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textSecondaryColor.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Opacity(
      opacity: _loaderOpacity.value,
      child: _BouncingDots(),
    );
  }

  Widget _buildParticles(Color primaryLightColor, Color accentColor) {
    return Opacity(
      opacity: _particleOpacity.value,
      child: IgnorePointer(
        child: Stack(
          children: List.generate(6, (i) {
            final rng = math.Random(i * 42);
            final size = 4.0 + rng.nextDouble() * 4;
            final left = rng.nextDouble() * MediaQuery.of(context).size.width;
            final top = 120.0 + rng.nextDouble() * (MediaQuery.of(context).size.height - 300);
            final opacity = 0.15 + rng.nextDouble() * 0.25;
            return Positioned(
              left: left,
              top: top,
              child: Transform.translate(
                offset: Offset(
                  0,
                  math.sin(_shimmerController.value * 2 * math.pi + i) * 8,
                ),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (i.isEven ? primaryLightColor : accentColor)
                        .withOpacity(opacity),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Three dots that bounce in sequence.
class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getPrimary(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
          // Bounce curve: fast up, slow down
          final bounce = t < 0.5
              ? math.sin(t * math.pi) * 8
              : math.sin(t * math.pi) * 8 * 0.3;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.translate(
              offset: Offset(0, -bounce),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.4 + t * 0.4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
