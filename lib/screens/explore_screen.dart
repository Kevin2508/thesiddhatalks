import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../services/optimized_youtube_service.dart';
import '../services/app_initialization_service.dart';
import 'player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final OptimizedYouTubeService _youtubeService = OptimizedYouTubeService();
  late AnimationController _fadeController;

  // Session-level cache to prevent repeated loading
  static List<String>? _sessionCategories;
  static List<YouTubeVideo>? _sessionAllVideos;
  static Map<String, List<YouTubeVideo>>? _sessionCategorizedVideos;

  String _selectedCategory = 'All';
  List<YouTubeVideo> _allVideos = [];
  List<YouTubeVideo> _filteredVideos = [];
  Map<String, List<YouTubeVideo>> _categorizedVideos = {};
  List<String> _categories = ['All'];

  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkInitializationAndLoad();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _checkInitializationAndLoad() async {
    // Check if app is initialized in current session
    if (AppInitializationService.isSessionInitialized) {
      print('✅ Session already initialized');
      
      // Check if we have session-cached data
      if (_sessionCategories != null && 
          _sessionAllVideos != null && 
          _sessionCategorizedVideos != null) {
        print('📱 Using session-cached explore data (no Firebase calls)');
        setState(() {
          _categories = List.from(_sessionCategories!);
          _allVideos = List.from(_sessionAllVideos!);
          _filteredVideos = List.from(_sessionAllVideos!);
          _categorizedVideos = Map.from(_sessionCategorizedVideos!);
          _isLoading = false;
        });
      } else {
        print('🔥 Loading explore data from Firebase and caching to session');
        await _loadDataFromCacheAndStore();
      }
    } else {
      print('⚠️ Session not initialized, redirecting to sync screen');
      Navigator.of(context).pushReplacementNamed('/initial-sync');
    }
  }

  /// Load data from Firebase cache and store in session cache (only called once per session)
  Future<void> _loadDataFromCacheAndStore() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Loading explore page data from Firebase cache (one-time per session)...');
      final stopwatch = Stopwatch()..start();

      // Use optimized loading method
      final result = await _youtubeService.loadExplorePageData();

      // Store in session cache
      _sessionCategories = result['categories'] as List<String>;
      _sessionAllVideos = result['allVideos'] as List<YouTubeVideo>;

      setState(() {
        _categories = List.from(_sessionCategories!);
        _allVideos = List.from(_sessionAllVideos!);
        _filteredVideos = List.from(_sessionAllVideos!);
        _isLoading = false;
      });

      // Categorize videos and store in session cache
      _categorizeVideos();
      _sessionCategorizedVideos = Map.from(_categorizedVideos);

      stopwatch.stop();
      print('✅ Explore page loaded and cached in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Cached ${_categories.length} categories with ${_allVideos.length} videos');

    } catch (e) {
      print('❌ Error loading explore data from Firebase cache: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load data with initialization checks (used for manual refresh)
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Manual refresh - loading explore page data...');
      final stopwatch = Stopwatch()..start();

      // Use optimized loading method
      final result = await _youtubeService.loadExplorePageData();

      setState(() {
        _categories = result['categories'] as List<String>;
        _allVideos = result['allVideos'] as List<YouTubeVideo>;
        _filteredVideos = result['allVideos'] as List<YouTubeVideo>;
        _isLoading = false;
      });

      // Categorize videos
      _categorizeVideos();

      stopwatch.stop();
      print('✅ Explore page refreshed in ${stopwatch.elapsedMilliseconds}ms (from cache)');
      print('📊 Loaded ${_categories.length} categories with ${_allVideos.length} videos');

    } catch (e) {
      print('❌ Error in manual refresh: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _categorizeVideos() {
    _categorizedVideos.clear();
    
    for (final video in _allVideos) {
      final category = VideoCategory.categorizeVideo(video.title, video.description);
      if (!_categorizedVideos.containsKey(category)) {
        _categorizedVideos[category] = [];
      }
      _categorizedVideos[category]!.add(video);
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
        limit: 30,
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
      resizeToAvoidBottomInset: true, // Handle keyboard properly
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _youtubeService.forceRefresh();
            await _loadData();
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // Category Filter
              if (!_isLoading)
                SliverToBoxAdapter(
                  child: _buildCategoryFilter(),
                ),

              SliverToBoxAdapter(
                child: const SizedBox(height: 20),
              ),

              // Content
              SliverFillRemaining(
                hasScrollBody: false,
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
    if (_categories.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
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
                  horizontal: 16,
                  vertical: 8,
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
                child: Row(
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
                    if (videoCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$videoCount',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
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
      return _buildSkeletonLoading();
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

  Widget _buildSkeletonLoading() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Reduced from 8 for faster loading
      itemBuilder: (context, index) => _buildVideoCardSkeleton(),
    );
  }

  Widget _buildVideoCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          Expanded(
            flex: 3,
            child: Shimmer.fromColors(
              baseColor: AppColors.textSecondary.withOpacity(0.1),
              highlightColor: AppColors.textSecondary.withOpacity(0.2),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // Content skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge skeleton
                  Shimmer.fromColors(
                    baseColor: AppColors.textSecondary.withOpacity(0.1),
                    highlightColor: AppColors.textSecondary.withOpacity(0.2),
                    child: Container(
                      width: 80,
                      height: 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title skeleton
                  Shimmer.fromColors(
                    baseColor: AppColors.textSecondary.withOpacity(0.1),
                    highlightColor: AppColors.textSecondary.withOpacity(0.2),
                    child: Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Shimmer.fromColors(
                    baseColor: AppColors.textSecondary.withOpacity(0.1),
                    highlightColor: AppColors.textSecondary.withOpacity(0.2),
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Stats skeleton
                  Shimmer.fromColors(
                    baseColor: AppColors.textSecondary.withOpacity(0.1),
                    highlightColor: AppColors.textSecondary.withOpacity(0.2),
                    child: Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // Adjusted for better title visibility
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredVideos.length,
      itemBuilder: (context, index) {
        return ExploreVideoCard(
          video: _filteredVideos[index],
          category: _getCategoryForVideo(_filteredVideos[index]),
          animationDelay: index * 50,
          onTap: () => _playVideo(_filteredVideos[index]),
        );
      },
    );
  }

  String _getCategoryForVideo(YouTubeVideo video) {
    for (final entry in _categorizedVideos.entries) {
      if (entry.value.any((v) => v.id == video.id)) {
        return entry.key;
      }
    }
    return 'General';
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
          ),
        ),
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
              onPressed: () async {
                await _youtubeService.forceRefresh();
                await _loadData();
              },
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
  final String category;
  final int animationDelay;
  final VoidCallback onTap;

  const ExploreVideoCard({
    Key? key,
    required this.video,
    required this.category,
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
                                ? AppColors.primaryAccent.withOpacity(0.2)
                                : AppColors.shadowLight,
                            blurRadius: _isPressed ? 12 : 6,
                            spreadRadius: _isPressed ? 1 : 0,
                            offset: Offset(0, _isPressed ? 3 : 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Expanded(
                            flex: 3,
                            child: _buildThumbnail(),
                          ),

                          // Content - Increased space for better title visibility
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
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.category,
                                      style: GoogleFonts.lato(
                                        fontSize: 10,
                                        color: AppColors.primaryAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Title - More space allocated
                                  Expanded(
                                    child: Text(
                                      widget.video.title,
                                      style: GoogleFonts.lato(
                                        fontSize: 14, // Increased font size
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 3, // Increased from 2 to 3
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Stats row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatViewCount(widget.video.viewCount),
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      // Duration
                                      if (widget.video.duration.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.textSecondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            widget.video.duration,
                                            style: GoogleFonts.lato(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
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

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: widget.video.thumbnailUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.cardBackground,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAccent,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.cardBackground,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Image\nUnavailable',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Play button overlay with better visibility
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Duration badge (moved to bottom-right for better UX)
          if (widget.video.duration.isNotEmpty)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.video.duration,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // New badge
          if (widget.video.isNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
    );
  }

  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    super.dispose();
  }
}