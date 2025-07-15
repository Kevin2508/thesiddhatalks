import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import 'watchlist_button.dart';

class CollapsiblePlaylistCard extends StatefulWidget {
  final PlaylistInfo playlist;
  final List<YouTubeVideo> videos;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(YouTubeVideo) onVideoTap;

  const CollapsiblePlaylistCard({
    Key? key,
    required this.playlist,
    required this.videos,
    required this.isExpanded,
    required this.onToggle,
    required this.onVideoTap,
  }) : super(key: key);

  @override
  State<CollapsiblePlaylistCard> createState() => _CollapsiblePlaylistCardState();
}

class _CollapsiblePlaylistCardState extends State<CollapsiblePlaylistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(_expandAnimation);

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CollapsiblePlaylistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          // Playlist Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onToggle();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Playlist Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 60,
                        child: widget.videos.isNotEmpty
                            ? Image.network(
                          widget.videos.first.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              child: Icon(
                                Icons.playlist_play,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                            );
                          },
                        )
                            : Container(
                          color: AppColors.textSecondary.withOpacity(0.1),
                          child: Icon(
                            Icons.playlist_play,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Playlist Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playlist.title,
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.videos.length} videos',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (widget.playlist.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.playlist.description,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: AppColors.textSecondary.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Expand/Collapse Icon
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconAnimation.value * 3.14159,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryAccent,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable Video List
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: widget.videos.isEmpty
                ? _buildEmptyState()
                : _buildVideosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: widget.videos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildVideoItem(widget.videos[index]);
        },
      ),
    );
  }

  Widget _buildVideoItem(YouTubeVideo video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onVideoTap(video),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                ),
                child: Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Video details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (video.duration != null && video.duration!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.duration.toString(), // Convert to string safely
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '${_formatViewCount(video.viewCount)} views',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WatchlistButton(
                  video: video,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ],
            ),
          ],
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
      return viewCount.toString();
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No videos available in this playlist',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

