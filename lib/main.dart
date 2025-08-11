import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/splash_screen.dart';
import 'screens/initial_sync_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/wisdom_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/watchlist_screen.dart';
import 'utils/app_colors.dart';
import 'models/youtube_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Auth Service
    await AuthService().initialize();

    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue anyway, but with error handling
  }

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

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    AppErrorHandler.handleError(details.exception, details.stack ?? StackTrace.current);
  };

  runApp(const SiddhaTalkApp());
}

class SiddhaTalkApp extends StatelessWidget {
  const SiddhaTalkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print('Creating AuthProvider...');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print('Creating VideoProvider...');
            return VideoProvider();
          },
        ),
      ],
      child: MaterialApp(
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
            case '/initial-sync':
              return _createRoute(const InitialSyncScreen());
            case '/auth':
              return _createRoute(const AuthWrapper());
            case '/login':
              return _createRoute(const LoginScreen());
            case '/signup':
              return _createRoute(const SignUpScreen());
            case '/home':
              return _createRoute(const MainScreen());
            case '/main':
              return _createRoute(const MainScreen());
            case '/player':
              final video = settings.arguments as YouTubeVideo?;
              return _createRoute(PlayerScreen(video: video));
            case '/profile':
              return _createRoute(const ProfileScreen());
            default:
              return _createRoute(const SplashScreen());
          }
        },
      ),
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
    const WatchlistScreen(),
    const WisdomScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'Explore',
    'Watchlist',
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(authProvider),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
      },
    );
  }

  PreferredSizeWidget? _buildAppBar(AuthProvider authProvider) {
    // Only show app bar on specific screens or when needed
    if (_currentIndex == 0) return null; // Home screen has its own app bar

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        _screenTitles[_currentIndex],
        style: GoogleFonts.rajdhani(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // User profile button
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                backgroundImage: authProvider.user?.photoURL != null
                    ? NetworkImage(authProvider.user!.photoURL!)
                    : null,
                child: authProvider.user?.photoURL == null
                    ? Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.primaryAccent,
                )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.bookmark_border,
      Icons.lightbulb_outline,
    ];
    final activeIcons = [
      Icons.home,
      Icons.explore,
      Icons.bookmark,
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
          horizontal: 12,
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
                size: 26,
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
      // For example, using connectivity_plus package
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Authentication state management helper
class AuthStateManager {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static void setInitialized() {
    _isInitialized = true;
  }

  static void reset() {
    _isInitialized = false;
  }
}

// App constants for authentication
class AuthConstants {
  static const String userCollectionPath = 'users';
  static const String recentlyPlayedKey = 'recently_played_videos';
  static const String userPreferencesKey = 'user_preferences';
  static const String rememberMeKey = 'remember_me';

  // Error messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
}

// User preferences model
class UserPreferences {
  final bool darkMode;
  final bool notifications;
  final String language;
  final double playbackSpeed;
  final bool autoplay;

  UserPreferences({
    this.darkMode = false,
    this.notifications = true,
    this.language = 'en',
    this.playbackSpeed = 1.0,
    this.autoplay = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'notifications': notifications,
      'language': language,
      'playbackSpeed': playbackSpeed,
      'autoplay': autoplay,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['darkMode'] ?? false,
      notifications: json['notifications'] ?? true,
      language: json['language'] ?? 'en',
      playbackSpeed: json['playbackSpeed'] ?? 1.0,
      autoplay: json['autoplay'] ?? false,
    );
  }
}

// App lifecycle manager for handling authentication persistence
class AppLifecycleManager {
  static DateTime? _lastActiveTime;
  static const Duration _sessionTimeout = Duration(hours: 24);

  static void updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  static bool shouldRequireReauth() {
    if (_lastActiveTime == null) return true;

    final timeSinceActive = DateTime.now().difference(_lastActiveTime!);
    return timeSinceActive > _sessionTimeout;
  }

  static void clearSession() {
    _lastActiveTime = null;
  }
}