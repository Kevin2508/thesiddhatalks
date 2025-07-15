import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../services/watchlist_service.dart';
import '../services/recently_played_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<YouTubeVideo> _watchlistVideos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadWatchlistVideos();
  }

  Future<void> _loadWatchlistVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await WatchlistService.getWatchlistVideos();
      
      setState(() {
        _watchlistVideos = videos;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWatchlist(YouTubeVideo video) async {
    final success = await WatchlistService.removeFromWatchlist(video.id);
    if (success) {
      setState(() {
        _watchlistVideos.removeWhere((v) => v.id == video.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from watchlist'),
            backgroundColor: AppColors.primaryAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playVideo(YouTubeVideo video) {
    RecentlyPlayedService.addRecentlyPlayedVideo(video);
    Navigator.pushNamed(
      context,
      '/player',
      arguments: video,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWatchlistVideos,
          child: CustomScrollView(
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
                    Icon(
                      Icons.bookmark,
                      color: AppColors.primaryAccent,
                      size: 24,
                    ),
                    if (_watchlistVideos.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${_watchlistVideos.length}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (_watchlistVideos.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'clear') {
                          _showClearConfirmDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, size: 20, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text('Clear All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _animationController,
                      child: _buildContent(),
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

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_watchlistVideos.isEmpty) {
      return _buildEmptyStateWidget();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Videos grid
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _watchlistVideos.length,
            itemBuilder: (context, index) {
              return _buildWatchlistVideoCard(_watchlistVideos[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistVideoCard(YouTubeVideo video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playVideo(video),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 120,
                    height: 68,
                    child: Stack(
                      children: [
                        Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: AppColors.textSecondary,
                                size: 32,
                              ),
                            );
                          },
                        ),                        // Duration overlay
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.duration,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Video info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.channelTitle,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: () => _removeFromWatchlist(video),
                  icon: Icon(
                    Icons.bookmark,
                    color: AppColors.primaryAccent,
                    size: 24,
                  ),
                  tooltip: 'Remove from watchlist',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Watchlist is Empty',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save videos to watch later by tapping the bookmark icon on any video.',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to home to discover videos
                Navigator.of(context).pushReplacementNamed('/home');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Videos'),
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
              'Failed to load watchlist',
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
              onPressed: _loadWatchlistVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(5, (index) => _buildSkeletonCard()),
      ),
    );
  }

  Widget _buildSkeletonCard() {
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
          _buildShimmerContainer(width: 120, height: 68, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(width: double.infinity, height: 20, borderRadius: 4),
                const SizedBox(height: 8),
                _buildShimmerContainer(width: 150, height: 16, borderRadius: 4),
              ],
            ),
          ),
          _buildShimmerContainer(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
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

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Watchlist',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all videos from your watchlist? This action cannot be undone.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await WatchlistService.clearWatchlist();
              await _loadWatchlistVideos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
