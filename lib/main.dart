import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/wisdom_screen.dart';
import 'screens/explore_screen.dart';
import 'utils/app_colors.dart';
import 'models/youtube_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better UX
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft, // Allow landscape for video player
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SiddhaTalkApp());
}

class SiddhaTalkApp extends StatelessWidget {
  const SiddhaTalkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Siddha Talks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        primaryColor: AppColors.primaryAccent,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryAccent,
          secondary: AppColors.secondaryAccent,
          surface: AppColors.surfaceBackground,
          background: AppColors.primaryBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onBackground: AppColors.textPrimary,
        ),
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.teko(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          headlineMedium: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          bodyLarge: GoogleFonts.lato(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.lato(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.shadowMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Add input decoration theme for consistent search bars
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        // Add card theme for consistency
        cardTheme: CardThemeData(
          color: AppColors.surfaceBackground,
          elevation: 4,
          shadowColor: AppColors.shadowLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _createRoute(const SplashScreen());
          case '/home':
            return _createRoute(const MainScreen());
          case '/player':
            final video = settings.arguments as YouTubeVideo?;
            return _createRoute(PlayerScreen(video: video));
          default:
            return _createRoute(const SplashScreen());
        }
      },
    );
  }

  // Custom route transition for smoother navigation
  Route<dynamic> _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _navBarController;
  late Animation<double> _navBarAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const WisdomScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'Explore',
    'Wisdom',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();
    _navBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _navBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navBarController,
      curve: Curves.easeInOut,
    ));

    // Start navigation bar animation
    _navBarController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for video player
    if (state == AppLifecycleState.paused) {
      // App is in background - pause any video playback
      _pauseVideoPlayback();
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      _resumeVideoPlayback();
    }
  }

  void _pauseVideoPlayback() {
    // This will be handled by the YouTube player controller
    // when the app goes to background
  }

  void _resumeVideoPlayback() {
    // This will be handled by the YouTube player controller
    // when the app comes back to foreground
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Provide haptic feedback
          HapticFeedback.selectionClick();
        },
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _navBarAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - _navBarAnimation.value)),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                    spreadRadius: 0,
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      _screens.length,
                          (index) => _buildNavItem(index),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.lightbulb_outline,
    ];
    final activeIcons = [
      Icons.home,
      Icons.explore,
      Icons.lightbulb,
    ];

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          HapticFeedback.lightImpact();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcons[index] : icons[index],
                key: ValueKey(isSelected),
                size: 28,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
              ),
              child: Text(_screenTitles[index]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _navBarController.dispose();
    super.dispose();
  }
}

// Global error handler for production
class AppErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    // Log error to analytics service (Firebase Crashlytics, etc.)
    debugPrint('App Error: $error');
    debugPrint('Stack Trace: $stackTrace');

    // In production, you might want to send this to a crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

// Custom exception for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Network connectivity helper
class NetworkHelper {
  static Future<bool> hasConnection() async {
    try {
      // You can implement actual network connectivity check here
      return true;
    } catch (e) {
      return false;
    }
  }
}