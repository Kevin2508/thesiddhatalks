import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../screens/home_screen.dart';

class PlaylistCarousel extends StatelessWidget {
  final String title;
  final List<VideoItem> videos;
  final bool showTitle;

  const PlaylistCarousel({
    Key? key,
    required this.title,
    required this.videos,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section title (only show if showTitle is true)
        if (showTitle && title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        if (showTitle && title.isNotEmpty) const SizedBox(height: 16),

        // Horizontal scrollable list - Fixed height to prevent overflow
        Container(
          height: 180, // Explicit height constraint
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                width: 160, // Explicit width
                margin: EdgeInsets.only(
                  right: index == videos.length - 1 ? 0 : 16,
                ),
                child: VideoCard(video: video),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VideoCard extends StatefulWidget {
  final VideoItem video;

  const VideoCard({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
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
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        if (!mounted) return;
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
        // Navigate to player screen
        Navigator.of(context).pushNamed('/player');
      },
      onTapCancel: () {
        if (!mounted) return;
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // Ensure scale is within valid range
          final scale = _scaleAnimation.value.clamp(0.8, 1.0);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 160,
              height: 180, // Explicit height to prevent overflow
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
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  // Thumbnail - Fixed height
                  Container(
                    height: 100, // Fixed height
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_circle_fill,
                            size: 40,
                            color: AppColors.textSecondary,
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
                  ),

                  // Content - Fixed height to prevent overflow
                  Container(
                    height: 80, // Fixed height for content area
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with constrained height
                        Expanded(
                          child: Text(
                            widget.video.title,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Play button at bottom
                        Row(
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: AppColors.primaryAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Play',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}