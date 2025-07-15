import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../screens/player_screen.dart';
import 'watchlist_button.dart';

class YouTubePlaylistCarousel extends StatelessWidget {
  final PlaylistInfo playlist;
  final List<YouTubeVideo> videos;
  final VoidCallback onSeeAll;
  final bool showTitle;

  const YouTubePlaylistCarousel({
    Key? key,
    required this.playlist,
    required this.videos,
    required this.onSeeAll,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (only show if showTitle is true)
        if (showTitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: GoogleFonts.rajdhani(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.videoCount} videos',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSeeAll();
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

        if (showTitle) const SizedBox(height: 16),

        // Video carousel - Fixed height to prevent overflow
        Container(
          height: 200, // Explicit height constraint
          child: videos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280, // Explicit width for horizontal scrolling
                margin: EdgeInsets.only(
                  right: index == videos.length - 1 ? 0 : 16,
                ),
                child: YouTubeVideoCard(
                  video: videos[index],
                  onTap: () => _playVideo(context, videos[index]),
                  isHorizontal: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No videos available',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Videos will appear here once loaded',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, YouTubeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(video: video),
      ),
    );
  }
}

class YouTubeVideoCard extends StatefulWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;
  final bool isHorizontal;
  final bool showPlayButton;

  const YouTubeVideoCard({
    Key? key,
    required this.video,
    required this.onTap,
    this.isHorizontal = false,
    this.showPlayButton = true,
  }) : super(key: key);

  @override
  State<YouTubeVideoCard> createState() => _YouTubeVideoCardState();
}

class _YouTubeVideoCardState extends State<YouTubeVideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!mounted) return;
        setState(() => _isPressed = true);
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        if (!mounted) return;
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        if (!mounted) return;
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value.clamp(0.9, 1.0),
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
              child: widget.isHorizontal
                  ? _buildHorizontalLayout()
                  : _buildVerticalLayout(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Container(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            flex: 3,
            child: _buildThumbnail(),
          ),
          // Content
          Expanded(
            flex: 2,
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Row(
      children: [
        // Thumbnail
        Container(
          width: 120,
          height: 80,
          child: _buildThumbnail(),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildThumbnail() {
    return Container(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: widget.isHorizontal
                ? const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            )
                : BorderRadius.circular(8),
            child: CachedNetworkImage(
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
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Play button overlay
          if (widget.showPlayButton)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: widget.isHorizontal ? 32 : 24,
                ),
              ),
            ),

          // Duration badge
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Expanded(
            child: Text(
              widget.video.title,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: widget.isHorizontal ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Video stats
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
              Text(
                _timeAgo(widget.video.publishedAt),
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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

  String _timeAgo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// List item version for vertical lists
class YouTubeVideoListItem extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;

  const YouTubeVideoListItem({
    Key? key,
    required this.video,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = VideoCategory.categorizeVideo(
      video.title,
      video.description,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 100,
                height: 60,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.cardBackground,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 1),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.cardBackground,
                          child: const Icon(Icons.error, size: 20),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: WatchlistButton(
                        video: video,
                        size: 14,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.duration,
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: Colors.white,
                          ),
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
                    Text(
                      video.title,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatViewCount(video.viewCount),
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _timeAgo(video.publishedAt),
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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

  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$viewCount';
    }
  }

  String _timeAgo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}