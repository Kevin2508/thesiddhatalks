import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import '../services/firestore_video_service.dart';
import 'watchlist_button.dart';

class RecommendedVideosSection extends StatefulWidget {
  final Function(Video)? onVideoTap;
  
  const RecommendedVideosSection({
    Key? key, 
    this.onVideoTap,
  }) : super(key: key);

  @override
  State<RecommendedVideosSection> createState() => _RecommendedVideosSectionState();
}

class _RecommendedVideosSectionState extends State<RecommendedVideosSection> {
  List<Video> _recommendedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedVideos();
  }

  Future<void> _loadRecommendedVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch videos from Firestore and get popular/recommended ones
      final allVideos = await FirestoreVideoService.fetchAllVideos();
      
      // Filter for popular categories and sort by publish date (newer first)
      final recommendedVideos = allVideos
          .where((video) => 
              video.category.toLowerCase().contains('wisdom') ||
              video.category.toLowerCase().contains('spiritual') ||
              video.category.toLowerCase().contains('enlightenment') ||
              video.titleEnglish.toLowerCase().contains('wisdom') ||
              video.titleEnglish.toLowerCase().contains('spiritual') ||
              video.titleHindi.toLowerCase().contains('ज्ञान') ||
              video.titleHindi.toLowerCase().contains('आध्यात्म'))
          .toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); // Sort by newest first
        
      final convertedVideos = recommendedVideos
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
                : 'https://via.placeholder.com/200x120?text=Recommended+Video',
            duration: firestoreVideo.duration,
            publishedAt: firestoreVideo.publishedAt,
            channelTitle: 'Siddha Kutumbakam',
            pcloudUrl: firestoreVideo.pcloudLink,
            youtubeUrl: firestoreVideo.youtubeUrl,
          ))
          .toList();

      setState(() {
        _recommendedVideos = convertedVideos;
        _isLoading = false;
      });

      // If no videos found, show dummy data to ensure section is visible
      if (_recommendedVideos.isEmpty) {
        setState(() {
          _recommendedVideos = _generateDummyRecommendedVideos();
        });
      }
    } catch (e) {
      print('Error loading recommended videos: $e');
      // Provide fallback dummy data to ensure section is always visible
      setState(() {
        _recommendedVideos = _generateDummyRecommendedVideos();
        _isLoading = false;
      });
    }
  }

  void _playVideo(Video video) {
    if (widget.onVideoTap != null) {
      widget.onVideoTap!(video);
    }
  }

  List<Video> _generateDummyRecommendedVideos() {
    return [
      Video(
        id: 'rec1',
        title: 'The Path to Inner Wisdom',
        description: 'Discover the ancient teachings that lead to enlightenment',
        thumbnailUrl: 'https://via.placeholder.com/200x120?text=Wisdom+Path',
        duration: '15:30',
        channelTitle: 'Siddha Kutumbakam',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        pcloudUrl: '',
        youtubeUrl: '',
      ),
      Video(
        id: 'rec2',
        title: 'Meditation for Spiritual Growth',
        description: 'Advanced meditation techniques for deeper understanding',
        thumbnailUrl: 'https://via.placeholder.com/200x120?text=Meditation',
        duration: '22:15',
        channelTitle: 'Siddha Kutumbakam',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        pcloudUrl: '',
        youtubeUrl: '',
      ),
      Video(
        id: 'rec3',
        title: 'Understanding Universal Consciousness',
        description: 'Explore the nature of consciousness and reality',
        thumbnailUrl: 'https://via.placeholder.com/200x120?text=Consciousness',
        duration: '18:45',
        channelTitle: 'Siddha Kutumbakam',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        pcloudUrl: '',
        youtubeUrl: '',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_recommendedVideos.isEmpty) {
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
                Icons.recommend,
                color: AppColors.primaryAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended Videos',
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
        _buildRecommendedVideosList(),
      ],
    );
  }

  Widget _buildRecommendedVideosList() {
    return SizedBox(
      height: 250, // Increased to match card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _recommendedVideos.length,
        itemBuilder: (context, index) {
          final video = _recommendedVideos[index];
          return _buildRecommendedVideoCard(video);
        },
      ),
    );
  }

  Widget _buildRecommendedVideoCard(Video video) {
    return Container(
      width: 250,
      height: 240, // Increased height for better title visibility
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
                      // Recommended indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              
                              const SizedBox(width: 2),
                              Text(
                                'RECOMMENDED',
                                style: GoogleFonts.lato(
                                  fontSize: 9,
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
                          video.channelTitle,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                Icons.recommend,
                color: AppColors.primaryAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended Videos',
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
}
