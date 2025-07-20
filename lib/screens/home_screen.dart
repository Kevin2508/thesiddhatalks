import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../widgets/hero_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/recently_played_section.dart';
import '../widgets/collapsible_playlist_card.dart';
import '../widgets/live_stream_banner.dart';
import '../services/optimized_youtube_service.dart';
import '../services/app_initialization_service.dart';
import '../services/recently_played_service.dart';
import '../models/youtube_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  final ScrollController _pageScrollController = ScrollController();
  final OptimizedYouTubeService _youtubeService = OptimizedYouTubeService();

  // Session-level cache to prevent repeated loading
  static List<PlaylistInfo>? _sessionAllPlaylists;
  static List<PlaylistInfo>? _sessionDisplayedPlaylists;
  static Map<String, List<YouTubeVideo>>? _sessionPlaylistVideos;
  static List<LiveStream>? _sessionLiveStreams;
  static bool? _sessionHasMore;

  List<PlaylistInfo> _allPlaylists = [];
  List<PlaylistInfo> _displayedPlaylists = [];
  Map<String, List<YouTubeVideo>> _playlistVideos = {};
  List<LiveStream> _liveStreams = [];
  String? _expandedPlaylistId;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _setupScrollListener();
    _checkInitializationAndLoad();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.forward();
      }
    });
  }

  void _checkInitializationAndLoad() async {
    // Check if app is initialized in current session
    if (AppInitializationService.isSessionInitialized) {
      print('✅ Session already initialized');
      
      // Check if we have session-cached data
      if (_sessionAllPlaylists != null && 
          _sessionDisplayedPlaylists != null && 
          _sessionPlaylistVideos != null && 
          _sessionLiveStreams != null &&
          _sessionHasMore != null) {
        print('📱 Using session-cached data (no Firebase calls)');
        setState(() {
          _allPlaylists = List.from(_sessionAllPlaylists!);
          _displayedPlaylists = List.from(_sessionDisplayedPlaylists!);
          _playlistVideos = Map.from(_sessionPlaylistVideos!);
          _liveStreams = List.from(_sessionLiveStreams!);
          _hasMore = _sessionHasMore!;
          _isLoading = false;
        });
      } else {
        print('🔥 Loading from Firebase and caching to session');
        await _loadDataFromCacheAndStore();
      }
    } else {
      print('⚠️ Session not initialized, redirecting to sync screen');
      Navigator.of(context).pushReplacementNamed('/initial-sync');
    }
  }

  void _setupScrollListener() {
    _pageScrollController.addListener(() {
      if (_pageScrollController.position.pixels >=
          _pageScrollController.position.maxScrollExtent - 200) {
        _loadMoreContent();
      }
    });
  }

  /// Load data from Firebase cache and store in session cache (only called once per session)
  Future<void> _loadDataFromCacheAndStore() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🏠 Loading home page data from Firebase cache (one-time per session)...');
      final stopwatch = Stopwatch()..start();

      final result = await _youtubeService.loadHomePageData();

      // Store in session cache
      _sessionAllPlaylists = result['playlists'] as List<PlaylistInfo>;
      _sessionDisplayedPlaylists = result['initialPlaylists'] as List<PlaylistInfo>;
      _sessionPlaylistVideos = result['playlistVideos'] as Map<String, List<YouTubeVideo>>;
      _sessionLiveStreams = result['liveStreams'] as List<LiveStream>;
      _sessionHasMore = result['hasMore'] as bool;

      setState(() {
        _allPlaylists = List.from(_sessionAllPlaylists!);
        _displayedPlaylists = List.from(_sessionDisplayedPlaylists!);
        _playlistVideos = Map.from(_sessionPlaylistVideos!);
        _liveStreams = List.from(_sessionLiveStreams!);
        _hasMore = _sessionHasMore!;
        _isLoading = false;
      });

      stopwatch.stop();
      print('✅ Home page loaded and cached in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Cached ${_displayedPlaylists.length}/${_allPlaylists.length} playlists');
      print('🔴 Found ${_liveStreams.length} live streams');

    } catch (e) {
      print('❌ Error loading from Firebase cache: $e');
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

      print('🏠 Manual refresh - loading home page data...');
      final stopwatch = Stopwatch()..start();

      final result = await _youtubeService.loadHomePageData();

      // Update session cache with fresh data
      _sessionAllPlaylists = result['playlists'] as List<PlaylistInfo>;
      _sessionDisplayedPlaylists = result['initialPlaylists'] as List<PlaylistInfo>;
      _sessionPlaylistVideos = result['playlistVideos'] as Map<String, List<YouTubeVideo>>;
      _sessionLiveStreams = result['liveStreams'] as List<LiveStream>;
      _sessionHasMore = result['hasMore'] as bool;

      setState(() {
        _allPlaylists = List.from(_sessionAllPlaylists!);
        _displayedPlaylists = List.from(_sessionDisplayedPlaylists!);
        _playlistVideos = Map.from(_sessionPlaylistVideos!);
        _liveStreams = List.from(_sessionLiveStreams!);
        _hasMore = _sessionHasMore!;
        _isLoading = false;
      });

      stopwatch.stop();
      final fromCache = result['fromCache'] as bool? ?? true;
      print('✅ Home page refreshed in ${stopwatch.elapsedMilliseconds}ms (${fromCache ? "from cache" : "from API"})');
      print('📊 Loaded ${_displayedPlaylists.length}/${_allPlaylists.length} playlists');
      print('🔴 Found ${_liveStreams.length} live streams');

      // Log live stream status for debugging
      final activeLiveStreams = _liveStreams.where((stream) => stream.isLive).toList();
      print('🔴 Active live streams: ${activeLiveStreams.length}');
      for (final stream in activeLiveStreams) {
        print('   - ${stream.title} (${stream.statusText})');
      }

    } catch (e) {
      print('❌ Error in manual refresh: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      const batchSize = 2;
      final currentCount = _displayedPlaylists.length;
      final remainingPlaylists = _allPlaylists.skip(currentCount).take(batchSize).toList();

      if (remainingPlaylists.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      final playlistIds = remainingPlaylists.map((p) => p.id).toList();
      final moreVideos = await _youtubeService.batchLoadPlaylistVideos(playlistIds, maxResults: 3);

      // Update session cache
      _sessionDisplayedPlaylists = [..._displayedPlaylists, ...remainingPlaylists];
      _sessionPlaylistVideos = {..._playlistVideos, ...moreVideos};
      _sessionHasMore = _sessionDisplayedPlaylists!.length < _allPlaylists.length;

      setState(() {
        _displayedPlaylists.addAll(remainingPlaylists);
        _playlistVideos.addAll(moreVideos);
        _hasMore = _displayedPlaylists.length < _allPlaylists.length;
        _isLoadingMore = false;
      });

    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      print('❌ Error loading more content: $e');
    }
  }

  void _togglePlaylist(String playlistId) {
    setState(() {
      if (_expandedPlaylistId == playlistId) {
        _expandedPlaylistId = null;
      } else {
        _expandedPlaylistId = playlistId;
      }
    });
  }

  void _playVideo(YouTubeVideo video) {
    RecentlyPlayedService.addRecentlyPlayedVideo(video);
    Navigator.pushNamed(
      context,
      '/player',
      arguments: video,
    );
  }

  // Check if there are any active live streams
  bool get _hasActiveLiveStream {
    return _liveStreams.any((stream) => stream.isLive);
  }

  // Get the current live stream (if any)
  LiveStream? get _currentLiveStream {
    try {
      return _liveStreams.firstWhere((stream) => stream.isLive);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            clearSessionCache(); // Clear session cache for fresh data
            await _youtubeService.forceRefresh();
            await _loadData();
          },
          child: CustomScrollView(
            controller: _pageScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.primaryBackground,
                elevation: 0,
                title: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 112,
                      height: 112,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                actions: [
                  // Live indicator - only show if there's an active live stream
                  if (_hasActiveLiveStream && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing dot animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.5, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, value, child) {
                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(value),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                            onEnd: () {
                              // Animation restarts automatically
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/profile');
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

                        // Recently Played Section
                        _buildAnimatedSection(
                          interval: const Interval(0.1, 0.4, curve: Curves.easeOut),
                          child: const RecentlyPlayedSection(),
                        ),

                        // Live Stream Banner - ONLY show when there's an active live stream
                        if (_hasActiveLiveStream && !_isLoading && _currentLiveStream != null)
                          _buildAnimatedSection(
                            interval: const Interval(0.2, 0.5, curve: Curves.easeOut),
                            child: _buildLiveStreamSection(_currentLiveStream!),
                          ),

                        // Hero Card
                        _buildAnimatedSection(
                          interval: const Interval(0.3, 0.6, curve: Curves.easeOut),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: HeroCard(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Playlists Section Header
                        if (!_isLoading && _displayedPlaylists.isNotEmpty)
                          _buildAnimatedSection(
                            interval: const Interval(0.4, 0.7, curve: Curves.easeOut),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.playlist_play,
                                    color: AppColors.primaryAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All Playlists',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primaryAccent.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${_allPlaylists.length}',
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Content based on loading state
                        if (_error != null)
                          _buildErrorWidget()
                        else if (_isLoading)
                          _buildSkeletonLoading()
                        else if (_displayedPlaylists.isEmpty)
                            _buildEmptyStateWidget()
                          else
                            ..._buildCollapsiblePlaylists(),

                        // Load more content
                        if (_isLoadingMore) _buildLoadMoreIndicator(),
                        if (_hasMore && !_isLoadingMore) _buildLoadMoreButton(),

                        // Bottom padding
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
      ),
    );
  }

  List<Widget> _buildCollapsiblePlaylists() {
    return _displayedPlaylists.asMap().entries.map((entry) {
      final index = entry.key;
      final playlist = entry.value;
      final videos = _playlistVideos[playlist.id] ?? [];

      return _buildAnimatedSection(
        interval: const Interval(0.5, 0.8, curve: Curves.easeOut),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CollapsiblePlaylistCard(
            playlist: playlist,
            videos: videos,
            isExpanded: _expandedPlaylistId == playlist.id,
            onToggle: () => _togglePlaylist(playlist.id),
            onVideoTap: _playVideo,
            index: index, // Pass the index for alternating colors
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLiveStreamSection(LiveStream liveStream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Pulsing live indicator
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
                onEnd: () {
                  // Animation restarts automatically
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Live Now',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              // Viewer count for live stream
              if (liveStream.concurrentViewers != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_formatNumber(liveStream.concurrentViewers!)} watching',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LiveStreamBanner(liveStream: liveStream),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading more playlists...',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _loadMoreContent,
          icon: const Icon(Icons.expand_more),
          label: Text('Load More Playlists (${_allPlaylists.length - _displayedPlaylists.length} remaining)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) => _buildPlaylistCardSkeleton()),
      ),
    );
  }

  Widget _buildPlaylistCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSkeletonContainer(width: 80, height: 60, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonContainer(width: double.infinity, height: 18, borderRadius: 4),
                const SizedBox(height: 8),
                _buildSkeletonContainer(width: 120, height: 12, borderRadius: 4),
                const SizedBox(height: 4),
                _buildSkeletonContainer(width: 200, height: 10, borderRadius: 4),
              ],
            ),
          ),
          _buildSkeletonContainer(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildSkeletonContainer({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.textSecondary.withOpacity(0.1),
      highlightColor: AppColors.textSecondary.withOpacity(0.2),
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.playlist_play,
              color: AppColors.primaryAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Playlists Found',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No video content is available at the moment. Please check back later.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

  /// Clear session cache (called when user manually refreshes)
  static void clearSessionCache() {
    _sessionAllPlaylists = null;
    _sessionDisplayedPlaylists = null;
    _sessionPlaylistVideos = null;
    _sessionLiveStreams = null;
    _sessionHasMore = null;
    print('🗑️ Session cache cleared');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }
}