import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/hero_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/playlist_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start entrance animations after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: CustomScrollView(
          controller: _pageScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with Logo placeholder
            // App Bar with Logo placeholder
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.primaryBackground,
              elevation: 0,
              title: Row(
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 112,
                    height: 112,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  // Text(
                  //   'The Siddha Talks',
                  //   style: GoogleFonts.rajdhani(
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.bold,
                  //     color: AppColors.textPrimary,
                  //   ),
                  // ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  onPressed: () {
                    // Handle notifications
                  },
                ),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Greeting Section
                      _buildAnimatedSection(
                        interval: const Interval(0.0, 0.3, curve: Curves.easeOut),
                        child: const GreetingSection(),
                      ),

                      // Hero Card
                      _buildAnimatedSection(
                        interval: const Interval(0.2, 0.5, curve: Curves.easeOut),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: HeroCard(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Guided Meditations Carousel (restored previous UI)
                      _buildAnimatedSection(
                        interval: const Interval(0.4, 0.7, curve: Curves.easeOut),
                        child: _buildGuidedMeditationsCarousel(),
                      ),

                      // Bottom padding to ensure content doesn't overlap with navigation
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 80,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedMeditationsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header with See All button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guided Meditations',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to all meditations screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllMeditationsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal scrollable carousel (restored previous UI)
        PlaylistCarousel(
          title: '', // Empty title since we show it above
          videos: _getTopGuidedMeditations(),
          showTitle: false, // Don't show title in carousel
        ),
      ],
    );
  }

  Widget _buildAnimatedSection({
    required Interval interval,
    required Widget child,
  }) {
    final animation = CurvedAnimation(
      parent: _scrollController,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final opacity = animation.value.clamp(0.0, 1.0);
        final slideValue = (0.3 * (1 - animation.value)).clamp(0.0, 0.3);

        return FadeTransition(
          opacity: AlwaysStoppedAnimation(opacity),
          child: SlideTransition(
            position: AlwaysStoppedAnimation(Offset(0, slideValue)),
            child: child,
          ),
        );
      },
    );
  }

  List<VideoItem> _getTopGuidedMeditations() {
    return [
      VideoItem(
        id: '1',
        title: 'Morning Mindfulness',
        duration: '15:30',
        thumbnail: 'assets/images/meditation1.jpg',
        isNew: true,
      ),
      VideoItem(
        id: '2',
        title: 'Deep Breathing',
        duration: '10:45',
        thumbnail: 'assets/images/meditation2.jpg',
      ),
      VideoItem(
        id: '3',
        title: 'Body Scan',
        duration: '20:20',
        thumbnail: 'assets/images/meditation3.jpg',
      ),
      VideoItem(
        id: '4',
        title: 'Evening Peace',
        duration: '18:15',
        thumbnail: 'assets/images/meditation4.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }
}

class VideoItem {
  final String id;
  final String title;
  final String duration;
  final String thumbnail;
  final bool isNew;

  VideoItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnail,
    this.isNew = false,
  });
}

// All Meditations Screen with Search
class AllMeditationsScreen extends StatefulWidget {
  const AllMeditationsScreen({Key? key}) : super(key: key);

  @override
  State<AllMeditationsScreen> createState() => _AllMeditationsScreenState();
}

class _AllMeditationsScreenState extends State<AllMeditationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MeditationItem> _allMeditations = [];
  List<MeditationItem> _filteredMeditations = [];

  @override
  void initState() {
    super.initState();
    _allMeditations = _getAllMeditations();
    _filteredMeditations = _allMeditations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'All Meditations',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMeditations,
              style: GoogleFonts.lato(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search meditations...',
                hintStyle: GoogleFonts.lato(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
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
            ),
          ),

          // Meditations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredMeditations.length,
              itemBuilder: (context, index) {
                final meditation = _filteredMeditations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MeditationListItem(meditation: meditation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _filterMeditations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMeditations = _allMeditations;
      } else {
        _filteredMeditations = _allMeditations.where((meditation) {
          return meditation.title.toLowerCase().contains(query.toLowerCase()) ||
              meditation.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  List<MeditationItem> _getAllMeditations() {
    return [
      MeditationItem(
        id: '1',
        title: 'Morning Mindfulness',
        duration: '15:30',
        description: 'Start your day with peaceful awareness',
        thumbnail: 'assets/images/meditation1.jpg',
        isNew: true,
      ),
      MeditationItem(
        id: '2',
        title: 'Deep Breathing Exercise',
        duration: '10:45',
        description: 'Connect with your breath and find calm',
        thumbnail: 'assets/images/meditation2.jpg',
      ),
      MeditationItem(
        id: '3',
        title: 'Body Scan Meditation',
        duration: '20:20',
        description: 'Release tension and relax completely',
        thumbnail: 'assets/images/meditation3.jpg',
      ),
      MeditationItem(
        id: '4',
        title: 'Evening Peace',
        duration: '18:15',
        description: 'Wind down and prepare for restful sleep',
        thumbnail: 'assets/images/meditation4.jpg',
      ),
      MeditationItem(
        id: '5',
        title: 'Walking Meditation',
        duration: '12:30',
        description: 'Mindful movement and awareness',
        thumbnail: 'assets/images/meditation5.jpg',
      ),
      MeditationItem(
        id: '6',
        title: 'Loving Kindness',
        duration: '18:45',
        description: 'Cultivate compassion and love',
        thumbnail: 'assets/images/meditation6.jpg',
      ),
      MeditationItem(
        id: '7',
        title: 'Stress Relief',
        duration: '14:20',
        description: 'Release tension and find peace',
        thumbnail: 'assets/images/meditation7.jpg',
      ),
      MeditationItem(
        id: '8',
        title: 'Focus Enhancement',
        duration: '16:15',
        description: 'Improve concentration and clarity',
        thumbnail: 'assets/images/meditation8.jpg',
      ),
      MeditationItem(
        id: '9',
        title: 'Anxiety Relief',
        duration: '13:40',
        description: 'Calm your mind and ease anxious thoughts',
        thumbnail: 'assets/images/meditation9.jpg',
      ),
      MeditationItem(
        id: '10',
        title: 'Gratitude Practice',
        duration: '11:25',
        description: 'Cultivate appreciation and positive mindset',
        thumbnail: 'assets/images/meditation10.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class MeditationItem {
  final String id;
  final String title;
  final String duration;
  final String description;
  final String thumbnail;
  final bool isNew;

  MeditationItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.description,
    required this.thumbnail,
    this.isNew = false,
  });
}

class MeditationListItem extends StatefulWidget {
  final MeditationItem meditation;

  const MeditationListItem({
    Key? key,
    required this.meditation,
  }) : super(key: key);

  @override
  State<MeditationListItem> createState() => _MeditationListItemState();
}

class _MeditationListItemState extends State<MeditationListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        Navigator.of(context).pushNamed('/player');
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? AppColors.shadowMedium
                  : AppColors.shadowLight,
              blurRadius: _isPressed ? 15 : 8,
              offset: Offset(0, _isPressed ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (widget.meditation.isNew)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.meditation.title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          widget.meditation.duration,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.meditation.description,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Play button
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}