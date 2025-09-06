import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import '../screens/hybrid_player_screen.dart';
import 'watchlist_button.dart';

class VideoPlaylistCarousel extends StatelessWidget {
  final String title;
  final List<Video> videos;
  final bool showTitle;
  final VoidCallback? onSeeAll;

  const VideoPlaylistCarousel({
    Key? key,
    required this.title,
    required this.videos,
    this.showTitle = true,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Text(
                      'See All',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: VideoCard(
                  video: video,
                  onTap: () => _playVideo(context, video),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playVideo(BuildContext context, Video video) {
    HapticFeedback.mediumImpact();
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
}

class VideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;
  final bool showDuration;
  final bool showWatchlist;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onTap,
    this.showDuration = true,
    this.showWatchlist = true,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: _isPressed ? 5 : 10,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail Section
                    Expanded(
                      flex: 3,
                      child: _buildThumbnail(),
                    ),
                    
                    // Info Section
                    Expanded(
                      flex: 2,
                      child: _buildVideoInfo(),
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

  Widget _buildThumbnail() {
    return Stack(
      children: [
        // Main thumbnail
        Container(
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceBackground,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceBackground,
              child: Icon(
                Icons.video_library_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
          ),
        ),
        
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),

        // Play button
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // Duration badge
        if (widget.showDuration && widget.video.duration.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Watchlist button
        if (widget.showWatchlist)
          Positioned(
            top: 8,
            right: 8,
            child: WatchlistButton(
              video: widget.video,
              size: 36,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
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
          
          const SizedBox(height: 6),
          
          // Channel name
          Text(
            widget.video.channelTitle,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Additional info row
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 14,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 4),
              Text(
                'Watch',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.video.youtubeUrl?.isNotEmpty == true)
                Icon(
                  Icons.link,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoListItem extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;
  final bool showThumbnail;

  const VideoListItem({
    Key? key,
    required this.video,
    this.onTap,
    this.showThumbnail = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showThumbnail) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 60,
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceBackground,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryAccent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceBackground,
                      child: Icon(
                        Icons.video_library_outlined,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channelTitle,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (video.duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.duration,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            WatchlistButton(
              video: video,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
