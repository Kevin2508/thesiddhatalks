import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/app_initialization_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();

    // Initialize app data in background
    _initializeAppData();

    // Wait for minimum splash duration
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _initializeAppData() async {
    try {
      print('🚀 Starting app data initialization...');
      final success = await AppInitializationService.initializeAppIfNeeded();
      
      if (success) {
        print('✅ App data initialization completed');
      } else {
        print('❌ App data initialization failed - will show sync screen');
      }
    } catch (e) {
      print('❌ App data initialization failed: $e');
      // Continue anyway - user can manually refresh later
    }
  }

  void _checkAuthAndNavigate() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check auth status and navigate accordingly
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case AuthStatus.unauthenticated:
        Navigator.of(context).pushReplacementNamed('/login');
        break;
      case AuthStatus.loading:
        // If still loading, wait a bit more and check again
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _checkAuthAndNavigate();
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppColors.surfaceBackground,
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final opacity = _fadeAnimation.value.clamp(0.0, 1.0);
                      final scale = _scaleAnimation.value.clamp(0.8, 1.0);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Column(
                            children: [
                              Container(
                                width: 250,
                                height: 250,
                                child: Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // App Name
                              Text(
                                'Siddha\nKutumbakam',
                                style: GoogleFonts.teko(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 2,

                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}