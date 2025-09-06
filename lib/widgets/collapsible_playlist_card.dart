import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import 'watchlist_button.dart';

class CollapsiblePlaylistCard extends StatefulWidget {
  final PlaylistInfo playlist;
  final List<Video> videos;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(Video) onVideoTap;
  final int index; // Add index parameter for alternating colors

  const CollapsiblePlaylistCard({
    Key? key,
    required this.playlist,
    required this.videos,
    required this.isExpanded,
    required this.onToggle,
    required this.onVideoTap,
    required this.index, // Add required index
  }) : super(key: key);

  @override
  State<CollapsiblePlaylistCard> createState() => _CollapsiblePlaylistCardState();
}

class _CollapsiblePlaylistCardState extends State<CollapsiblePlaylistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  
  // Use colors from AppColors class - deep orange and lighter orange shades
  static const List<Color> playlistColors = [
    AppColors.primaryAccent,   // Deep saffron orange (#E65100)
    AppColors.secondaryAccent, // Lighter warm amber orange (#FF8F00)
  ];
  
  Color get playlistColor {
    // Perfect alternating pattern: even index = orange, odd index = grey
    return playlistColors[widget.index % playlistColors.length];
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
    final primaryColor = playlistColor;
    
    return Container(
       // Reduced from 16 to 6
      decoration: BoxDecoration(
        color: Colors.transparent, // Single solid color instead of gradient
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
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
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Playlist logo from assets
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _getCategoryLogoPath(widget.playlist.title),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to colored icon if asset image not found
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.playlist_play,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
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
                        ],
                      ),
                    ),
                    // Expand/Collapse Icon
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Transform.rotate(
                            angle: _iconAnimation.value * 3.14159,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: primaryColor,
                              size: 20,
                            ),
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
    final primaryColor = playlistColor;
    
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 150, // Reduced to fit better in the new layout
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(), // Allow scrolling if content overflows
        padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
        itemCount: widget.videos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8), // Reduced from 12 to 8
        itemBuilder: (context, index) {
          return _buildVideoItem(widget.videos[index]);
        },
      ),
    );
  }

  Widget _buildVideoItem(Video video) {
    final primaryColor = playlistColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced from 8 to 4
      padding: const EdgeInsets.all(8), // Reduced from 12 to 8
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onVideoTap(video),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6), // Reduced from 8 to 6
              child: Container(
                width: 60, // Reduced from 80 to 60
                height: 45, // Reduced from 60 to 45
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
                        size: 20, // Reduced from 24 to 20
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12 to 10
            // Video details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: GoogleFonts.lato(
                      fontSize: 13, // Reduced from 14 to 13
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3), // Reduced from 4 to 3
                  Row(
                    children: [
                      if (video.duration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), // Reduced padding
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3), // Reduced from 4 to 3
                          ),
                          child: Text(
                            video.duration,
                            style: GoogleFonts.lato(
                              fontSize: 9, // Reduced from 10 to 9
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      
                    ],
                  ),
                ],
              ),
            ),
            // Action button - only save/watchlist button
            WatchlistButton(
              video: video,
              size: 18, // Reduced from 20 to 18
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLogoPath(String categoryName) {
    // Map each category to its specific logo path
    switch (categoryName) {
      case 'Chakra Alignment':
        return 'assets/images/logos/chakra_alignment_logo.png';
      case 'Protection Layer':
        return 'assets/images/logos/protection_layer_logo.png';
      case 'Mangal Kamana':
        return 'assets/images/logos/mangal_kamna_logo.png';
      case 'Cleansing':
        return 'assets/images/logos/cleansing_logo.png';
      case 'Breathing Technique':
        return 'assets/images/logos/breathing_technique_logo.png';
      case 'Sahaj Dhyan':
        return 'assets/images/logos/sahaj_dhyan_logo.png';
      case 'Ratri Dhyan':
        return 'assets/images/logos/ratri_dhyan_logo.png';
      case 'Devine Energy':
        return 'assets/images/logos/devine_energy_logo.png';
      case 'Gibberish':
        return 'assets/images/logos/gibberish_logo.png';
      case 'Kundali':
        return 'assets/images/logos/kundali_logo.png';
      case 'Standing Meditation':
        return 'assets/images/logos/standing_meditation_logo.png';
      default:
        // Fallback to default logo
        return 'assets/images/siddhvachan_logo.png';
    }
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
    final primaryColor = playlistColor;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No videos available in this playlist',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: primaryColor,
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

