import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../widgets/hero_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/recently_played_section.dart';
import '../widgets/collapsible_playlist_card.dart';
import '../models/youtube_models.dart';
import '../models/firestore_video_models.dart' as firestore;
import '../services/firestore_video_service.dart';
import 'hybrid_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  final ScrollController _pageScrollController = ScrollController();
  
  String? _expandedPlaylistId;
  
  // Firestore data
  List<PlaylistInfo> _playlists = [];
  Map<String, List<YouTubeVideo>> _playlistVideos = {};
  bool _isLoadingPlaylists = false;
  int _currentPlaylistPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadFirestoreData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.forward();
      }
    });
  }

  Future<void> _loadFirestoreData() async {
    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      // Get all predefined categories
      final allCategoryNames = firestore.VideoCategory.getAllCategories();
      final List<PlaylistInfo> playlistList = [];
      final Map<String, List<YouTubeVideo>> playlistVideosMap = {};
      
      // Fetch all videos from Firestore once
      final allFirestoreVideos = await FirestoreVideoService.fetchAllVideos();
      
      // Create playlist for each category
      for (int i = 0; i < allCategoryNames.length; i++) {
        final categoryName = allCategoryNames[i];
        
        // Get videos for this category
        final categoryFirestoreVideos = allFirestoreVideos
            .where((video) => video.category == categoryName)
            .toList();
        
        // Convert Firestore videos to YouTube video format for compatibility
        final categoryYouTubeVideos = categoryFirestoreVideos.map((firestoreVideo) {
          return YouTubeVideo(
            id: firestoreVideo.id.toString(),
            title: firestoreVideo.titleEnglish,
            description: firestoreVideo.titleHindi,
            thumbnailUrl: firestoreVideo.thumbnail.isNotEmpty 
                ? firestoreVideo.thumbnail 
                : 'https://via.placeholder.com/200x120',
            duration: firestoreVideo.duration,
            viewCount: 1000, // Default view count
            likeCount: 50,   // Default like count
            publishedAt: firestoreVideo.publishedAt,
            channelTitle: 'Siddha Samadhi',
            pcloudUrl: firestoreVideo.pcloudLink, // Include pCloud URL
          );
        }).toList();
        
        // Create playlist info
        playlistList.add(PlaylistInfo(
          id: (i + 1).toString(),
          title: categoryName,
          description: firestore.VideoCategory.getCategoryDescription(categoryName),
          thumbnailUrl: 'https://via.placeholder.com/300x200',
          videoCount: categoryYouTubeVideos.length,
          publishedAt: DateTime.now(),
        ));
        
        // Store videos for this playlist
        playlistVideosMap[(i + 1).toString()] = categoryYouTubeVideos;
      }
      
      setState(() {
        _playlists = playlistList;
        _playlistVideos = playlistVideosMap;
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      print('Error loading Firestore data: $e');
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  void _playVideo(YouTubeVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HybridPlayerScreen(
          video: video,
          pcloudUrl: video.pcloudUrl,
        ),
      ),
    );
  }

  void _togglePlaylist(String playlistId) {
    setState(() {
      _expandedPlaylistId = _expandedPlaylistId == playlistId ? null : playlistId;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        controller: _pageScrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _scrollController.value)),
                  child: Opacity(
                    opacity: _scrollController.value,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const GreetingSection(),
                        const SizedBox(height: 20),
                        const RecentlyPlayedSection(),
                        const SizedBox(height: 25),
                        
                        _buildPlaylistsSection(),
                        const SizedBox(height: 30),
                        _buildYouTubeChannelsSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primaryBackground.withOpacity(0.95),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryAccent.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: HeroCard(),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.playlist_play, color: AppColors.primaryAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                'All Playlists',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (_isLoadingPlaylists)
          Container(
            height: 350,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
            ),
          )
        else
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _expandedPlaylistId != null ? 500 : 350, // Dynamic height based on expansion
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _playlists.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No categories available',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      _currentPlaylistPage = index;
                    });
                  },
                  itemCount: (_playlists.length / 4).ceil(),
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * 4;
                    final endIndex = (startIndex + 4 > _playlists.length) 
                        ? _playlists.length 
                        : startIndex + 4;
                    final pagePlaylist = _playlists.sublist(startIndex, endIndex);
                    
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...pagePlaylist.asMap().entries.map((entry) {
                              final index = startIndex + entry.key;
                              final playlist = entry.value;
                              final videos = _playlistVideos[playlist.id] ?? [];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CollapsiblePlaylistCard(
                                  playlist: playlist,
                                  videos: videos,
                                  isExpanded: _expandedPlaylistId == playlist.id,
                                  onToggle: () => _togglePlaylist(playlist.id),
                                  onVideoTap: _playVideo,
                                  index: index,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if ((_playlists.length / 4).ceil() > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    (_playlists.length / 4).ceil(),
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPlaylistPage == index
                            ? AppColors.primaryAccent
                            : AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildYouTubeChannelsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.subscriptions, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Follow Our Channels',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularChannelButton(
                'The Siddha Talks',
                'assets/images/thesiddhatalks_logo.jpg',
                'https://www.youtube.com/@TheSiddhaTalks',
              ),
              _buildCircularChannelButton(
                'Siddh Vachan',
                'assets/images/siddhvachan_logo.png',
                'https://www.youtube.com/@SiddhVachan',
              ),
              _buildCircularChannelButton(
                'Divya Dhyanam',
                'assets/images/meditation_logo.png',
                'https://www.youtube.com/@Meditation-j2t',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularChannelButton(String title, String logoPath, String url) {
    return InkWell(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open $title')),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryAccent.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                logoPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryAccent.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.play_circle_fill,
                      color: AppColors.primaryAccent,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 90,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
