import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkify/linkify.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';
import '../services/youtube_service.dart';
import '../widgets/playlist_carousel.dart';

class PlayerScreen extends StatefulWidget {
  final YouTubeVideo? video;

  const PlayerScreen({Key? key, this.video}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late YoutubePlayerController _youtubeController;
  final YouTubeService _youtubeService = YouTubeService();

  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  List<YouTubeVideo> _relatedVideos = [];
  List<Comment> _comments = [];
  bool _isLoadingRelated = true;
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // About, Comments, Related

    if (widget.video != null) {
      _initializePlayer();
      _loadRelatedContent();
    }
  }

  void _initializePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.video!.id,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
        startAt: 0,
        forceHD: false,
        controlsVisibleAtStart: true,
        hideControls: false,
        hideThumbnail: false,
        disableDragSeek: false,
        useHybridComposition: true,
      ),
    );
    
    // Add listener for fullscreen changes
    _youtubeController.addListener(() {
      if (_youtubeController.value.isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = _youtubeController.value.isFullScreen;
        });
        
        if (_isFullScreen) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        }
      }
    });
  }

  Future<void> _loadRelatedContent() async {
    try {
      // Load related videos from the same channel
      final uploads = await _youtubeService.getChannelUploads(maxResults: 10);
      final related = uploads.where((v) => v.id != widget.video!.id).take(8).toList();

      setState(() {
        _relatedVideos = related;
        _isLoadingRelated = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRelated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          title: Text('Video Player'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No video selected'),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        setState(() {
          _isFullScreen = true;
        });
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        // Hide system UI for true fullscreen experience
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
      onExitFullScreen: () {
        setState(() {
          _isFullScreen = false;
        });
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        // Restore system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryAccent,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primaryAccent,
          handleColor: AppColors.primaryAccent,
        ),
        bottomActions: [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
          FullScreenButton(),
        ],
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (data) {
          // Auto-play next video or show completion
          _showVideoCompleted();
        },
      ),
      builder: (context, player) => WillPopScope(
        onWillPop: () async {
          // Handle back button press
          if (_isFullScreen) {
            _youtubeController.toggleFullScreenMode();
            return false; // Don't exit the screen
          }
          return true; // Allow normal back navigation
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: _isFullScreen 
            ? player  // Show only player in fullscreen
            : SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar (hidden in fullscreen)
                    _buildAppBar(),

                    // Video Player
                    player,

                    // Content below player
                    _buildContentSection(),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.video!.title,
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: _shareVideo,
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          IconButton(
            onPressed: _toggleFullScreen,
            icon: const Icon(
              Icons.fullscreen,
              color: AppColors.textSecondary,
            ),
          ),
          IconButton(
            onPressed: _openInYouTube,
            icon: const Icon(
              Icons.open_in_new,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      child: Column(
        children: [
          // Video Info
          _buildVideoInfo(),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryAccent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryAccent,
              labelStyle: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Related'),
                Tab(text: 'Comments'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildRelatedTab(),
                _buildCommentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video!.title,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatViewCount(widget.video!.viewCount),
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatViewCount(widget.video!.likeCount),
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.video!.duration,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(widget.video!.publishedAt),
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'About This Video',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClickableDescription(),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInfoChip('Channel', widget.video!.channelTitle),
                const SizedBox(width: 12),
                _buildInfoChip('Category', VideoCategory.categorizeVideo(
                    widget.video!.title,
                    widget.video!.description
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableDescription() {
    final description = widget.video!.description.isNotEmpty
        ? widget.video!.description
        : 'Experience this beautiful meditation session designed to bring peace and mindfulness to your day.';

    return Linkify(
      onOpen: (link) async {
        if (await canLaunchUrl(Uri.parse(link.url))) {
          await launchUrl(
            Uri.parse(link.url),
            mode: LaunchMode.externalApplication,
          );
        }
      },
      text: description,
      style: GoogleFonts.lato(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      linkStyle: GoogleFonts.lato(
        fontSize: 16,
        color: AppColors.primaryAccent,
        height: 1.6,
        decoration: TextDecoration.underline,
      ),
      options: const LinkifyOptions(humanize: false),
    );
  }
  Widget _buildRelatedTab() {
    if (_isLoadingRelated) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _relatedVideos.length,
      itemBuilder: (context, index) {
        final video = _relatedVideos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: YouTubeVideoListItem(
            video: video,
            onTap: () => _playRelatedVideo(video),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Comments',
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your thoughts and connect\nwith fellow practitioners',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openInYouTube,
            icon: const Icon(Icons.comment),
            label: Text('View on YouTube'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],

      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _shareVideo() {
    final url = 'https://youtu.be/${widget.video!.id}';
    Share.share(
      '${widget.video!.title}\n\n$url',
      subject: 'Check out this meditation video',
    );
  }

  void _toggleFullScreen() {
    _youtubeController.toggleFullScreenMode();
  }

  void _openInYouTube() async {
    final url = 'https://youtu.be/${widget.video!.id}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _playRelatedVideo(YouTubeVideo video) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(video: video),
      ),
    );
  }

  void _showVideoCompleted() {
    if (_relatedVideos.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Video Completed',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Would you like to watch the next video?',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'No, thanks',
                  style: GoogleFonts.lato(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _playRelatedVideo(_relatedVideos.first);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text('Play Next'),
              ),
            ],
          );
        },
      );
    }
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String _timeAgo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _tabController.dispose();
    // Reset orientation and system UI when leaving the screen
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

// Simple comment model for future implementation
class Comment {
  final String id;
  final String author;
  final String content;
  final DateTime publishedAt;
  final int likeCount;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.publishedAt,
    required this.likeCount,
  });
}