import 'package:flutter/foundation.dart';
import '../models/firestore_video_models.dart';
import '../services/firestore_video_service.dart';

class VideoProvider extends ChangeNotifier {
  // Categories and videos data
  Map<String, VideoCategory> _categories = {};
  List<FirestoreVideo> _allVideos = [];
  List<FirestoreVideo> _recentVideos = [];
  List<FirestoreVideo> _popularVideos = [];
  
  // UI state
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _displayedCategoriesCount = 3; // Start with 3 categories like playlists
  
  // Cache for performance
  static bool _isSessionInitialized = false;
  static Map<String, VideoCategory>? _sessionCategories;
  static List<FirestoreVideo>? _sessionRecentVideos;
  
  // Getters
  Map<String, VideoCategory> get categories => _categories;
  List<VideoCategory> get displayedCategories => 
      _categories.values.take(_displayedCategoriesCount).toList();
  List<VideoCategory> get allCategoriesList => _categories.values.toList();
  List<FirestoreVideo> get allVideos => _allVideos;
  List<FirestoreVideo> get recentVideos => _recentVideos;
  List<FirestoreVideo> get popularVideos => _popularVideos;
  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreCategories => _displayedCategoriesCount < _categories.length;
  
  // Category-specific getters
  List<FirestoreVideo> getVideosForCategory(String categoryName) {
    return _categories[categoryName]?.videos ?? [];
  }
  
  VideoCategory? getCategory(String categoryName) {
    return _categories[categoryName];
  }

  // Initialize data
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _setError(null);
      
      print('🎬 Initializing Video Provider with Firestore data...');
      final stopwatch = Stopwatch()..start();
      
      // Check session cache first
      if (_isSessionInitialized && 
          _sessionCategories != null && 
          _sessionRecentVideos != null) {
        print('📱 Using session-cached video data');
        _categories = Map.from(_sessionCategories!);
        _recentVideos = List.from(_sessionRecentVideos!);
        _allVideos = _categories.values.expand((cat) => cat.videos).toList();
        _setLoading(false);
        stopwatch.stop();
        print('✅ Video data loaded from session cache in ${stopwatch.elapsedMilliseconds}ms');
        return;
      }
      
      // Load fresh data from Firestore
      await _loadDataFromFirestore();
      
      // Cache in session
      _sessionCategories = Map.from(_categories);
      _sessionRecentVideos = List.from(_recentVideos);
      _isSessionInitialized = true;
      
      stopwatch.stop();
      print('✅ Video data initialized in ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Loaded ${_categories.length} categories, ${_allVideos.length} total videos');
      
    } catch (e) {
      print('❌ Error initializing video data: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load data from Firestore
  Future<void> _loadDataFromFirestore() async {
    // Load categories with videos
    _categories = await FirestoreVideoService.fetchCategoriesWithVideos();
    
    // Extract all videos
    _allVideos = _categories.values.expand((cat) => cat.videos).toList();
    
    // Load recent videos
    _recentVideos = await FirestoreVideoService.getRecentVideos(limit: 10);
    
    // Load popular videos (for future use)
    _popularVideos = await FirestoreVideoService.getPopularVideos(limit: 10);
  }

  // Refresh data (manual refresh)
  Future<void> refreshData() async {
    try {
      print('🔄 Refreshing video data from Firestore...');
      _setError(null);
      
      final stopwatch = Stopwatch()..start();
      
      await _loadDataFromFirestore();
      
      // Update session cache
      _sessionCategories = Map.from(_categories);
      _sessionRecentVideos = List.from(_recentVideos);
      
      notifyListeners();
      
      stopwatch.stop();
      print('✅ Video data refreshed in ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      print('❌ Error refreshing video data: $e');
      _setError(e.toString());
    }
  }

  // Load more categories (for pagination)
  Future<void> loadMoreCategories() async {
    if (_isLoadingMore || !hasMoreCategories) return;
    
    try {
      _setLoadingMore(true);
      
      // Simulate loading delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      const batchSize = 2;
      final newCount = _displayedCategoriesCount + batchSize;
      _displayedCategoriesCount = newCount > _categories.length 
          ? _categories.length 
          : newCount;
      
      print('📊 Loaded ${_displayedCategoriesCount}/${_categories.length} categories');
      
    } finally {
      _setLoadingMore(false);
    }
  }

  // Search videos
  Future<List<FirestoreVideo>> searchVideos(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      print('🔍 Searching videos for: "$query"');
      final results = await FirestoreVideoService.searchVideos(query);
      print('🔍 Found ${results.length} search results');
      return results;
    } catch (e) {
      print('❌ Error searching videos: $e');
      return [];
    }
  }

  // Get video by ID
  Future<FirestoreVideo?> getVideoById(int videoId) async {
    try {
      return await FirestoreVideoService.getVideoById(videoId);
    } catch (e) {
      print('❌ Error getting video by ID: $e');
      return null;
    }
  }

  // Get videos for a specific category with lazy loading
  Future<List<FirestoreVideo>> loadCategoryVideos(String categoryName, {int limit = 10}) async {
    try {
      final videos = await FirestoreVideoService.fetchVideosByCategory(categoryName);
      return videos.take(limit).toList();
    } catch (e) {
      print('❌ Error loading category videos: $e');
      return [];
    }
  }

  // Get app statistics
  Future<Map<String, int>> getVideoStats() async {
    try {
      return await FirestoreVideoService.getVideoStats();
    } catch (e) {
      print('❌ Error getting video stats: $e');
      return {};
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Reset session cache (for logout or data refresh)
  static void clearSessionCache() {
    _isSessionInitialized = false;
    _sessionCategories = null;
    _sessionRecentVideos = null;
    print('🧹 Video session cache cleared');
  }

  // Check if video can be played
  bool canPlayVideo(FirestoreVideo video) {
    return video.canPlay && video.isAvailable;
  }

  // Get streaming URL for video
  String getVideoStreamingUrl(FirestoreVideo video) {
    return FirestoreVideoService.getStreamingUrl(video.pcloudLink);
  }

  // Get category by name (helper method)
  VideoCategory? getCategoryByName(String name) {
    return _categories[name];
  }

  // Get categories by availability
  List<VideoCategory> getAvailableCategories() {
    return _categories.values
        .where((category) => category.availableVideosCount > 0)
        .toList();
  }

  // Get video count summary
  String getVideoCountSummary() {
    final total = _allVideos.length;
    final available = _allVideos.where((v) => v.isAvailable).length;
    return '$available/$total videos available';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
