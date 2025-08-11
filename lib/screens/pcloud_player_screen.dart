import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';

class PCloudPlayerScreen extends StatefulWidget {
  final YouTubeVideo? video;
  final String? pcloudUrl;

  const PCloudPlayerScreen({
    Key? key, 
    this.video,
    this.pcloudUrl,
  }) : super(key: key);

  @override
  State<PCloudPlayerScreen> createState() => _PCloudPlayerScreenState();
}

class _PCloudPlayerScreenState extends State<PCloudPlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // About, Related
    
    if (widget.pcloudUrl != null && widget.pcloudUrl!.isNotEmpty) {
      _initializePlayer();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video URL provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Convert pCloud URL to streaming URL if needed
      String videoUrl = await _processVideoUrl(widget.pcloudUrl!);
      
      print('Attempting to play video URL: $videoUrl'); // Debug log

      // Initialize video player with processed URL
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
      );

      await _videoPlayerController!.initialize();

      // Initialize Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryAccent,
          handleColor: AppColors.primaryAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.withOpacity(0.5),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryAccent,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video playback error',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _tryAlternativePlayer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                    child: Text(
                      'Try Alternative Player',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Listen for fullscreen changes
      _chewieController!.addListener(() {
        if (mounted) {
          final isCurrentlyFullScreen = _chewieController!.isFullScreen;
          if (isCurrentlyFullScreen != _isFullScreen) {
            setState(() {
              _isFullScreen = isCurrentlyFullScreen;
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
        }
      });

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to process pCloud URLs and convert them to streamable format
  Future<String> _processVideoUrl(String pcloudUrl) async {
    try {
      // Check if it's already a direct video URL
      if (pcloudUrl.contains('.mp4') || pcloudUrl.contains('.m3u8') || pcloudUrl.contains('.webm')) {
        return pcloudUrl;
      }
      
      // If it's a pCloud share link, try to convert it to direct download
      if (pcloudUrl.contains('pcloud.com')) {
        // Try to extract file ID and convert to direct link
        if (pcloudUrl.contains('/publink/show?code=')) {
          String code = pcloudUrl.split('code=')[1].split('&')[0];
          return 'https://filedn.eu/l${code}';
        }
        // For other pCloud formats, try adding /download at the end
        if (!pcloudUrl.endsWith('/download')) {
          return '$pcloudUrl/download';
        }
      }
      
      return pcloudUrl;
    } catch (e) {
      print('Error processing video URL: $e');
      return pcloudUrl;
    }
  }

  // Alternative player method using WebView or external browser
  void _tryAlternativePlayer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Alternative Playback',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'The video cannot be played in the app. Would you like to open it in your browser?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          backgroundColor: AppColors.cardBackground,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (widget.pcloudUrl != null) {
                  final uri = Uri.parse(widget.pcloudUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
              ),
              child: Text(
                'Open in Browser',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          title: const Text('Video Player'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No video selected'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _chewieController?.exitFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: _isFullScreen 
          ? _buildPlayer()  // Show only player in fullscreen
          : SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildPlayer(),
                  _buildContentSection(),
                ],
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
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _shareVideo(),
            child: Container(
              padding: const EdgeInsets.all(8),
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
              child: const Icon(
                Icons.share,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryAccent,
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to play video',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }

    return Container(
      height: 200,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryAccent,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoInfo(),
            const SizedBox(height: 20),
            _buildTabSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video!.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.video!.description.isNotEmpty) ...[
            Text(
              widget.video!.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.video!.channelTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.video!.duration,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryAccent,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Related'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutTab(),
              _buildRelatedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Duration', widget.video!.duration),
          _buildDetailRow('Channel', widget.video!.channelTitle),
          _buildDetailRow('Published', _formatDate(widget.video!.publishedAt)),
        ],
      ),
    );
  }

  Widget _buildRelatedTab() {
    return const Center(
      child: Text(
        'Related videos coming soon',
        style: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _shareVideo() {
    if (widget.video != null) {
      Share.share(
        'Check out this video: ${widget.video!.title}\n\n${widget.pcloudUrl ?? 'Video from The Siddha Talks'}',
        subject: widget.video!.title,
      );
    }
  }
}
