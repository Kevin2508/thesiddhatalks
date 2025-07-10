import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  String _selectedCategory = 'All';
  List<VideoItem> _allVideos = [];
  List<VideoItem> _filteredVideos = [];

  final List<String> _categories = [
    'All',
    'Meditation',
    'Philosophy',
    'Daily Wisdom',
    'Discourses',
    'Q&A Sessions',
  ];

  @override
  void initState() {
    super.initState();
    _allVideos = _getAllVideos();
    _filteredVideos = _allVideos;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: GoogleFonts.teko(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover spiritual teachings and wisdom',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _filterContent,
                    style: GoogleFonts.lato(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search teachings...',
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
                ],
              ),
            ),

            // Category Filter
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _categories.length - 1 ? 0 : 12,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCategory = category;
                        });
                        _filterContent(_searchController.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent
                              : AppColors.surfaceBackground,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Content Grid
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  // Clamp the opacity value to ensure it's within valid range
                  final opacity = _fadeController.value.clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredVideos.length,
                      itemBuilder: (context, index) {
                        return ExploreVideoCard(
                          video: _filteredVideos[index],
                          animationDelay: index * 50,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterContent(String query) {
    setState(() {
      _filteredVideos = _allVideos.where((video) {
        final matchesCategory = _selectedCategory == 'All' ||
            video.category == _selectedCategory;
        final matchesSearch = query.isEmpty ||
            video.title.toLowerCase().contains(query.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  List<VideoItem> _getAllVideos() {
    return [
      VideoItem(
        id: '1',
        title: 'Morning Mindfulness Practice',
        duration: '15:30',
        thumbnail: 'assets/images/meditation1.jpg',
        category: 'Meditation',
        isNew: true,
      ),
      VideoItem(
        id: '2',
        title: 'The Nature of Reality',
        duration: '45:20',
        thumbnail: 'assets/images/philosophy1.jpg',
        category: 'Philosophy',
      ),
      VideoItem(
        id: '3',
        title: 'Breath Awareness Technique',
        duration: '22:45',
        thumbnail: 'assets/images/meditation2.jpg',
        category: 'Meditation',
      ),
      VideoItem(
        id: '4',
        title: 'Daily Spiritual Insight',
        duration: '8:15',
        thumbnail: 'assets/images/wisdom1.jpg',
        category: 'Daily Wisdom',
      ),
      VideoItem(
        id: '5',
        title: 'Understanding Consciousness',
        duration: '52:30',
        thumbnail: 'assets/images/discourse1.jpg',
        category: 'Discourses',
      ),
      VideoItem(
        id: '6',
        title: 'Questions on Inner Peace',
        duration: '35:10',
        thumbnail: 'assets/images/qa1.jpg',
        category: 'Q&A Sessions',
      ),
      VideoItem(
        id: '7',
        title: 'Walking Meditation Guide',
        duration: '18:45',
        thumbnail: 'assets/images/meditation3.jpg',
        category: 'Meditation',
      ),
      VideoItem(
        id: '8',
        title: 'The Path of Self-Inquiry',
        duration: '41:20',
        thumbnail: 'assets/images/philosophy2.jpg',
        category: 'Philosophy',
      ),
      VideoItem(
        id: '9',
        title: 'Evening Reflection',
        duration: '12:30',
        thumbnail: 'assets/images/wisdom2.jpg',
        category: 'Daily Wisdom',
        isNew: true,
      ),
      VideoItem(
        id: '10',
        title: 'The Science of Meditation',
        duration: '38:15',
        thumbnail: 'assets/images/discourse2.jpg',
        category: 'Discourses',
      ),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Extended VideoItem class to include category
class VideoItem {
  final String id;
  final String title;
  final String duration;
  final String thumbnail;
  final String category;
  final bool isNew;

  VideoItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnail,
    required this.category,
    this.isNew = false,
  });
}

class ExploreVideoCard extends StatefulWidget {
  final VideoItem video;
  final int animationDelay;

  const ExploreVideoCard({
    Key? key,
    required this.video,
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  State<ExploreVideoCard> createState() => _ExploreVideoCardState();
}

class _ExploreVideoCardState extends State<ExploreVideoCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pressController;
  late Animation<double> _entranceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(_entranceAnimation);

    // Start entrance animation with delay and proper bounds checking
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        // Ensure opacity and slide values are within valid ranges
        final opacity = _entranceAnimation.value.clamp(0.0, 1.0);
        final slideOffset = _slideAnimation.value.clamp(0.0, 30.0);

        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: Opacity(
            opacity: opacity,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                // Ensure scale value is within valid range
                final scale = _scaleAnimation.value.clamp(0.8, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (!mounted) return;
                      setState(() {
                        _isPressed = true;
                      });
                      _pressController.forward();
                      HapticFeedback.lightImpact();
                    },
                    onTapUp: (_) {
                      if (!mounted) return;
                      setState(() {
                        _isPressed = false;
                      });
                      _pressController.reverse();
                      Navigator.of(context).pushNamed('/player');
                    },
                    onTapCancel: () {
                      if (!mounted) return;
                      setState(() {
                        _isPressed = false;
                      });
                      _pressController.reverse();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _isPressed
                                ? AppColors.primaryAccent.withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            blurRadius: _isPressed ? 15 : 8,
                            spreadRadius: _isPressed ? 2 : 0,
                            offset: Offset(0, _isPressed ? 4 : 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBackground,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  size: 50,
                                  color: Colors.black54,
                                ),
                              ),

                              // Category Badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBackground.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.video.category,
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Duration
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.video.duration,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // New Badge
                              if (widget.video.isNew)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'NEW',
                                      style: GoogleFonts.lato(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.video.title,
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.play_arrow,
                                        size: 16,
                                        color: AppColors.primaryAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Watch',
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          color: AppColors.primaryAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    super.dispose();
  }
}