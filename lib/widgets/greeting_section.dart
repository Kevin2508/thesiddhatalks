import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';

class GreetingSection extends StatefulWidget {
  const GreetingSection({Key? key}) : super(key: key);

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentImageIndex = 0;
  List<Map<String, String>> _dailyQuoteImages = [];

  @override
  void initState() {
    super.initState();
    _dailyQuoteImages = _getDailyQuoteImages();
    _pageController = PageController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start auto-swiping images
    _startAutoSwipe();
    _fadeController.forward();
  }

  List<Map<String, String>> _getDailyQuoteImages() {
    // Get current day of year to determine which quote to show
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    // List of quote image pairs (you can expand this list)
    final allQuoteImages = [
      {
        'hindi': 'assets/quotes/quote1_hindi.jpeg',
        'english': 'assets/quotes/quote1_english.jpeg',
        'title': 'Inner Peace',
      },
      {
        'hindi': 'assets/quotes/quote2_hindi.jpeg',
        'english': 'assets/quotes/quote2_english.jpeg',
        'title': 'Meditation',
      },
      {
        'hindi': 'assets/quotes/quote3_hindi.jpeg',
        'english': 'assets/quotes/quote3_english.jpeg',
        'title': 'Wisdom',
      },
      {
        'hindi': 'assets/quotes/quote4_hindi.jpeg',
        'english': 'assets/quotes/quote4_english.jpeg',
        'title': 'Mindfulness',
      },
      {
        'hindi': 'assets/quotes/quote5_hindi.jpeg',
        'english': 'assets/quotes/quote5_english.jpeg',
        'title': 'Enlightenment',
      },
      
      // Add more quote image pairs as needed
    ];

    // Select quote based on day of year (cycles through available quotes)
    final selectedQuoteIndex = (dayOfYear - 1) % allQuoteImages.length;
    final selectedQuote = allQuoteImages[selectedQuoteIndex];

    // Return both Hindi and English images for today's quote
    return [
      {
        'image': selectedQuote['hindi']!,
        'language': 'Hindi',
        'title': selectedQuote['title']!,
      },
      {
        'image': selectedQuote['english']!,
        'language': 'English',
        'title': selectedQuote['title']!,
      },
    ];
  }

  void _startAutoSwipe() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _nextImage();
      }
    });
  }

  void _nextImage() {
    if (!mounted) return;

    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _dailyQuoteImages.length;
    });

    _pageController.animateToPage(
      _currentImageIndex,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );

    // Schedule next image
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _nextImage();
      }
    });
  }

  String _getGreetingWithUsername(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final timeGreeting = _getTimeBasedGreeting();
    
    // First try to get display name from Firestore user data
    final displayName = authProvider.user?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return '$timeGreeting, $displayName';
    }
    
    // If Firestore user data is not available, try Firebase user data
    final firebaseUser = authProvider.firebaseUser;
    if (firebaseUser != null) {
      final firebaseDisplayName = firebaseUser.displayName;
      if (firebaseDisplayName != null && firebaseDisplayName.isNotEmpty) {
        return '$timeGreeting, $firebaseDisplayName';
      }
      
      // Extract name from Firebase user email if display name is not available
      final firebaseEmail = firebaseUser.email;
      if (firebaseEmail != null && firebaseEmail.isNotEmpty) {
        final emailName = firebaseEmail.split('@')[0];
        if (emailName.isNotEmpty) {
          final capitalizedName = emailName[0].toUpperCase() + emailName.substring(1);
          return '$timeGreeting, $capitalizedName';
        }
      }
    }
    
    // Fallback to Firestore user email if available
    final email = authProvider.user?.email;
    if (email != null && email.isNotEmpty) {
      // Extract name from email (before @)
      final emailName = email.split('@')[0];
      if (emailName.isNotEmpty) {
        final capitalizedName = emailName[0].toUpperCase() + emailName.substring(1);
        return '$timeGreeting, $capitalizedName';
      }
    }
    
    return timeGreeting;
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time-based greeting with username
          Container(
            width: double.infinity,
            child: Text(
              _getGreetingWithUsername(context),
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Today's Wisdom with auto-swiping quote images
          Container(
            width: double.infinity,
            height: 380, // Increased height for better image display
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryAccent.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Wisdom',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            
                          ],
                        ),
                      ),
                      // Language indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dailyQuoteImages.isNotEmpty
                              ? _dailyQuoteImages[_currentImageIndex]['language']!
                              : 'EN',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Auto-swiping quote images
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: _dailyQuoteImages.length,
                        itemBuilder: (context, index) {
                          final quoteImage = _dailyQuoteImages[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildQuoteImage(quoteImage),
                            ),
                          );
                        },
                      ),

                      // Image indicator dots
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _dailyQuoteImages.length,
                                (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == _currentImageIndex
                                    ? AppColors.primaryAccent
                                    : Colors.white.withOpacity(0.4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (index == _currentImageIndex)
                                    BoxShadow(
                                      color: AppColors.primaryAccent.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteImage(Map<String, String> quoteImage) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          quoteImage['image']!,
          fit: BoxFit.contain, // Changed from cover to contain
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(quoteImage);
          },
        ),
      ),
    );
  }
  Widget _buildPlaceholder(Map<String, String> quoteImage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withOpacity(0.1),
            AppColors.primaryAccent.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote,
              size: 32,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quote Image',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${quoteImage['language']} • ${quoteImage['title']}',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Image not available',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}