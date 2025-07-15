import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';

class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _underlineController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _underlineAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _underlineController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _underlineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _underlineController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _underlineController.forward();

    // Wait for animations to complete and then navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.displayName != null && user!.displayName.isNotEmpty
            ? user.displayName.split(' ').first 
            : 'User';

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  AppColors.meditationGold.withOpacity(0.1),
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
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Namaste greeting
                              Text(
                                'नमस्ते',
                                style: GoogleFonts.tiroDevanagariHindi(
                                  fontSize: 82,
                                  color: AppColors.meditationGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Username with animated underline
                              Stack(
                                children: [
                                  Text(
                                    userName,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 62,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  // Animated underline
                                  Positioned(
                                    bottom: -8,
                                    left: 0,
                                    child: AnimatedBuilder(
                                      animation: _underlineAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          height: 3,
                                          width: _getTextWidth(userName) * _underlineAnimation.value,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primaryAccent,
                                                AppColors.meditationGold,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryAccent.withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),    
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.rajdhani(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    
    return textPainter.size.width;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _underlineController.dispose();
    super.dispose();
  }
}
