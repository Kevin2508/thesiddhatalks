import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../services/youtube_service.dart';
import '../widgets/youtube_playlist_carousel.dart';
import 'player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService();
  late AnimationController _fadeController;

  String _selectedCategory = 'All';
  List<YouTubeVideo> _allVideos = [];
  List<YouTubeVideo> _filteredVideos = [];
  List<PlaylistInfo> _playlists = [];
  Map<String, List<YouTubeVideo>> _categorizedVideos = {};

  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all playlists
      final playlists = await _youtubeService.getChannelPlaylists();

      // Load all recent uploads
      final uploads = await _youtubeService.getChannelUploads(maxResults: 50);

      // Categorize videos based on title and description
      final categorizedVideos = <String, List<YouTubeVideo>>{};

      for (final category in _categories) {
        if (category == 'All') continue;

        categorizedVideos[category] = uploads.where((video) {
          final videoCategory = VideoCategory.categorizeVideo(
              video.title,
              video.description
          );
          return videoCategory == category;
        }).toList();
      }

      setState(() {
        _playlists = playlists;
        _allVideos = uploads;
        _categorizedVideos = categorizedVideos;
        _filteredVideos = uploads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) {
      _filterContent('');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final searchResults = await _youtubeService.searchChannelVideos(
        query,
        maxResults: 30,
      );

      setState(() {
        _filteredVideos = searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      // Fall back to local search
      _filterContent(query);
    }
  }

  void _filterContent(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredVideos = _allVideos;
      } else {
        List<YouTubeVideo> videosToFilter = _selectedCategory == 'All'
            ? _allVideos
            : _categorizedVideos[_selectedCategory] ?? [];

        if (query.isEmpty) {
          _filteredVideos = videosToFilter;
        } else {
          _filteredVideos = videosToFilter.where((video) {
            return video.title.toLowerCase().contains(query.toLowerCase()) ||
                video.description.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Category Filter
              _buildCategoryFilter(),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
                    Text(
                      'Discover spiritual teachings and wisdom',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading || _isSearching)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (query) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == query) {
                  _searchVideos(query);
                }
              });
            },
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
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  _searchController.clear();
                  _filterContent('');
                },
              )
                  : null,
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
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          final videoCount = category == 'All'
              ? _allVideos.length
              : _categorizedVideos[category]?.length ?? 0;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (videoCount > 0)
                      Text(
                        '$videoCount',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final opacity = _fadeController.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: _filteredVideos.isEmpty
              ? _buildEmptyState()
              : _buildVideoGrid(),
        );
      },
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
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
          onTap: () => _playVideo(_filteredVideos[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No videos found',
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms\nor exploring different categories',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'All';
              });
              _filterContent('');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Show All Videos'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading spiritual content...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(YouTubeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(video: video),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class ExploreVideoCard extends StatefulWidget {
  final YouTubeVideo video;
  final int animationDelay;
  final VoidCallback onTap;

  const ExploreVideoCard({
    Key? key,
    required this.video,
    this.animationDelay = 0,
    required this.onTap,
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

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = VideoCategory.categorizeVideo(
        widget.video.title,
        widget.video.description
    );

    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        final opacity = _entranceAnimation.value.clamp(0.0, 1.0);
        final slideOffset = _slideAnimation.value.clamp(0.0, 30.0);

        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: Opacity(
            opacity: opacity,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                final scale = _scaleAnimation.value.clamp(0.9, 1.0);

                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (!mounted) return;
                      setState(() => _isPressed = true);
                      _pressController.forward();
                      HapticFeedback.lightImpact();
                    },
                    onTapUp: (_) {
                      if (!mounted) return;
                      setState(() => _isPressed = false);
                      _pressController.reverse();
                      widget.onTap();
                    },
                    onTapCancel: () {
                      if (!mounted) return;
                      setState(() => _isPressed = false);
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
                                : AppColors.shadowLight,
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
                          Expanded(
                            flex: 3,
                            child: YouTubeVideoCard(
                              video: widget.video,
                              onTap: widget.onTap,
                              showPlayButton: true,
                            ),
                          ),

                          // Content
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.lato(
                                        fontSize: 10,
                                        color: AppColors.primaryAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Title
                                  Expanded(
                                    child: Text(
                                      widget.video.title,
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Stats
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatViewCount(widget.video.viewCount),
                                          style: GoogleFonts.lato(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
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

  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$viewCount';
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    super.dispose();
  }
}