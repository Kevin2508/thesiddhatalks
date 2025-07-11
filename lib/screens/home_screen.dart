import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../widgets/hero_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/youtube_playlist_carousel.dart';
import '../widgets/live_stream_banner.dart';
import '../services/youtube_service.dart';
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
  final YouTubeService _youtubeService = YouTubeService();

  List<PlaylistInfo> _allPlaylists = [];
  List<PlaylistInfo> _displayedPlaylists = [];
  Map<String, List<YouTubeVideo>> _playlistVideos = {};
  List<LiveStream> _liveStreams = [];
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

    _loadData();
    _setupScrollListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.forward();
      }
    });
  }

  void _setupScrollListener() {
    _pageScrollController.addListener(() {
      if (_pageScrollController.position.pixels >=
          _pageScrollController.position.maxScrollExtent - 200) {
        _loadMoreContent();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🏠 Starting optimized home page load...');
      final stopwatch = Stopwatch()..start();

      final result = await _youtubeService.loadHomePageData();

      setState(() {
        _allPlaylists = result['playlists'] as List<PlaylistInfo>;
        _displayedPlaylists = result['initialPlaylists'] as List<PlaylistInfo>;
        _playlistVideos = result['playlistVideos'] as Map<String, List<YouTubeVideo>>;
        _liveStreams = result['liveStreams'] as List<LiveStream>;
        _hasMore = result['hasMore'] as bool;
        _isLoading = false;
      });

      stopwatch.stop();
      print('✅ Home page loaded in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Loaded ${_displayedPlaylists.length}/${_allPlaylists.length} playlists');
      print('🔴 Found ${_liveStreams.length} live streams');

      // Log live stream status for debugging
      final activeLiveStreams = _liveStreams.where((stream) => stream.isLive).toList();
      print('🔴 Active live streams: ${activeLiveStreams.length}');
      for (final stream in activeLiveStreams) {
        print('   - ${stream.title} (${stream.statusText})');
      }

    } catch (e) {
      print('❌ Error in _loadData: $e');
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
            await _youtubeService.clearCache();
            await _youtubeService.clearLiveStreamCache();
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

                        // Live Stream Banner - ONLY show when there's an active live stream
                        if (_hasActiveLiveStream && !_isLoading && _currentLiveStream != null)
                          _buildAnimatedSection(
                            interval: const Interval(0.1, 0.4, curve: Curves.easeOut),
                            child: _buildLiveStreamSection(_currentLiveStream!),
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

                        // Content based on loading state
                        if (_error != null)
                          _buildErrorWidget()
                        else if (_isLoading)
                          _buildSkeletonLoading()
                        else if (_displayedPlaylists.isEmpty)
                            _buildEmptyStateWidget()
                          else
                            ..._buildPlaylistSections(),

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
              'Loading more content...',
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
          label: Text('Load More (${_allPlaylists.length - _displayedPlaylists.length} remaining)'),
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
    return Column(
      children: List.generate(2, (index) => _buildPlaylistSkeleton()),
    );
  }

  Widget _buildPlaylistSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonContainer(
                      width: 200,
                      height: 24,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 8),
                    _buildSkeletonContainer(
                      width: 120,
                      height: 16,
                      borderRadius: 6,
                    ),
                  ],
                ),
                _buildSkeletonContainer(
                  width: 80,
                  height: 32,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (context, index) => _buildVideoCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCardSkeleton() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonContainer(
            width: 280,
            height: 120,
            borderRadius: 12,
          ),
          const SizedBox(height: 12),
          _buildSkeletonContainer(
            width: 260,
            height: 18,
            borderRadius: 6,
          ),
          const SizedBox(height: 8),
          _buildSkeletonContainer(
            width: 200,
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: 6),
          _buildSkeletonContainer(
            width: 80,
            height: 12,
            borderRadius: 4,
          ),
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

  List<Widget> _buildPlaylistSections() {
    // Filter out playlists that have no videos
    final playlistsWithVideos = _displayedPlaylists.where((playlist) {
      final videos = _playlistVideos[playlist.id] ?? [];
      return videos.isNotEmpty;
    }).toList();

    if (playlistsWithVideos.isEmpty) {
      return [_buildEmptyStateWidget()];
    }

    return playlistsWithVideos.map((playlist) {
      final videos = _playlistVideos[playlist.id] ?? [];

      return _buildAnimatedSection(
        interval: const Interval(0.4, 0.7, curve: Curves.easeOut),
        child: Column(
          children: [
            YouTubePlaylistCarousel(
              playlist: playlist,
              videos: videos,
              onSeeAll: () => _navigateToPlaylistView(playlist),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }).toList();
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

  void _navigateToPlaylistView(PlaylistInfo playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistVideosScreen(playlist: playlist),
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

  @override
  void dispose() {
    _scrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }
}

// Screen to show all videos in a playlist
class PlaylistVideosScreen extends StatefulWidget {
  final PlaylistInfo playlist;

  const PlaylistVideosScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  State<PlaylistVideosScreen> createState() => _PlaylistVideosScreenState();
}

class _PlaylistVideosScreenState extends State<PlaylistVideosScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  List<YouTubeVideo> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllVideos();
  }

  Future<void> _loadAllVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await _youtubeService.getPlaylistVideos(
        widget.playlist.id,
        maxResults: 50,
      );

      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.playlist.title,
          style: GoogleFonts.rajdhani(
            fontSize: 20,
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
      body: _isLoading
          ? _buildPlaylistDetailSkeleton()
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadAllVideos,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return YouTubeVideoListItem(
            video: _videos[index],
            onTap: () => _playVideo(_videos[index]),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistDetailSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) => _buildVideoListItemSkeleton(),
    );
  }

  Widget _buildVideoListItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.textSecondary.withOpacity(0.1),
            highlightColor: AppColors.textSecondary.withOpacity(0.2),
            child: Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppColors.textSecondary.withOpacity(0.1),
                  highlightColor: AppColors.textSecondary.withOpacity(0.2),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: AppColors.textSecondary.withOpacity(0.1),
                  highlightColor: AppColors.textSecondary.withOpacity(0.2),
                  child: Container(
                    height: 14,
                    width: double.infinity * 0.7,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: AppColors.textSecondary.withOpacity(0.1),
                  highlightColor: AppColors.textSecondary.withOpacity(0.2),
                  child: Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(YouTubeVideo video) {
    Navigator.pushNamed(
      context,
      '/player',
      arguments: video,
    );
  }
}