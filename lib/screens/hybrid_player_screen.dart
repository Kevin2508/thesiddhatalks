import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/youtube_models.dart';

class HybridPlayerScreen extends StatefulWidget {
  final YouTubeVideo? video;
  final String? pcloudUrl;

  const HybridPlayerScreen({
    Key? key, 
    this.video,
    this.pcloudUrl,
  }) : super(key: key);

  @override
  State<HybridPlayerScreen> createState() => _HybridPlayerScreenState();
}

class _HybridPlayerScreenState extends State<HybridPlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _useDirectUrl = false;

  // Test URLs to try in order
  List<String> _testUrls = [];
  int _currentUrlIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.pcloudUrl != null && widget.pcloudUrl!.isNotEmpty) {
      _prepareTestUrls();
      _tryNextUrl();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video URL provided';
        _isLoading = false;
      });
    }
  }

  void _prepareTestUrls() {
    _testUrls.clear();
    final originalUrl = widget.pcloudUrl!;
    
    // Add multiple URL variations to test
    _testUrls.add(originalUrl); // Original URL
    
    // Try pCloud direct download variations
    if (originalUrl.contains('pcloud.com')) {
      if (originalUrl.contains('/publink/show?code=')) {
        String code = originalUrl.split('code=')[1].split('&')[0];
        _testUrls.add('https://filedn.eu/l$code');
        _testUrls.add('https://p-def6.pcloud.com/dl$code');
      }
      
      // Add /download if not present
      if (!originalUrl.endsWith('/download')) {
        _testUrls.add('$originalUrl/download');
      }
      
      // Try with different pCloud domains
      _testUrls.add(originalUrl.replaceAll('pcloud.com', 'filedn.eu'));
      _testUrls.add(originalUrl.replaceAll('pcloud.com', 'p-def6.pcloud.com'));
    }
    
    // Add sample video for testing (remove this in production)
    _testUrls.add('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
  }

  Future<void> _tryNextUrl() async {
    if (_currentUrlIndex >= _testUrls.length) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to play video with any available URL format';
        _isLoading = false;
      });
      return;
    }

    final currentUrl = _testUrls[_currentUrlIndex];
    print('Trying URL ${ _currentUrlIndex + 1}/${_testUrls.length}: $currentUrl');

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Dispose previous controller if exists
      await _videoPlayerController?.dispose();
      _chewieController?.dispose();

      // Create new video player controller
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(currentUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
          'Range': 'bytes=0-',
        },
      );

      // Set timeout and try to initialize
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // If initialization successful, create Chewie controller
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
          return _buildErrorWidget(errorMessage);
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
        _useDirectUrl = true;
      });

      print('Successfully loaded video with URL: $currentUrl');

    } catch (e) {
      print('Failed to load URL ${ _currentUrlIndex + 1}: $e');
      _currentUrlIndex++;
      _tryNextUrl();
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
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
            if (_currentUrlIndex < _testUrls.length - 1) ...[
              ElevatedButton(
                onPressed: () {
                  _currentUrlIndex++;
                  _tryNextUrl();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                ),
                child: Text(
                  'Try Next URL',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _openInBrowser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
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
        ),
      ),
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

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) {
        if (_isFullScreen) {
          _chewieController?.exitFullScreen();
        }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (_currentUrlIndex > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Trying URL ${_currentUrlIndex + 1}/${_testUrls.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
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
                onPressed: () {
                  _currentUrlIndex = 0;
                  _tryNextUrl();
                },
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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _openInBrowser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
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
              if (_useDirectUrl) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Direct Play',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
              Tab(text: 'Settings'),
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
              _buildSettingsTab(),
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
          if (_useDirectUrl) 
            _buildDetailRow('Status', 'Playing directly from source'),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Playback Options',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.refresh, color: AppColors.primaryAccent),
            title: Text('Retry with different URL'),
            subtitle: Text('Try alternative streaming formats'),
            onTap: () {
              _currentUrlIndex = 0;
              _tryNextUrl();
            },
          ),
          ListTile(
            leading: Icon(Icons.open_in_browser, color: AppColors.primaryAccent),
            title: Text('Open in browser'),
            subtitle: Text('Use external browser for playback'),
            onTap: _openInBrowser,
          ),
        ],
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

  void _openInBrowser() async {
    if (widget.pcloudUrl != null) {
      final uri = Uri.parse(widget.pcloudUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
