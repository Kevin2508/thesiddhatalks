import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/youtube_models.dart';
import 'youtube_firebase_cache.dart';

class OptimizedYouTubeService {
  static const String _baseUrl = ApiConfig.youtubeBaseUrl;
  static const String _apiKey = ApiConfig.youtubeApiKey;
  static const String _channelId = ApiConfig.channelId;
  static const String _appInitializedKey = 'app_data_initialized';
  
  void _debugLog(String message) {
    if (ApiConfig.enableDebugLogging) {
      print('🚀 OptimizedYouTubeService: $message');
    }
  }
  
  // =================== INITIALIZATION CHECK ===================
  
  /// Check if app has been initialized with data (either from cache or API)
  Future<bool> isAppDataInitialized() async {
    try {
      // First check if we have valid Firebase cache
      final hasCache = await YouTubeFirebaseCache.hasAnyCache();
      if (hasCache) {
        _debugLog('App data available from Firebase cache');
        return true;
      }
      
      // Check SharedPreferences flag
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_appInitializedKey) ?? false;
      
      _debugLog('App initialization status: $isInitialized');
      return isInitialized;
    } catch (e) {
      _debugLog('Error checking initialization status: $e');
      return false;
    }
  }
  
  /// Mark app as initialized
  Future<void> _markAppAsInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appInitializedKey, true);
      _debugLog('App marked as initialized');
    } catch (e) {
      _debugLog('Error marking app as initialized: $e');
    }
  }
  
  // =================== INITIAL DATA SYNC ===================
  
  /// Perform initial data sync from YouTube API to Firebase
  Future<Map<String, dynamic>> performInitialSync() async {
    try {
      _debugLog('🔄 Starting initial sync from YouTube API');
      final stopwatch = Stopwatch()..start();
      
      // Fetch playlists from API
      final playlists = await _fetchPlaylistsFromAPI();
      await YouTubeFirebaseCache.cachePlaylists(playlists);
      
      // Fetch videos for each playlist from API
      final Map<String, List<YouTubeVideo>> playlistVideos = {};
      final List<YouTubeVideo> allVideos = [];
      
      for (final playlist in playlists) {
        final videos = await _fetchPlaylistVideosFromAPI(playlist.id);
        playlistVideos[playlist.id] = videos;
        allVideos.addAll(videos);
        
        // Cache videos for this playlist
        await YouTubeFirebaseCache.cachePlaylistVideos(playlist.id, videos);
      }
      
      // Cache metadata for all videos
      await YouTubeFirebaseCache.updateCacheMetadata('all_videos', additionalData: {
        'count': allVideos.length,
      });
      
      // Fetch live streams from API
      final liveStreams = await _fetchLiveStreamsFromAPI();
      await YouTubeFirebaseCache.cacheLiveStreams(liveStreams);
      
      await _markAppAsInitialized();
      
      stopwatch.stop();
      _debugLog('✅ Initial sync completed in ${stopwatch.elapsedMilliseconds}ms');
      _debugLog('📊 Synced: ${playlists.length} playlists, ${allVideos.length} videos, ${liveStreams.length} live streams');
      
      return {
        'playlists': playlists,
        'playlistVideos': playlistVideos,
        'liveStreams': liveStreams,
        'totalVideos': allVideos.length,
      };
    } catch (e) {
      _debugLog('❌ Error during initial sync: $e');
      rethrow;
    }
  }
  
  // =================== DATA RETRIEVAL (CACHE FIRST) ===================
  
  /// Load home page data (cache first, API fallback)
  Future<Map<String, dynamic>> loadHomePageData() async {
    try {
      _debugLog('📱 Loading home page data');
      
      // Try to get data from Firebase cache first
      final cachedPlaylists = await YouTubeFirebaseCache.getCachedPlaylists();
      final cachedLiveStreams = await YouTubeFirebaseCache.getCachedLiveStreams();
      
      if (cachedPlaylists != null && cachedLiveStreams != null) {
        _debugLog('✅ Using cached data for home page');
        
        // Load videos for first few playlists
        const initialPlaylistCount = 3;
        final initialPlaylists = cachedPlaylists.take(initialPlaylistCount).toList();
        final Map<String, List<YouTubeVideo>> playlistVideos = {};
        
        for (final playlist in initialPlaylists) {
          final videos = await YouTubeFirebaseCache.getCachedPlaylistVideos(playlist.id);
          if (videos != null) {
            playlistVideos[playlist.id] = videos.take(3).toList(); // Limit to 3 videos per playlist
          }
        }
        
        return {
          'playlists': cachedPlaylists,
          'initialPlaylists': initialPlaylists,
          'playlistVideos': playlistVideos,
          'liveStreams': cachedLiveStreams,
          'hasMore': cachedPlaylists.length > initialPlaylistCount,
          'fromCache': true,
        };
      }
      
      // If no cache, perform initial sync
      _debugLog('⚠️ No valid cache found, performing initial sync');
      final syncResult = await performInitialSync();
      
      const initialPlaylistCount = 3;
      final allPlaylists = syncResult['playlists'] as List<PlaylistInfo>;
      final allPlaylistVideos = syncResult['playlistVideos'] as Map<String, List<YouTubeVideo>>;
      final initialPlaylists = allPlaylists.take(initialPlaylistCount).toList();
      
      // Limit videos for initial display
      final Map<String, List<YouTubeVideo>> limitedPlaylistVideos = {};
      for (final playlist in initialPlaylists) {
        final videos = allPlaylistVideos[playlist.id] ?? [];
        limitedPlaylistVideos[playlist.id] = videos.take(3).toList();
      }
      
      return {
        'playlists': allPlaylists,
        'initialPlaylists': initialPlaylists,
        'playlistVideos': limitedPlaylistVideos,
        'liveStreams': syncResult['liveStreams'],
        'hasMore': allPlaylists.length > initialPlaylistCount,
        'fromCache': false,
      };
    } catch (e) {
      _debugLog('❌ Error loading home page data: $e');
      rethrow;
    }
  }
  
  /// Batch load playlist videos (cache first)
  Future<Map<String, List<YouTubeVideo>>> batchLoadPlaylistVideos(
    List<String> playlistIds, {
    int maxResults = 3,
  }) async {
    try {
      _debugLog('📦 Batch loading videos for ${playlistIds.length} playlists');
      
      final Map<String, List<YouTubeVideo>> result = {};
      
      for (final playlistId in playlistIds) {
        final cachedVideos = await YouTubeFirebaseCache.getCachedPlaylistVideos(playlistId);
        if (cachedVideos != null) {
          result[playlistId] = cachedVideos.take(maxResults).toList();
        }
      }
      
      _debugLog('✅ Loaded videos for ${result.length}/${playlistIds.length} playlists from cache');
      return result;
    } catch (e) {
      _debugLog('❌ Error batch loading playlist videos: $e');
      return {};
    }
  }
  
  /// Search videos (Firebase only - no API calls)
  Future<List<YouTubeVideo>> searchVideos(String query, {int limit = 20}) async {
    try {
      _debugLog('🔍 Searching videos in Firebase for: "$query"');
      return await YouTubeFirebaseCache.searchCachedVideos(query, limit: limit);
    } catch (e) {
      _debugLog('❌ Error searching videos: $e');
      return [];
    }
  }

  /// Search channel videos (alias for searchVideos for compatibility)
  Future<List<YouTubeVideo>> searchChannelVideos(String query, {int limit = 20}) async {
    return await searchVideos(query, limit: limit);
  }

  /// Load explore page data (cache first)
  Future<Map<String, dynamic>> loadExplorePageData() async {
    try {
      _debugLog('🔍 Loading explore page data');
      
      // Get all cached videos
      final allVideos = await YouTubeFirebaseCache.getAllCachedVideos();
      if (allVideos == null || allVideos.isEmpty) {
        _debugLog('⚠️ No cached videos found for explore page');
        
        // If no cache, perform initial sync
        final syncResult = await performInitialSync();
        final videos = <YouTubeVideo>[];
        final playlistVideos = syncResult['playlistVideos'] as Map<String, List<YouTubeVideo>>;
        
        for (final videoList in playlistVideos.values) {
          videos.addAll(videoList);
        }
        
        return {
          'allVideos': videos,
          'playlists': syncResult['playlists'],
          'categories': _extractCategories(videos),
        };
      }
      
      // Get playlists
      final playlists = await YouTubeFirebaseCache.getCachedPlaylists() ?? [];
      
      return {
        'allVideos': allVideos,
        'playlists': playlists,
        'categories': _extractCategories(allVideos),
      };
    } catch (e) {
      _debugLog('❌ Error loading explore page data: $e');
      rethrow;
    }
  }

  /// Extract categories from videos
  List<String> _extractCategories(List<YouTubeVideo> videos) {
    final categories = <String>{'All'};
    
    for (final video in videos) {
      final category = VideoCategory.categorizeVideo(video.title, video.description);
      categories.add(category);
    }
    
    return categories.toList();
  }
  
  /// Get live streams (cache first)
  Future<List<LiveStream>> getLiveStreams() async {
    try {
      final cachedStreams = await YouTubeFirebaseCache.getCachedLiveStreams();
      if (cachedStreams != null) {
        _debugLog('✅ Retrieved ${cachedStreams.length} live streams from cache');
        return cachedStreams;
      }
      
      // If no valid cache, fetch from API
      _debugLog('⚠️ No valid live streams cache, fetching from API');
      final streams = await _fetchLiveStreamsFromAPI();
      await YouTubeFirebaseCache.cacheLiveStreams(streams);
      return streams;
    } catch (e) {
      _debugLog('❌ Error getting live streams: $e');
      return [];
    }
  }
  
  // =================== MANUAL REFRESH ===================
  
  /// Force refresh data from API (user-initiated)
  Future<void> forceRefresh() async {
    try {
      _debugLog('🔄 Force refresh initiated by user');
      
      // Clear Firebase cache
      await YouTubeFirebaseCache.clearAllCache();
      
      // Clear initialization flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appInitializedKey);
      
      // Perform fresh sync
      await performInitialSync();
      
      _debugLog('✅ Force refresh completed');
    } catch (e) {
      _debugLog('❌ Error during force refresh: $e');
      rethrow;
    }
  }
  
  // =================== DIRECT API CALLS (Private) ===================
  
  Future<List<PlaylistInfo>> _fetchPlaylistsFromAPI() async {
    try {
      _debugLog('🌐 Fetching playlists from YouTube API');
      
      final url = '${_baseUrl}/playlists?part=snippet,contentDetails&channelId=${_channelId}&maxResults=50&key=${_apiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = (data['items'] as List)
            .map((item) => PlaylistInfo.fromJson(item))
            .toList();
        
        _debugLog('✅ Fetched ${playlists.length} playlists from API');
        return playlists;
      } else {
        throw Exception('Failed to fetch playlists: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog('❌ Error fetching playlists from API: $e');
      rethrow;
    }
  }
  
  Future<List<YouTubeVideo>> _fetchPlaylistVideosFromAPI(String playlistId) async {
    try {
      _debugLog('🌐 Fetching videos for playlist $playlistId from YouTube API');
      
      final url = '${_baseUrl}/playlistItems?part=snippet&playlistId=${playlistId}&maxResults=50&key=${_apiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        final List<YouTubeVideo> videos = [];
        for (final item in items) {
          try {
            final videoId = item['snippet']['resourceId']['videoId'];
            final video = await _fetchVideoDetailsFromAPI(videoId);
            if (video != null) {
              videos.add(video);
            }
          } catch (e) {
            _debugLog('⚠️ Skipping video due to error: $e');
          }
        }
        
        _debugLog('✅ Fetched ${videos.length} videos for playlist $playlistId');
        return videos;
      } else {
        throw Exception('Failed to fetch playlist videos: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog('❌ Error fetching playlist videos from API: $e');
      return [];
    }
  }
  
  Future<YouTubeVideo?> _fetchVideoDetailsFromAPI(String videoId) async {
    try {
      final url = '${_baseUrl}/videos?part=snippet,statistics,contentDetails&id=${videoId}&key=${_apiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        if (items.isNotEmpty) {
          return YouTubeVideo.fromJson(items[0]);
        }
      }
      return null;
    } catch (e) {
      _debugLog('⚠️ Error fetching video details for $videoId: $e');
      return null;
    }
  }
  
  Future<List<LiveStream>> _fetchLiveStreamsFromAPI() async {
    try {
      _debugLog('🌐 Fetching live streams from YouTube API');
      
      final url = '${_baseUrl}/search?part=snippet&channelId=${_channelId}&eventType=live&type=video&maxResults=10&key=${_apiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        final List<LiveStream> liveStreams = [];
        for (final item in items) {
          try {
            final liveStream = LiveStream.fromSearchJson(item);
            liveStreams.add(liveStream);
          } catch (e) {
            _debugLog('⚠️ Error parsing live stream: $e');
          }
        }
        
        _debugLog('✅ Fetched ${liveStreams.length} live streams from API');
        return liveStreams;
      } else {
        throw Exception('Failed to fetch live streams: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog('❌ Error fetching live streams from API: $e');
      return [];
    }
  }
}
