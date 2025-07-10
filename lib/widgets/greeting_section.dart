import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/meditation_quotes.dart';

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
  int _currentQuoteIndex = 0;
  List<Map<String, String>> _dailyQuotes = [];

  @override
  void initState() {
    super.initState();
    _dailyQuotes = MeditationQuotes.getDailyQuotes();
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

    // Start auto-swiping quotes
    _startAutoSwipe();
    _fadeController.forward();
  }

  void _startAutoSwipe() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextQuote();
      }
    });
  }

  void _nextQuote() {
    if (!mounted) return;

    setState(() {
      _currentQuoteIndex = (_currentQuoteIndex + 1) % _dailyQuotes.length;
    });

    _pageController.animateToPage(
      _currentQuoteIndex,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );

    // Schedule next quote
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextQuote();
      }
    });
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time-based greeting with reduced font size
          Text(
            _getTimeBasedGreeting(),
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Today's Wisdom with auto-swiping quotes
          Container(
            width: double.infinity,
            height: 200, // Fixed height for consistent UI
            padding: const EdgeInsets.all(20),
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
                Row(
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
                    Text(
                      'Today\'s Wisdom',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Quote indicator dots
                    Row(
                      children: List.generate(
                        _dailyQuotes.length,
                            (index) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: index == _currentQuoteIndex
                                ? AppColors.primaryAccent
                                : AppColors.textSecondary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Auto-swiping quotes
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuoteIndex = index;
                      });
                    },
                    itemCount: _dailyQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = _dailyQuotes[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              quote['hindi']!,
                              style: GoogleFonts.tiroDevanagariHindi(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.meditationGold,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              quote['english']!,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              ],
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