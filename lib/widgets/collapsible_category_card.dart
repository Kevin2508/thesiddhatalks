import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../models/firestore_video_models.dart';
import 'watchlist_button.dart';

class CollapsiblePlaylistCard extends StatefulWidget {
  // Support both YouTube and Firestore data
  final PlaylistInfo? playlist;
  final String? title;
  final String? description;
  final int? videoCount;
  
  final List<YouTubeVideo>? youtubeVideos;
  final List<FirestoreVideo>? firestoreVideos;
  
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(dynamic)? onVideoTap; // Accept both video types
  final int? index;
  final String? logoAssetName;

  // Constructor for YouTube playlists (backward compatibility)
  const CollapsiblePlaylistCard({
    Key? key,
    required this.playlist,
    required this.youtubeVideos,
    required this.isExpanded,
    required this.onToggle,
    required this.onVideoTap,
    required this.index,
    this.logoAssetName,
  }) : title = null,
       description = null,
       videoCount = null,
       firestoreVideos = null,
       super(key: key);

  // Constructor for Firestore categories (new system)
  const CollapsiblePlaylistCard.firestore({
    Key? key,
    required this.title,
    required this.description,
    required this.videoCount,
    required this.firestoreVideos,
    required this.isExpanded,
    required this.onToggle,
    required this.onVideoTap,
    this.index = 0,
    this.logoAssetName,
  }) : playlist = null,
       youtubeVideos = null,
       super(key: key);

  @override
  State<CollapsiblePlaylistCard> createState() => _CollapsiblePlaylistCardState();
}

class _CollapsiblePlaylistCardState extends State<CollapsiblePlaylistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  
  // Use colors from AppColors class
  static const List<Color> playlistColors = [
    AppColors.primaryAccent,   // Deep saffron orange
    AppColors.secondaryAccent, // Warm amber orange
  ];
  
  Color get playlistColor {
    return playlistColors[(widget.index ?? 0) % playlistColors.length];
  }

  // Get display title
  String get displayTitle {
    return widget.title ?? widget.playlist?.title ?? 'Untitled';
  }

  // Get display description
  String get displayDescription {
    return widget.description ?? widget.playlist?.description ?? '';
  }

  // Get video count
  int get displayVideoCount {
    return widget.videoCount ?? 
           widget.youtubeVideos?.length ?? 
           widget.firestoreVideos?.length ?? 
           0;
  }

  // Get videos list for display
  List<dynamic> get displayVideos {
    return widget.firestoreVideos ?? widget.youtubeVideos ?? [];
  }

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
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getPlaylistLogoName(String playlistTitle) {
    final lowerTitle = playlistTitle.toLowerCase();
    
    if (lowerTitle.contains('chakra')) {
      return 'chakra_logo.png';
    } else if (lowerTitle.contains('protection')) {
      return 'protection_logo.png';
    } else if (lowerTitle.contains('mangal')) {
      return 'mangal_logo.png';
    } else if (lowerTitle.contains('cleansing')) {
      return 'cleansing_logo.png';
    } else if (lowerTitle.contains('breathing')) {
      return 'breathing_logo.png';
    } else if (lowerTitle.contains('sahaj')) {
      return 'sahaj_logo.png';
    } else if (lowerTitle.contains('ratri')) {
      return 'ratri_logo.png';
    } else if (lowerTitle.contains('devine')) {
      return 'devine_logo.png';
    } else if (lowerTitle.contains('gibberish')) {
      return 'gibberish_logo.png';
    } else if (lowerTitle.contains('kundali')) {
      return 'kundali_logo.png';
    } else if (lowerTitle.contains('standing')) {
      return 'standing_logo.png';
    } else {
      return 'meditation_default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildExpandableContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggle();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Inner shadow effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.03),
                    Colors.transparent,
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Row(
              children: [
                _buildPlaylistLogo(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (displayDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          displayDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: playlistColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$displayVideoCount videos',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: playlistColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _iconAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _iconAnimation.value * 3.14159,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: playlistColor,
                        size: 28,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: playlistColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: playlistColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/${widget.logoAssetName ?? _getPlaylistLogoName(displayTitle)}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: playlistColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.self_improvement,
                color: playlistColor,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandableContent() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            if (displayVideos.isEmpty)
              _buildEmptyState()
            else
              _buildVideosList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No videos available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for new content',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: displayVideos.length,
        itemBuilder: (context, index) {
          final video = displayVideos[index];
          return _buildVideoItem(video, index);
        },
      ),
    );
  }

  Widget _buildVideoItem(dynamic video, int index) {
    // Handle both FirestoreVideo and YouTubeVideo
    String title = '';
    String duration = '';
    String thumbnail = '';
    
    if (video is FirestoreVideo) {
      title = video.getDisplayTitle();
      duration = video.duration;
      thumbnail = video.displayThumbnail;
    } else if (video is YouTubeVideo) {
      title = video.title;
      duration = video.duration;
      thumbnail = video.thumbnailUrl;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onVideoTap?.call(video);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildVideoThumbnail(thumbnail, duration),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                          color: playlistColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration.isNotEmpty ? duration : 'Duration: N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Add watchlist button for YouTube videos if needed
              if (video is YouTubeVideo)
                WatchlistButton(video: video),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String thumbnailUrl, String duration) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.primaryAccent.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Thumbnail
            if (thumbnailUrl.isNotEmpty && thumbnailUrl.startsWith('http'))
              Image.network(
                thumbnailUrl,
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailFallback();
                },
              )
            else if (thumbnailUrl.isNotEmpty && thumbnailUrl.startsWith('assets/'))
              Image.asset(
                thumbnailUrl,
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailFallback();
                },
              )
            else
              _buildThumbnailFallback(),
            
            // Duration overlay
            if (duration.isNotEmpty)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailFallback() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            playlistColor.withOpacity(0.2),
            playlistColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.play_circle_outline,
        color: playlistColor,
        size: 24,
      ),
    );
  }
}
