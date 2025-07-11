import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/youtube_models.dart';

class YouTubeService {
  static const String _baseUrl = ApiConfig.youtubeBaseUrl;
  static const String _apiKey = ApiConfig.youtubeApiKey;
  static const String _channelId = ApiConfig.channelId;
  static const String _cachePrefix = 'youtube_cache_';
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _liveStreamCacheExpiry = Duration(minutes: 2); // Shorter cache for live streams

  // In-memory cache
  Map<String, List<PlaylistInfo>> _playlistCache = {};
  Map<String, List<YouTubeVideo>> _videoCache = {};
  Map<String, List<LiveStream>> _liveStreamCache = {};
  Map<String, DateTime> _cacheTimestamps = {};

  void _debugLog(String message) {
    if (ApiConfig.enableDebugLogging) {
      print('🔍 YouTubeService: $message');
    }
  }

  // Cache validation with different expiry for live streams
  bool _isValidCache(String key, {bool isLiveStream = false}) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final cacheTime = _cacheTimestamps[key]!;
    final now = DateTime.now();
    final expiry = isLiveStream ? _liveStreamCacheExpiry : _cacheExpiry;

    return now.difference(cacheTime) < expiry;
  }

  // LIVE STREAM METHODS

  // Get all live streams and scheduled live events
  Future<List<LiveStream>> getLiveStreams() async {
    const cacheKey = 'live_streams';

    // Check in-memory cache first (with shorter expiry)
    if (_isValidCache(cacheKey, isLiveStream: true) && _liveStreamCache.containsKey(cacheKey)) {
      _debugLog('📦 Returning live streams from memory cache');
      return _liveStreamCache[cacheKey]!;
    }

    try {
      _debugLog('🔴 Fetching live streams from API');

      final List<LiveStream> allStreams = [];

      // Fetch different types of live broadcasts
      final liveStreams = await _fetchLiveStreamsByType('live');
      final upcomingStreams = await _fetchLiveStreamsByType('upcoming');

      allStreams.addAll(liveStreams);
      allStreams.addAll(upcomingStreams);

      // Sort by priority: live first, then upcoming by schedule time
      allStreams.sort((a, b) {
        if (a.status == LiveStreamStatus.live && b.status != LiveStreamStatus.live) {
          return -1;
        } else if (b.status == LiveStreamStatus.live && a.status != LiveStreamStatus.live) {
          return 1;
        } else if (a.status == LiveStreamStatus.upcoming && b.status == LiveStreamStatus.upcoming) {
          final aTime = a.scheduledStartTime ?? DateTime.now();
          final bTime = b.scheduledStartTime ?? DateTime.now();
          return aTime.compareTo(bTime);
        }

        return 0;
      });

      // Cache the result
      _liveStreamCache[cacheKey] = allStreams;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _debugLog('✅ Found ${allStreams.length} live streams (${liveStreams.length} live, ${upcomingStreams.length} upcoming)');
      return allStreams;

    } catch (e) {
      _debugLog('❌ Error fetching live streams: $e');
      // Return cached data if available, even if expired
      if (_liveStreamCache.containsKey(cacheKey)) {
        _debugLog('📦 Returning expired cache due to error');
        return _liveStreamCache[cacheKey]!;
      }
      throw Exception('Error fetching live streams: $e');
    }
  }

  // Fetch live streams by broadcast status
  Future<List<LiveStream>> _fetchLiveStreamsByType(String eventType) async {
    try {
      final searchUrl = Uri.parse(
          '$_baseUrl/search?part=snippet&channelId=$_channelId&type=video&eventType=$eventType&maxResults=25&order=date&key=$_apiKey'
      );

      _debugLog('🔍 Searching for $eventType streams');

      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final List<dynamic> items = searchData['items'] ?? [];

        if (items.isEmpty) {
          _debugLog('📭 No $eventType streams found');
          return [];
        }

        // Get video IDs
        final videoIds = items.map((item) => item['id']['videoId'] as String).toList();

        // Get detailed live broadcast information
        return await _getLiveBroadcastDetails(videoIds);
      } else {
        _debugLog('❌ Search API Error: ${searchResponse.statusCode} - ${searchResponse.body}');
        return [];
      }
    } catch (e) {
      _debugLog('❌ Error in _fetchLiveStreamsByType: $e');
      return [];
    }
  }

  // Get detailed information about live broadcasts
  Future<List<LiveStream>> _getLiveBroadcastDetails(List<String> videoIds) async {
    try {
      if (videoIds.isEmpty) return [];

      final videoIdsString = videoIds.join(',');
      final url = Uri.parse(
          '$_baseUrl/videos?part=snippet,liveStreamingDetails,statistics&id=$videoIdsString&key=$_apiKey'
      );

      _debugLog('📊 Getting live broadcast details for ${videoIds.length} videos');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final streams = items.map((item) => LiveStream.fromJson(item)).toList();
        _debugLog('✅ Processed ${streams.length} live streams');

        return streams;
      } else {
        _debugLog('❌ Videos API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      _debugLog('❌ Error in _getLiveBroadcastDetails: $e');
      return [];
    }
  }

  // Get current live stream (if any)
  Future<LiveStream?> getCurrentLiveStream() async {
    try {
      final liveStreams = await getLiveStreams();

      final currentLive = liveStreams.where((stream) =>
      stream.status == LiveStreamStatus.live
      ).toList();

      return currentLive.isNotEmpty ? currentLive.first : null;
    } catch (e) {
      _debugLog('❌ Error getting current live stream: $e');
      return null;
    }
  }

  // Get next scheduled live stream
  Future<LiveStream?> getNextScheduledStream() async {
    try {
      final liveStreams = await getLiveStreams();

      final upcomingStreams = liveStreams.where((stream) =>
      stream.status == LiveStreamStatus.upcoming
      ).toList();

      return upcomingStreams.isNotEmpty ? upcomingStreams.first : null;
    } catch (e) {
      _debugLog('❌ Error getting next scheduled stream: $e');
      return null;
    }
  }

  // Clear live stream cache (useful for real-time updates)
  Future<void> clearLiveStreamCache() async {
    _liveStreamCache.clear();
    _cacheTimestamps.remove('live_streams');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_cachePrefix}live_streams');

    _debugLog('🧹 Live stream cache cleared');
  }

  // EXISTING METHODS (optimized)

  // Persistent cache operations
  Future<void> _saveToPersistentCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode({
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_cachePrefix + key, jsonData);
    } catch (e) {
      _debugLog('Error saving to cache: $e');
    }
  }

  Future<dynamic> _loadFromPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachePrefix + key);

      if (jsonString == null) return null;

      final jsonData = json.decode(jsonString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(jsonData['timestamp']);

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await prefs.remove(_cachePrefix + key);
        return null;
      }

      return jsonData['data'];
    } catch (e) {
      _debugLog('Error loading from cache: $e');
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    _playlistCache.clear();
    _videoCache.clear();
    _liveStreamCache.clear();
    _cacheTimestamps.clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // Test API connection and get correct channel ID
  Future<Map<String, dynamic>?> testApiAndGetChannelId() async {
    try {
      _debugLog('Testing API connection...');

      final handleUrl = Uri.parse(
          '$_baseUrl/search?part=snippet&q=${ApiConfig.channelHandle}&type=channel&key=$_apiKey'
      );

      final handleResponse = await http.get(handleUrl);

      if (handleResponse.statusCode == 200) {
        final handleData = json.decode(handleResponse.body);
        final items = handleData['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final channelId = items.first['snippet']['channelId'];
          return await _testChannelId(channelId);
        }
      }

      return await _testChannelId(_channelId);

    } catch (e) {
      _debugLog('Error in testApiAndGetChannelId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _testChannelId(String channelId) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/channels?part=snippet,statistics&id=$channelId&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final channel = items.first;
          final result = {
            'success': true,
            'id': channel['id'],
            'title': channel['snippet']['title'],
            'description': channel['snippet']['description'],
            'subscriberCount': channel['statistics']['subscriberCount'] ?? '0',
            'videoCount': channel['statistics']['videoCount'] ?? '0',
            'thumbnail': channel['snippet']['thumbnails']['high']['url'],
          };
          return result;
        }
      }

      return {'success': false, 'error': 'Channel not found'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // OPTIMIZED: Get channel playlists with caching
  Future<List<PlaylistInfo>> getChannelPlaylists() async {
    const cacheKey = 'playlists';

    if (_isValidCache(cacheKey) && _playlistCache.containsKey(cacheKey)) {
      return _playlistCache[cacheKey]!;
    }

    final cachedData = await _loadFromPersistentCache(cacheKey);
    if (cachedData != null) {
      final playlists = (cachedData as List).map((item) =>
          PlaylistInfo.fromJson(Map<String, dynamic>.from(item))).toList();
      _playlistCache[cacheKey] = playlists;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return playlists;
    }

    try {
      final url = Uri.parse(
          '$_baseUrl/playlists?part=snippet,contentDetails&channelId=$_channelId&maxResults=50&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final playlists = items.map((item) => PlaylistInfo.fromJson(item)).toList();

        _playlistCache[cacheKey] = playlists;
        _cacheTimestamps[cacheKey] = DateTime.now();
        await _saveToPersistentCache(cacheKey, playlists.map((p) => p.toJson()).toList());

        return playlists;
      } else {
        throw Exception('Failed to load playlists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlists: $e');
    }
  }

  // OPTIMIZED: Get playlist videos with caching
  Future<List<YouTubeVideo>> getPlaylistVideos(String playlistId, {int maxResults = 10}) async {
    final cacheKey = 'videos_$playlistId';

    if (_isValidCache(cacheKey) && _videoCache.containsKey(cacheKey)) {
      return _videoCache[cacheKey]!.take(maxResults).toList();
    }

    final cachedData = await _loadFromPersistentCache(cacheKey);
    if (cachedData != null) {
      final videos = (cachedData as List).map((item) =>
          YouTubeVideo.fromJson(Map<String, dynamic>.from(item))).toList();
      _videoCache[cacheKey] = videos;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return videos.take(maxResults).toList();
    }

    try {
      final url = Uri.parse(
          '$_baseUrl/playlistItems?part=snippet&playlistId=$playlistId&maxResults=$maxResults&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final videoIds = items.map((item) => item['snippet']['resourceId']['videoId'] as String).toList();
        final videos = await getVideoDetails(videoIds);

        _videoCache[cacheKey] = videos;
        _cacheTimestamps[cacheKey] = DateTime.now();
        await _saveToPersistentCache(cacheKey, videos.map((v) => v.toJson()).toList());

        return videos;
      } else {
        throw Exception('Failed to load playlist videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlist videos: $e');
    }
  }

  // Batch load playlist videos concurrently
  Future<Map<String, List<YouTubeVideo>>> batchLoadPlaylistVideos(
      List<String> playlistIds, {
        int maxResults = 5,
      }) async {
    final futures = playlistIds.map((playlistId) =>
        getPlaylistVideos(playlistId, maxResults: maxResults)
            .catchError((error) {
          _debugLog('❌ Error loading playlist $playlistId: $error');
          return <YouTubeVideo>[];
        })
    ).toList();

    final results = await Future.wait(futures);

    final Map<String, List<YouTubeVideo>> playlistVideos = {};
    for (int i = 0; i < playlistIds.length; i++) {
      playlistVideos[playlistIds[i]] = results[i];
    }

    return playlistVideos;
  }

  // Load home page data efficiently (including live streams)
  Future<Map<String, dynamic>> loadHomePageData() async {
    try {
      // Load playlists and live streams concurrently
      final futures = await Future.wait([
        getChannelPlaylists(),
        getLiveStreams(),
      ]);

      final playlists = futures[0] as List<PlaylistInfo>;
      final liveStreams = futures[1] as List<LiveStream>;

      // Load videos for first 3 playlists
      final initialPlaylists = playlists.take(3).toList();
      final playlistIds = initialPlaylists.map((p) => p.id).toList();

      final playlistVideos = await batchLoadPlaylistVideos(playlistIds, maxResults: 3);

      return {
        'playlists': playlists,
        'initialPlaylists': initialPlaylists,
        'playlistVideos': playlistVideos,
        'liveStreams': liveStreams,
        'hasMore': playlists.length > 3,
      };
    } catch (e) {
      throw Exception('Failed to load home page data: $e');
    }
  }

  // Load explore page data efficiently
  Future<Map<String, dynamic>> loadExplorePageData() async {
    try {
      final playlists = await getChannelPlaylists();

      const batchSize = 5;
      final categories = ['All'];
      final categorizedVideos = <String, List<YouTubeVideo>>{};
      final allVideos = <YouTubeVideo>[];

      for (int i = 0; i < playlists.length; i += batchSize) {
        final batch = playlists.skip(i).take(batchSize).toList();
        final batchIds = batch.map((p) => p.id).toList();

        final batchResults = await batchLoadPlaylistVideos(batchIds, maxResults: 10);

        for (final playlist in batch) {
          final videos = batchResults[playlist.id] ?? [];

          if (videos.isNotEmpty) {
            categories.add(playlist.title);
            categorizedVideos[playlist.title] = videos;
            allVideos.addAll(videos);
          }
        }

        if (i + batchSize < playlists.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Remove duplicates
      final uniqueVideos = <String, YouTubeVideo>{};
      for (final video in allVideos) {
        uniqueVideos[video.id] = video;
      }

      return {
        'playlists': playlists,
        'categories': categories,
        'categorizedVideos': categorizedVideos,
        'allVideos': uniqueVideos.values.toList(),
      };
    } catch (e) {
      throw Exception('Failed to load explore page data: $e');
    }
  }

  // Get channel uploads with better error handling
  Future<List<YouTubeVideo>> getChannelUploads({int maxResults = 20}) async {
    try {
      final testResult = await testApiAndGetChannelId();
      if (testResult == null || testResult['success'] != true) {
        throw Exception('Channel not accessible: ${testResult?['error'] ?? 'Unknown error'}');
      }

      final workingChannelId = testResult['id'];

      final channelUrl = Uri.parse(
          '$_baseUrl/channels?part=contentDetails&id=$workingChannelId&key=$_apiKey'
      );

      final channelResponse = await http.get(channelUrl);

      if (channelResponse.statusCode == 200) {
        final channelData = json.decode(channelResponse.body);
        final items = channelData['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final uploadsPlaylistId = items.first['contentDetails']['relatedPlaylists']['uploads'] as String;
          return await getPlaylistVideos(uploadsPlaylistId, maxResults: maxResults);
        }
      }

      return await getLatestVideos(maxResults: maxResults);

    } catch (e) {
      throw Exception('Error fetching channel uploads: $e');
    }
  }

  // Get detailed video information including duration
  Future<List<YouTubeVideo>> getVideoDetails(List<String> videoIds) async {
    try {
      if (videoIds.isEmpty) return [];

      final videoIdsString = videoIds.join(',');
      final url = Uri.parse(
          '$_baseUrl/videos?part=snippet,contentDetails,statistics&id=$videoIdsString&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load video details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching video details: $e');
    }
  }

  // Search videos in channel
  Future<List<YouTubeVideo>> searchChannelVideos(String query, {int maxResults = 20}) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/search?part=snippet&channelId=$_channelId&q=$query&type=video&maxResults=$maxResults&order=relevance&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final videoIds = items.map((item) => item['id']['videoId'] as String).toList();
        return await getVideoDetails(videoIds);
      } else {
        throw Exception('Failed to search videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching videos: $e');
    }
  }

  // Get latest uploads from channel
  Future<List<YouTubeVideo>> getLatestVideos({int maxResults = 10}) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/search?part=snippet&channelId=$_channelId&type=video&order=date&maxResults=$maxResults&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final videoIds = items.map((item) => item['id']['videoId'] as String).toList();
        return await getVideoDetails(videoIds);
      } else {
        throw Exception('Failed to load latest videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching latest videos: $e');
    }
  }

  // Get channel info
  Future<Map<String, dynamic>?> getChannelInfo() async {
    try {
      final url = Uri.parse(
          '$_baseUrl/channels?part=snippet,statistics&id=$_channelId&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final channel = items.first;
          return {
            'id': channel['id'],
            'title': channel['snippet']['title'],
            'description': channel['snippet']['description'],
            'subscriberCount': channel['statistics']['subscriberCount'] ?? '0',
            'videoCount': channel['statistics']['videoCount'] ?? '0',
            'thumbnail': channel['snippet']['thumbnails']['high']['url'],
          };
        }
      }
      return null;
    } catch (e) {
      _debugLog('Error getting channel info: $e');
      return null;
    }
  }
}