import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../screens/player_screen.dart';

class LiveStreamBanner extends StatelessWidget {
  final LiveStream liveStream;
  final VoidCallback? onTap;

  const LiveStreamBanner({
    Key? key,
    required this.liveStream,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _playLiveStream(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: liveStream.isLive
                ? [
              Colors.red.withOpacity(0.1),
              Colors.red.withOpacity(0.05),
            ]
                : [
              AppColors.primaryAccent.withOpacity(0.1),
              AppColors.primaryAccent.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: liveStream.isLive
                ? Colors.red.withOpacity(0.3)
                : AppColors.primaryAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: liveStream.isLive
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primaryAccent.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: liveStream.thumbnailUrl,
                    width: 120,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 120,
                      height: 80,
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
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: liveStream.isLive
                                    ? Colors.red
                                    : AppColors.primaryAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (liveStream.isLive) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    liveStream.statusText,
                                    style: GoogleFonts.lato(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.play_circle_fill,
                              color: liveStream.isLive
                                  ? Colors.red
                                  : AppColors.primaryAccent,
                              size: 20,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title
                        Text(
                          liveStream.title,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Time and viewers
                        Row(
                          children: [
                            Icon(
                              liveStream.isLive
                                  ? Icons.visibility
                                  : Icons.schedule,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              liveStream.isLive
                                  ? liveStream.viewerText
                                  : liveStream.timeText,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
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

            // Pulse animation for live streams
            if (liveStream.isLive)
              Positioned(
                top: 8,
                left: 8,
                child: _buildPulseAnimation(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(1.0 - value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Animation will restart automatically due to TweenAnimationBuilder
      },
    );
  }

  void _playLiveStream(BuildContext context) {
    // Convert LiveStream to YouTubeVideo for compatibility
    final video = YouTubeVideo(
      id: liveStream.id,
      title: liveStream.title,
      description: liveStream.description,
      thumbnailUrl: liveStream.thumbnailUrl,
      channelTitle: liveStream.channelTitle,
      publishedAt: liveStream.publishedAt,
      duration: liveStream.isLive ? 'LIVE' : '0:00',
      viewCount: liveStream.viewCount,
      likeCount: liveStream.likeCount,
      isNew: liveStream.isUpcoming || liveStream.isLive,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(video: video),
      ),
    );
  }
}