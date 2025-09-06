import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';

class HybridPlayerScreen extends StatefulWidget {
  final Video? video;
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
    } else if (widget.video?.youtubeUrl?.isNotEmpty == true) {
      // Fallback to YouTube URL if no pCloud URL
      _testUrls.add(widget.video!.youtubeUrl!);
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
    
    print('Original URL: $originalUrl'); // Debug logging
    
    // Add original URL first
    _testUrls.add(originalUrl);
    
    // Handle different pCloud URL formats
    if (originalUrl.contains('pcloud.com')) {
      // Handle publink format: https://my.pcloud.com/publink/show?code=XYZ
      if (originalUrl.contains('/publink/show?code=')) {
        String code = originalUrl.split('code=')[1].split('&')[0];
        // Try direct download links
        _testUrls.add('https://api.pcloud.com/getpubthumb?code=$code&linkcodetype=upload&size=1920x1080&type=auto');
        _testUrls.add('https://filedn.eu/l$code');
        _testUrls.add('https://p-def6.pcloud.com/cBZ$code');
      }
      
      // Handle direct pCloud links
      if (originalUrl.contains('pcloud.link')) {
        // Try different variations of pcloud.link URLs
        _testUrls.add(originalUrl.replaceAll('pcloud.link', 'filedn.eu'));
      }
      
      // Add /download suffix if not present
      if (!originalUrl.contains('/download') && !originalUrl.contains('?')) {
        _testUrls.add('$originalUrl/download');
      }
      
      // Try different pCloud domains
      _testUrls.add(originalUrl.replaceAll('my.pcloud.com', 'filedn.eu'));
      _testUrls.add(originalUrl.replaceAll('my.pcloud.com', 'e1.pcloud.link'));
    }
    
    // Don't add YouTube URLs to direct video player - they need special handling
    // Instead, we'll handle them separately
    
    // Remove duplicates while preserving order
    _testUrls = _testUrls.toSet().toList();
    
    print('Test URLs prepared: $_testUrls'); // Debug logging
  }

  Future<void> _tryNextUrl() async {
    if (_currentUrlIndex >= _testUrls.length) {
      // If we've tried all pCloud URLs and failed, show YouTube fallback option
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to play video directly. All ${_testUrls.length} formats failed.\n\nThis might be because the video requires special playback or the URLs are not direct video files.';
        _isLoading = false;
      });
      return;
    }

    final currentUrl = _testUrls[_currentUrlIndex];
    print('Trying URL ${_currentUrlIndex + 1}/${_testUrls.length}: $currentUrl'); // Debug logging

    // Skip YouTube URLs for direct playback
    if (currentUrl.contains('youtube.com') || currentUrl.contains('youtu.be')) {
      print('Skipping YouTube URL - not suitable for direct playback');
      _currentUrlIndex++;
      _tryNextUrl();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Dispose previous controller if exists
      await _videoPlayerController?.dispose();
      _chewieController?.dispose();

      // Create new video player controller with improved headers
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(currentUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5',
          'Accept-Encoding': 'identity',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Range': 'bytes=0-',
          'Referer': 'https://pcloud.com/',
          'Sec-Fetch-Dest': 'video',
          'Sec-Fetch-Mode': 'no-cors',
          'Sec-Fetch-Site': 'cross-site',
        },
      );

      // Set timeout and try to initialize with longer timeout for slow connections
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout after 15 seconds');
        },
      );

      // If initialization successful, create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true, // Changed to true for better user experience
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

      print('Successfully loaded video from: $currentUrl'); // Debug logging

    } catch (e) {
      print('Failed to load URL ${_currentUrlIndex + 1}: $e'); // Debug logging
      _currentUrlIndex++;
      
      // Add a small delay before trying the next URL to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 500));
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tried ${_currentUrlIndex + 1}/${_testUrls.length} formats',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 10,
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
                  'Try Alternative Format (${_currentUrlIndex + 2}/${_testUrls.length})',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _currentUrlIndex = 0;
                    _tryNextUrl();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Retry All',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openInBrowser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Open in Browser',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.video?.youtubeUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openYouTubeInApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: Icon(Icons.play_circle_filled, color: Colors.white, size: 18),
                label: Text(
                  'Watch on YouTube',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
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
                    'Direct Play (${_currentUrlIndex + 1}/${_testUrls.length})',
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
            _buildDetailRow('Status', 'Playing directly from source (Format ${_currentUrlIndex + 1}/${_testUrls.length})'),
          if (!_useDirectUrl && _hasError)
            _buildDetailRow('Status', 'Failed to load video'),
          if (widget.pcloudUrl?.isNotEmpty == true)
            _buildDetailRow('pCloud URL', widget.pcloudUrl!.length > 50 ? 
              '${widget.pcloudUrl!.substring(0, 50)}...' : widget.pcloudUrl!),
          if (widget.video?.youtubeUrl?.isNotEmpty == true)
            _buildDetailRow('YouTube URL', widget.video!.youtubeUrl!.length > 50 ? 
              '${widget.video!.youtubeUrl!.substring(0, 50)}...' : widget.video!.youtubeUrl!),
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
            title: Text('Retry with different format'),
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
    String urlToOpen = widget.pcloudUrl ?? '';
    
    // If we have a YouTube URL as fallback, prefer that for browser opening
    if (urlToOpen.isEmpty || (!urlToOpen.contains('youtube.com') && !urlToOpen.contains('youtu.be'))) {
      if (widget.video?.youtubeUrl?.isNotEmpty == true) {
        urlToOpen = widget.video!.youtubeUrl!;
      }
    }
    
    if (urlToOpen.isNotEmpty) {
      try {
        final uri = Uri.parse(urlToOpen);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Unable to open URL in browser');
        }
      } catch (e) {
        _showSnackBar('Invalid URL format');
      }
    } else {
      _showSnackBar('No URL available to open');
    }
  }

  void _openYouTubeInApp() async {
    if (widget.video?.youtubeUrl?.isNotEmpty == true) {
      try {
        final uri = Uri.parse(widget.video!.youtubeUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Unable to open YouTube video');
        }
      } catch (e) {
        _showSnackBar('Invalid YouTube URL format');
      }
    } else {
      _showSnackBar('No YouTube URL available');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primaryAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
