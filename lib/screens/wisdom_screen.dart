import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class WisdomScreen extends StatefulWidget {
  const WisdomScreen({Key? key}) : super(key: key);

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  int _currentIndex = 0;

  final List<MahaVakyaItem> _mahaVakyas = [
    MahaVakyaItem(
      number: 1,
      hindi: 'सबका मंगल हो। सबका कल्याण हो।',
      english: 'May there be mangal (auspiciousness) for all. May there be kalyan (spiritual well-being) for all.',
    ),
    MahaVakyaItem(
      number: 2,
      hindi: 'परमात्मा को छुआ नहीं जा सकता, परमात्मा हुआ जा सकता है।',
      english: 'Paramatma cannot be grasped by mind or senses — It is only known by becoming one with it.',
    ),
    MahaVakyaItem(
      number: 3,
      hindi: 'करने वाले सब बिगाड़ देते है, बिना किए सब ठीक हो जाता है।',
      english: 'Doing creates disorder; in non-doing, there is harmony.',
    ),
    MahaVakyaItem(
      number: 4,
      hindi: 'प्रकृति परमात्मा का सौम्या द्वार है।',
      english: 'Prakriti (Nature) is the gentle doorway to the Paramatma.',
    ),
    MahaVakyaItem(
      number: 5,
      hindi: 'चुनाव रहित जानना और निर्विकल्प बोध ध्यान की अनिवार्यता है।',
      english: 'Choiceless Awareness with Effortless Knowing are essential for dhyana.',
    ),
    MahaVakyaItem(
      number: 6,
      hindi: 'सब हो रहा है और युगपत् जाना भी जा रहा है | होना जानना अलग-अलग घटना नहीं है ।',
      english: 'Everything is happening, being known simultaneously. There is no duality. This is Dhyana.',
    ),
    MahaVakyaItem(
      number: 7,
      hindi: 'सृष्टा ने सृष्टि नहीं बनाई, सृष्टा स्वयं सृष्ट हो रहा है।',
      english: 'The Srishta (Creator) did not create the Srishti (creation). The Creator is continuously manifesting itself as a creation.',
    ),
    MahaVakyaItem(
      number: 8,
      hindi: 'परम स्वीकार परम धर्म : अर्थात् चेतना फैलकर असीम हो गई; अनंत हो गई',
      english: 'Param Swikar (Supreme acceptance) is the supreme dharma: i.e. when consciousness becomes infinite & boundless.',
    ),
    MahaVakyaItem(
      number: 9,
      hindi: 'होश एक ऐसी चाबी है जिससे सारे ताले खुल जाते हैं।',
      english: 'Hosh — awakened awareness — unfolds all hidden truths.',
    ),
    MahaVakyaItem(
      number: 10,
      hindi: 'ध्यान यदि राम है तो concentration रावण है।',
      english: 'If dhyana is Ram, then mere concentration is Ravan — one embodies grace, the other clings to control.',
    ),
    MahaVakyaItem(
      number: 11,
      hindi: 'ध्यान किया नहीं जाता, ध्यान एक happening है, ध्यान घटता है। परमात्मा की grace है।',
      english: 'Dhyana cannot be done — its a happening. It descends — a flowering, a grace of Paramatma.',
    ),
    MahaVakyaItem(
      number: 12,
      hindi: 'ध्यान की कोई विधियाँ नहीं हैं; बल्कि ध्यान के लिए विधियाँ हैं।',
      english: 'There are no methods of meditation; rather, there are methods for meditation.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _mahaVakyas.length,
                itemBuilder: (context, index) {
                  return _buildMahaVakyaCard(_mahaVakyas[index]);
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Maha Vakya',
                  style: GoogleFonts.teko(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildMahaVakyaCard(MahaVakyaItem vakya) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.orange.shade50,
              Colors.amber.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.primaryAccent.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primaryAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${vakya.number}',
                  style: GoogleFonts.teko(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ),
                  
                  const SizedBox(height: 16),
                  
                  // Hindi Quote Text
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        vakya.hindi,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0c6386),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: null, // Allow unlimited lines
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // English Quote Text
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        vakya.english,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 168, 127, 56),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: null, // Allow unlimited lines
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 0),
                  
            // Language indicator
              
      
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_mahaVakyas.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == index 
                    ? AppColors.primaryAccent 
                    : AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // Navigation buttons
          Row(
            children: [
              // Previous button
              Expanded(
                child: GestureDetector(
                  onTap: _currentIndex > 0 ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    HapticFeedback.lightImpact();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _currentIndex > 0 
                        ? AppColors.surfaceBackground 
                        : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _currentIndex > 0 
                          ? AppColors.primaryAccent.withOpacity(0.3) 
                          : AppColors.textSecondary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: _currentIndex > 0 
                            ? AppColors.primaryAccent 
                            : AppColors.textSecondary.withOpacity(0.5),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Previous',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _currentIndex > 0 
                              ? AppColors.primaryAccent 
                              : AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Next button
              Expanded(
                child: GestureDetector(
                  onTap: _currentIndex < _mahaVakyas.length - 1 ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    HapticFeedback.lightImpact();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _currentIndex < _mahaVakyas.length - 1 
                        ? AppColors.primaryAccent 
                        : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _currentIndex < _mahaVakyas.length - 1 
                              ? Colors.white 
                              : AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _currentIndex < _mahaVakyas.length - 1 
                            ? Colors.white 
                            : AppColors.textSecondary.withOpacity(0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class MahaVakyaItem {
  final int number;
  final String hindi;
  final String english;

  MahaVakyaItem({
    required this.number,
    required this.hindi,
    required this.english,
  });
}
