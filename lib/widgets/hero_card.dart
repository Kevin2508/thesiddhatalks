import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../services/youtube_service.dart';
import '../screens/player_screen.dart';
import 'watchlist_button.dart';

class HeroCard extends StatefulWidget {
  const HeroCard({Key? key}) : super(key: key);

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> with TickerProviderStateMixin {
  final YouTubeService _youtubeService = YouTubeService();

  LiveStream? _currentLiveStream;
  bool _isLoading = true;
  bool _hasLiveContent = false;

  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLiveContent();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadLiveContent() async {
    try {
      setState(() {
        _isLoading = true;
        _hasLiveContent = false;
      });

      print('🎥 HeroCard: Checking for live streams...');

      // Only check for current live streams
      final currentLiveStream = await _youtubeService.getCurrentLiveStream();

      setState(() {
        _currentLiveStream = currentLiveStream;
        _hasLiveContent = currentLiveStream != null;
        _isLoading = false;
      });

      if (_hasLiveContent) {
        print('🔴 HeroCard: Found live stream - ${_currentLiveStream!.title}');
        _pulseController.repeat(reverse: true);
        _backgroundController.repeat(reverse: true);
      } else {
        print('📭 HeroCard: No live streams found');
        _pulseController.stop();
        _backgroundController.stop();
      }

    } catch (e) {
      print('❌ HeroCard: Error loading live content: $e');
      setState(() {
        _isLoading = false;
        _hasLiveContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show the card if there's a live stream
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show anything while loading
    }

    if (!_hasLiveContent || _currentLiveStream == null) {
      return const SizedBox.shrink(); // Don't show anything if no live content
    }

    return _buildLiveStreamCard(_currentLiveStream!);
  }

  Widget _buildLiveStreamCard(LiveStream liveStream) {
    return GestureDetector(
      onTap: () => _playLiveStream(liveStream),
      child: Container(
        height: 240,
        margin: const EdgeInsets.only(bottom: 24), // Add margin since it's conditional
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: liveStream.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.red.withOpacity(0.6),
                          Colors.deepOrange.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.red.withOpacity(0.6),
                          Colors.deepOrange.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.live_tv,
                        size: 80,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated gradient overlay for live effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                            Colors.red.withOpacity(0.2 * _backgroundAnimation.value),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pulsing live indicator overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2 + (_backgroundAnimation.value * 0.4),
                          colors: [
                            Colors.red.withOpacity(0.15 * _backgroundAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live status and viewer count
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final scale = _pulseAnimation.value.clamp(1.0, 1.15);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pulsing dot
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.7, end: 1.0),
                                        duration: const Duration(milliseconds: 800),
                                        builder: (context, value, child) {
                                          return Container(
                                            width: 10,
                                            height: 10,
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
                                      const SizedBox(width: 8),
                                      Text(
                                        'LIVE',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  liveStream.viewerText,
                                  style: GoogleFonts.lato(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        liveStream.title,
                        style: GoogleFonts.rajdhani(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // Action buttons row
                      Row(
                        children: [
                          // Watchlist button
                          WatchlistButton(
                            video: liveStream.toYouTubeVideo(),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          // Watch Live button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _playLiveStream(liveStream);
                              },
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: Text(
                                'Watch Live Now',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 8,
                                shadowColor: Colors.red.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Central play button overlay
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = _pulseAnimation.value.clamp(1.0, 1.1);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Live pulse border effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3 + (0.4 * _backgroundAnimation.value)),
                          width: 2,
                        ),
                      ),
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

  void _playLiveStream(LiveStream liveStream) {
    // Convert LiveStream to YouTubeVideo for player compatibility
    final videoForPlayer = YouTubeVideo(
      id: liveStream.id,
      title: liveStream.title,
      description: liveStream.description,
      thumbnailUrl: liveStream.thumbnailUrl,
      channelTitle: liveStream.channelTitle,
      publishedAt: liveStream.publishedAt,
      duration: 'LIVE',
      viewCount: liveStream.viewCount,
      likeCount: liveStream.likeCount,
      isNew: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(video: videoForPlayer),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
}