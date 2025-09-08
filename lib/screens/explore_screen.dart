import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import '../services/firestore_video_service.dart';
import 'hybrid_player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];
  Map<String, List<Video>> _categorizedVideos = {};
  List<String> _categories = ['All'];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadFirestoreData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  Future<void> _loadFirestoreData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch all videos from Firestore
      final allFirestoreVideos = await FirestoreVideoService.fetchAllVideos();
      
      if (allFirestoreVideos.isEmpty) {
        setState(() {
          _allVideos = [];
          _filteredVideos = [];
          _categorizedVideos = {};
          _categories = ['All'];
          _isLoading = false;
        });
        return;
      }

      // Convert Firestore videos to Video models and categorize them
      final List<Video> videoList = [];
      final Map<String, List<Video>> categorizedVideos = {};
      final Set<String> categorySet = {'All'};

      for (final firestoreVideo in allFirestoreVideos) {
        final video = Video(
          id: firestoreVideo.id.toString(),
          title: firestoreVideo.titleEnglish.isNotEmpty 
              ? firestoreVideo.titleEnglish 
              : firestoreVideo.titleHindi,
          description: firestoreVideo.titleHindi.isNotEmpty 
              ? firestoreVideo.titleHindi 
              : firestoreVideo.titleEnglish,
          thumbnailUrl: firestoreVideo.thumbnail.isNotEmpty 
              ? firestoreVideo.thumbnail 
              : 'https://via.placeholder.com/200x120?text=Video+Thumbnail',
          duration: firestoreVideo.duration,
          viewCount: 1000, // Default view count
          likeCount: 50,   // Default like count
          publishedAt: firestoreVideo.publishedAt,
          channelTitle: 'Siddha Kutumbakam',
          pcloudUrl: firestoreVideo.pcloudLink,
          youtubeUrl: firestoreVideo.youtubeUrl,
        );

        videoList.add(video);

        // Categorize videos
        final category = firestoreVideo.category.isNotEmpty 
            ? firestoreVideo.category 
            : 'General';
        
        categorySet.add(category);
        
        if (!categorizedVideos.containsKey(category)) {
          categorizedVideos[category] = [];
        }
        categorizedVideos[category]!.add(video);
      }

      setState(() {
        _allVideos = videoList;
        _filteredVideos = videoList;
        _categorizedVideos = categorizedVideos;
        _categories = categorySet.toList()..sort();
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _allVideos = [];
        _filteredVideos = [];
        _categorizedVideos = {};
        _categories = ['All'];
        _isLoading = false;
        _error = 'Failed to load videos: ${e.toString()}';
      });
    }
  }

  Future<void> _searchVideos(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = true;
    });

    if (_searchQuery.isEmpty) {
      // Reset to show all videos or current category
      _filterByCategory(_selectedCategory);
    } else {
      // Filter videos based on search query
      List<Video> searchResults;
      
      if (_selectedCategory == 'All') {
        searchResults = _allVideos.where((video) =>
            video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            video.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      } else {
        final categoryVideos = _categorizedVideos[_selectedCategory] ?? [];
        searchResults = categoryVideos.where((video) =>
            video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            video.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
      }

      setState(() {
        _filteredVideos = searchResults;
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        // Apply search filter to all videos
        if (_searchQuery.isEmpty) {
          _filteredVideos = List.from(_allVideos);
        } else {
          _filteredVideos = _allVideos.where((video) =>
              video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              video.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
      } else {
        // Filter by category and apply search
        final categoryVideos = _categorizedVideos[category] ?? [];
        if (_searchQuery.isEmpty) {
          _filteredVideos = List.from(categoryVideos);
        } else {
          _filteredVideos = categoryVideos.where((video) =>
              video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              video.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        if (_showSuggestions) {
          setState(() {
            _showSuggestions = false;
          });
        }
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadFirestoreData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Category Filter
                  if (!_isLoading && _categories.isNotEmpty)
                    _buildCategoryFilter(),

                  const SizedBox(height: 20),

                  // Content
                  _buildContent(),
                ],
              ),
            ),
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

          // Enhanced Search Bar with Transliteration Support
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (query) {
                  // TODO: Implement search suggestions with Firestore data
                  setState(() {
                    _showSuggestions = false;
                    _searchSuggestions = [];
                  });

                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == query) {
                      if (query.isNotEmpty) {
                        _searchVideos(query);
                      } else {
                        _searchVideos('');
                      }
                    }
                  });
                },
                onTap: () {
                  if (_searchController.text.isNotEmpty && _searchSuggestions.isNotEmpty) {
                    setState(() {
                      _showSuggestions = true;
                    });
                  }
                },
                style: GoogleFonts.lato(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search teachings',
                  hintStyle: GoogleFonts.lato(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchVideos('');
                            setState(() {
                              _showSuggestions = false;
                              _searchSuggestions = [];
                            });
                            _searchFocusNode.unfocus();
                          },
                        ),
                      
                    ],
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primaryAccent.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              
              // Search Suggestions
              if (_showSuggestions && _searchSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Suggestions',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...(_searchSuggestions.take(3).map((suggestion) => 
                        InkWell(
                          onTap: () {
                            _searchController.text = suggestion;
                            _searchVideos(suggestion);
                            setState(() {
                              _showSuggestions = false;
                            });
                            _searchFocusNode.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).toList()),
                    ],
                  ),
                ),
            ],
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
                _filterByCategory(category);
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
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling to avoid conflicts
      shrinkWrap: true, // Allow grid to size itself
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Increased from 0.68 to 0.75 for much more height
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

  String _getCategoryForVideo(Video video) {
    for (final entry in _categorizedVideos.entries) {
      if (entry.value.any((v) => v.id == video.id)) {
        return entry.key;
      }
    }
    return ''; // Return empty string instead of 'General'
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
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
              _filterByCategory('All');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Show All Videos'),
          ),
          const SizedBox(height: 40),
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
              onPressed: () async {
                // TODO: Implement retry with Firestore data
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

  void _playVideo(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HybridPlayerScreen(
          video: video,
          pcloudUrl: video.pcloudUrl.isNotEmpty ? video.pcloudUrl : video.youtubeUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

class ExploreVideoCard extends StatefulWidget {
  final Video video;
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
                            flex: 2, // Increased from 4 to 5 for even more thumbnail space
                            child: _buildThumbnail(),
                          ),

                          // Content - Reduced content area significantly
                          Expanded(
                            flex: 2, // Keep at 2 for minimal content space
                            child: Padding(
                              padding: const EdgeInsets.all(8), // Reduced from 10 to 8
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Prevent overflow
                                children: [
                                  // Category badge - hide if it's "General" or empty
                                  if (widget.category != 'General' && widget.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.category,
                                        style: GoogleFonts.lato(
                                          fontSize: 9,
                                          color: AppColors.primaryAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                  SizedBox(height: 6), // Reduced from 4 to 2

                                  // Title - Much smaller fixed height container
                                  Container(
                                    height: 32, // Reduced from 42 to 32
                                    child: Text(
                                      widget.video.title,
                                      style: GoogleFonts.lato(
                                        fontSize: 12, // Reduced from 12 to 11
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.0, // Reduced from 1.1 to 1.0 for minimum spacing
                                      ),
                                      maxLines: 2, // Reduced from 3 to 2 lines
                                      overflow: TextOverflow.ellipsis, // Ensure ellipsis when text overflows
                                    ),
                                  ),

                                  const SizedBox(height: 2), // Reduced from 4 to 2

                                  // Upload date - Fixed position at bottom
                                  Text(
                                    _formatDate(widget.video.publishedAt),
                                    style: GoogleFonts.lato(
                                      fontSize: 9, // Reduced from 10 to 9
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  // Stats row - more compact
                                  
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
            errorWidget: (context, url, error) {
              return Container(
                color: AppColors.cardBackground,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_circle_filled,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                  ],
                ),
              );
            },
            imageBuilder: (context, imageProvider) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
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

          // Note: 'isNew' property removed - was part of YouTube model
          // if (widget.video.isNew)
           ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    super.dispose();
  }
}