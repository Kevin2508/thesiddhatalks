import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/hero_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/youtube_playlist_carousel.dart';
import '../services/youtube_service.dart';
import '../models/youtube_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  final ScrollController _pageScrollController = ScrollController();
  final YouTubeService _youtubeService = YouTubeService();

  List<PlaylistInfo> _playlists = [];
  Map<String, List<YouTubeVideo>> _playlistVideos = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.forward();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load playlists
      final playlists = await _youtubeService.getChannelPlaylists();

      // Load videos for each playlist (limited for home page)
      final Map<String, List<YouTubeVideo>> playlistVideos = {};

      for (final playlist in playlists.take(3)) { // Show only first 3 playlists on home
        final videos = await _youtubeService.getPlaylistVideos(
          playlist.id,
          maxResults: 5, // Show only 5 videos per playlist on home
        );
        playlistVideos[playlist.id] = videos;
      }

      setState(() {
        _playlists = playlists;
        _playlistVideos = playlistVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            controller: _pageScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.primaryBackground,
                elevation: 0,
                title: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 112,
                      height: 112,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),

              // Main Content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Greeting Section
                        _buildAnimatedSection(
                          interval: const Interval(0.0, 0.3, curve: Curves.easeOut),
                          child: const GreetingSection(),
                        ),

                        // Hero Card
                        _buildAnimatedSection(
                          interval: const Interval(0.2, 0.5, curve: Curves.easeOut),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: HeroCard(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Error handling
                        if (_error != null)
                          _buildErrorWidget()
                        else if (_isLoading)
                          _buildLoadingWidget()
                        else
                          ..._buildPlaylistSections(),

                        // Bottom padding
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 80,
                        ),
                      ],
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

  List<Widget> _buildPlaylistSections() {
    return _playlists.take(3).map((playlist) {
      final videos = _playlistVideos[playlist.id] ?? [];

      return _buildAnimatedSection(
        interval: const Interval(0.4, 0.7, curve: Curves.easeOut),
        child: Column(
          children: [
            YouTubePlaylistCarousel(
              playlist: playlist,
              videos: videos,
              onSeeAll: () => _navigateToPlaylistView(playlist),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading meditation content...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylistView(PlaylistInfo playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistVideosScreen(playlist: playlist),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required Interval interval,
    required Widget child,
  }) {
    final animation = CurvedAnimation(
      parent: _scrollController,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final opacity = animation.value.clamp(0.0, 1.0);
        final slideValue = (0.3 * (1 - animation.value)).clamp(0.0, 0.3);

        return FadeTransition(
          opacity: AlwaysStoppedAnimation(opacity),
          child: SlideTransition(
            position: AlwaysStoppedAnimation(Offset(0, slideValue)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }
}

// Screen to show all videos in a playlist
class PlaylistVideosScreen extends StatefulWidget {
  final PlaylistInfo playlist;

  const PlaylistVideosScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  State<PlaylistVideosScreen> createState() => _PlaylistVideosScreenState();
}

class _PlaylistVideosScreenState extends State<PlaylistVideosScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  List<YouTubeVideo> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllVideos();
  }

  Future<void> _loadAllVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final videos = await _youtubeService.getPlaylistVideos(
        widget.playlist.id,
        maxResults: 50, // Load all videos
      );

      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.playlist.title,
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadAllVideos,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return YouTubeVideoListItem(
            video: _videos[index],
            onTap: () => _playVideo(_videos[index]),
          );
        },
      ),
    );
  }

  void _playVideo(YouTubeVideo video) {
    // Navigate to player with video ID
    Navigator.pushNamed(
      context,
      '/player',
      arguments: video,
    );
  }
}