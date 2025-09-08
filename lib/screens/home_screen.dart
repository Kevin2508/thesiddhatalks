import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';

import '../widgets/greeting_section.dart';
import '../widgets/recently_played_section.dart';
import '../widgets/new_meditation_techniques_section.dart';
import '../widgets/recommended_videos_section.dart';
import '../widgets/collapsible_playlist_card.dart';
import '../models/video_models.dart';
import '../services/firestore_video_service.dart';
import '../services/firestore_recently_played_service.dart';
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
  final GlobalKey<State<RecentlyPlayedSection>> _recentlyPlayedKey = GlobalKey<State<RecentlyPlayedSection>>();
  
  String? _expandedPlaylistId;
  
  // Firestore data
  List<PlaylistInfo> _playlists = [];
  Map<String, List<Video>> _playlistVideos = {};
  bool _isLoadingPlaylists = false;
  int _currentPlaylistPage = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Load data immediately when screen initializes
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
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Fetch all videos from Firestore
      final allFirestoreVideos = await FirestoreVideoService.fetchAllVideos();
      
      if (allFirestoreVideos.isEmpty) {
        setState(() {
          _playlists = [];
          _playlistVideos = {};
          _isLoadingPlaylists = false;
          _hasError = true;
          _errorMessage = 'No videos found in database';
        });
        return;
      }
      
      // Group videos by category
      final Map<String, List<Video>> categorizedVideos = {};
      
      for (final firestoreVideo in allFirestoreVideos) {
        final category = firestoreVideo.category;
        
        // Convert Firestore video to Video model
        final video = Video(
          id: firestoreVideo.id.toString(),
          title: firestoreVideo.titleEnglish.isNotEmpty 
              ? firestoreVideo.titleEnglish 
              : firestoreVideo.titleHindi,
          description: firestoreVideo.titleHindi.isNotEmpty 
              ? firestoreVideo.titleHindi 
              : firestoreVideo.titleEnglish,
          thumbnailUrl: firestoreVideo.thumbnail.isNotEmpty 
              ? firestoreVideo.thumbnail 
              : 'https://via.placeholder.com/200x120?text=Video+Thumbnail',
          duration: firestoreVideo.duration,
          publishedAt: firestoreVideo.publishedAt,
          channelTitle: 'Siddha Kutumbakam',
          pcloudUrl: firestoreVideo.pcloudLink,
          youtubeUrl: firestoreVideo.youtubeUrl,
        );
        
        if (!categorizedVideos.containsKey(category)) {
          categorizedVideos[category] = [];
        }
        categorizedVideos[category]!.add(video);
      }
      
      // Create playlists from categories
      final List<PlaylistInfo> playlistList = [];
      final Map<String, List<Video>> playlistVideosMap = {};
      
      int playlistIndex = 1;
      categorizedVideos.forEach((category, videos) {
        if (videos.isNotEmpty) {
          final playlistId = playlistIndex.toString();
          
          // Create playlist info
          playlistList.add(PlaylistInfo(
            id: playlistId,
            title: category,
            description: 'Videos in $category category',
            thumbnailUrl: videos.first.thumbnailUrl,
            videoCount: videos.length,
            publishedAt: DateTime.now(),
          ));
          
          // Store videos for this playlist
          playlistVideosMap[playlistId] = videos;
          playlistIndex++;
        }
      });
      
      setState(() {
        _playlists = playlistList;
        _playlistVideos = playlistVideosMap;
        _isLoadingPlaylists = false;
        _hasError = false;
        _errorMessage = '';
      });
    } catch (e) {
      String errorMessage = 'Error loading videos';
      if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied: Please check Firestore security rules';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Service unavailable: Please check your internet connection';
      } else {
        errorMessage = 'Error loading videos: ${e.toString()}';
      }
      
      setState(() {
        _playlists = [];
        _playlistVideos = {};
        _isLoadingPlaylists = false;
        _hasError = true;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadFirestoreData();
  }

  void _playVideo(Video video) {
    // Add to recently played when video is accessed
    FirestoreRecentlyPlayedService.addRecentlyPlayedVideo(video);
    
    // Use pCloud URL for direct video playback if available
    final videoUrl = video.pcloudUrl.isNotEmpty 
        ? video.pcloudUrl 
        : video.youtubeUrl; // Fallback to YouTube URL if pCloud not available
        
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HybridPlayerScreen(
          video: video,
          pcloudUrl: videoUrl,
        ),
      ),
    ).then((_) {
      // Refresh recently played section when returning from player
      if (_recentlyPlayedKey.currentState != null) {
        (_recentlyPlayedKey.currentState as dynamic).refresh();
      }
    });
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
      body: Stack(
        children: [
          // Background image overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/home_bg_header.png'),
                  
                  alignment: Alignment.topCenter,
                  opacity: 0.5,
                ),
              ),
            ),
          ),
          // Content overlay
          RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryAccent,
            backgroundColor: AppColors.cardBackground,
            child: CustomScrollView(
              controller: _pageScrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                              const GreetingSection(),
                              RecentlyPlayedSection(
                                key: _recentlyPlayedKey,
                                showAll: false, // Show only 3 videos on home screen
                                onSeeAll: () {
                                  // Navigate to the full recently played screen
                                  Navigator.pushNamed(context, '/recently-played');
                                },
                                onRefresh: () {
                                  // Recently played section refreshed
                                },
                              ),
                              const SizedBox(height: 25),
                              
                              NewMeditationTechniquesSection(
                                onVideoTap: _playVideo,
                              ),

                              
                              const SizedBox(height: 25),
                              
                              RecommendedVideosSection(
                                onVideoTap: _playVideo,
                              ),
                              const SizedBox(height: 25),
                              
                              _buildPlaylistsSection(),
                              const SizedBox(height: 30),
                              _buildYouTubeChannelsSection(),
                              const SizedBox(height: 30),
                              _buildSocialMediaSection(),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.transparent,
        ),
      ),
      actions: [
        // Donate button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/donation'),
            icon: Icon(Icons.favorite, size: 16, color: Colors.white),
            label: Text(
              'Donate',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
              minimumSize: const Size(80, 32),
            ),
          ),
        ),
        // User profile button
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryAccent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                    backgroundImage: authProvider.localProfilePicturePath != null
                        ? FileImage(File(authProvider.localProfilePicturePath!))
                        : authProvider.user?.photoURL != null
                            ? NetworkImage(authProvider.user!.photoURL!)
                            : null,
                    child: (authProvider.localProfilePicturePath == null && authProvider.user?.photoURL == null)
                        ? Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primaryAccent,
                    )
                        : null,
                  ),
                ),
              );
            },
          ),
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
                  fontSize: 18,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading playlists...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_hasError)
          Container(
            height: 350,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load playlists',
                      style: GoogleFonts.rajdhani(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadFirestoreData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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
        image: const DecorationImage(
          image: AssetImage('assets/images/follow_channel_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
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

  Widget _buildSocialMediaSection() {
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
              Icon(Icons.connect_without_contact, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stay Connected With Us',
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
              _buildSocialMediaButton(
                'Website',
                Icons.language,
                'https://www.siddhakutumbakam.org/',
                Colors.blue,
              ),
              _buildSocialMediaButton(
                'Instagram',
                Icons.camera_alt,
                'https://www.instagram.com/siddha_kutumbakam/?igsh=M3Y1MWl1Z2U0Nmhw#',
                Colors.pink,
              ),
              _buildSocialMediaButton(
                'Facebook',
                Icons.facebook,
                'https://www.facebook.com/share/16cD57ABsK/',
                Colors.blue[800]!,
              ),
              _buildSocialMediaButton(
                'WhatsApp',
                Icons.chat,
                'https://chat.whatsapp.com/FOKEBWK0JQQ8AFqLtdY6eA',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaButton(String title, IconData icon, String url, Color color) {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
