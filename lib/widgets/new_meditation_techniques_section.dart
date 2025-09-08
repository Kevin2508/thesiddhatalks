import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import '../services/firestore_video_service.dart';
import 'watchlist_button.dart';

class NewMeditationTechniquesSection extends StatefulWidget {
  final Function(Video)? onVideoTap;
  
  const NewMeditationTechniquesSection({
    Key? key, 
    this.onVideoTap,
  }) : super(key: key);

  @override
  State<NewMeditationTechniquesSection> createState() => _NewMeditationTechniquesSectionState();
}

class _NewMeditationTechniquesSectionState extends State<NewMeditationTechniquesSection> {
  List<Video> _meditationVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeditationVideos();
  }

  Future<void> _loadMeditationVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch videos from Firestore and filter for meditation category
      final allVideos = await FirestoreVideoService.fetchAllVideos();
      final meditationVideos = allVideos
          .where((video) => 
              video.category.toLowerCase().contains('meditation') ||
              video.titleEnglish.toLowerCase().contains('meditation') ||
              video.titleHindi.toLowerCase().contains('ध्यान') ||
              video.titleHindi.toLowerCase().contains('meditation'))
          .take(10) // Limit to 10 videos
          .map((firestoreVideo) => Video(
            id: firestoreVideo.id.toString(),
            title: firestoreVideo.titleEnglish.isNotEmpty 
                ? firestoreVideo.titleEnglish 
                : firestoreVideo.titleHindi,
            description: firestoreVideo.titleHindi.isNotEmpty 
                ? firestoreVideo.titleHindi 
                : firestoreVideo.titleEnglish,
            thumbnailUrl: firestoreVideo.thumbnail.isNotEmpty 
                ? firestoreVideo.thumbnail 
                : 'https://via.placeholder.com/200x120?text=Meditation+Video',
            duration: firestoreVideo.duration,
            publishedAt: firestoreVideo.publishedAt,
            channelTitle: 'Siddha Kutumbakam',
            pcloudUrl: firestoreVideo.pcloudLink,
            youtubeUrl: firestoreVideo.youtubeUrl,
          ))
          .toList();

      setState(() {
        _meditationVideos = meditationVideos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meditation videos: $e');
      setState(() {
        _meditationVideos = [];
        _isLoading = false;
      });
    }
  }

  void _playVideo(Video video) {
    if (widget.onVideoTap != null) {
      widget.onVideoTap!(video);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_meditationVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: AppColors.primaryAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Latest Meditation Practices',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildMeditationVideosList(),
      ],
    );
  }

  Widget _buildMeditationVideosList() {
    return SizedBox(
      height: 220, // Increased to match card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _meditationVideos.length,
        itemBuilder: (context, index) {
          final video = _meditationVideos[index];
          return _buildMeditationVideoCard(video);
        },
      ),
    );
  }

  Widget _buildMeditationVideoCard(Video video) {
    return Container(
      width: 250,
      height: 100, // Increased height for better title visibility
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playVideo(video),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with play indicator
                Container(
                  height: 140, // Fixed height for thumbnail
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          child: Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.textSecondary.withOpacity(0.1),
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: AppColors.textSecondary,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // New meditation indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              
                              const SizedBox(width: 2),
                              Text(
                                'NEW',
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Watchlist button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: WatchlistButton(
                            video: video,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Duration
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                // Video info with more space
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(video.publishedAt),
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.self_improvement,
                color: AppColors.primaryAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'New Meditation Techniques',
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 250, // Match the updated list height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 250,
                height: 240, // Match card height
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 140, // Fixed thumbnail height
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 14,
                              width: 150,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
