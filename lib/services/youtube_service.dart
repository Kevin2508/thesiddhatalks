import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/youtube_models.dart';

class YouTubeService {
  static const String _baseUrl = ApiConfig.youtubeBaseUrl;
  static const String _apiKey = ApiConfig.youtubeApiKey;
  static const String _channelId = ApiConfig.channelId;

  void _debugLog(String message) {
    if (ApiConfig.enableDebugLogging) {
      print('🔍 YouTubeService: $message');
    }
  }

  // Test API connection and get correct channel ID
  Future<Map<String, dynamic>?> testApiAndGetChannelId() async {
    try {
      _debugLog('Testing API connection...');

      // Try to get channel by handle first
      final handleUrl = Uri.parse(
          '$_baseUrl/search?part=snippet&q=${ApiConfig.channelHandle}&type=channel&key=$_apiKey'
      );

      _debugLog('Testing with handle: ${handleUrl.toString()}');

      final handleResponse = await http.get(handleUrl);
      _debugLog('Handle search response: ${handleResponse.statusCode}');

      if (handleResponse.statusCode == 200) {
        final handleData = json.decode(handleResponse.body);
        _debugLog('Handle search result: ${handleData.toString()}');

        final items = handleData['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final channelId = items.first['snippet']['channelId'];
          _debugLog('Found channel ID from handle: $channelId');

          // Now test with this channel ID
          return await _testChannelId(channelId);
        }
      }

      // If handle search failed, try with current channel ID
      _debugLog('Handle search failed, testing current channel ID: $_channelId');
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

      _debugLog('Testing channel ID: $channelId');
      _debugLog('URL: ${url.toString()}');

      final response = await http.get(url);
      _debugLog('Channel test response: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');

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
          _debugLog('✅ Channel found successfully: ${channel['snippet']['title']}');
          return result;
        }
      } else {
        _debugLog('❌ API Error: ${response.statusCode} - ${response.body}');
      }

      return {'success': false, 'error': 'Channel not found'};
    } catch (e) {
      _debugLog('❌ Exception in _testChannelId: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get channel uploads with better error handling
  Future<List<YouTubeVideo>> getChannelUploads({int maxResults = 20}) async {
    try {
      _debugLog('Getting channel uploads...');

      // First test the connection
      final testResult = await testApiAndGetChannelId();
      if (testResult == null || testResult['success'] != true) {
        throw Exception('Channel not accessible: ${testResult?['error'] ?? 'Unknown error'}');
      }

      final workingChannelId = testResult['id'];
      _debugLog('Using channel ID: $workingChannelId');

      // Get uploads playlist ID
      final channelUrl = Uri.parse(
          '$_baseUrl/channels?part=contentDetails&id=$workingChannelId&key=$_apiKey'
      );

      final channelResponse = await http.get(channelUrl);
      _debugLog('Channel details response: ${channelResponse.statusCode}');

      if (channelResponse.statusCode == 200) {
        final channelData = json.decode(channelResponse.body);
        final items = channelData['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final uploadsPlaylistId = items.first['contentDetails']['relatedPlaylists']['uploads'] as String;
          _debugLog('Found uploads playlist: $uploadsPlaylistId');

          return await getPlaylistVideos(uploadsPlaylistId, maxResults: maxResults);
        }
      }

      // Fallback to search
      _debugLog('Falling back to search method...');
      return await getLatestVideos(maxResults: maxResults);

    } catch (e) {
      _debugLog('❌ Error in getChannelUploads: $e');
      throw Exception('Error fetching channel uploads: $e');
    }
  }

  // Your existing methods (getChannelPlaylists, getPlaylistVideos, etc.)
  // ... keep all your existing methods as they are ...

  // Get channel playlists
  Future<List<PlaylistInfo>> getChannelPlaylists() async {
    try {
      final url = Uri.parse(
          '$_baseUrl/playlists?part=snippet,contentDetails&channelId=$_channelId&maxResults=50&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) => PlaylistInfo.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load playlists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlists: $e');
    }
  }

  // Get videos from a specific playlist
  Future<List<YouTubeVideo>> getPlaylistVideos(String playlistId, {int maxResults = 10}) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/playlistItems?part=snippet&playlistId=$playlistId&maxResults=$maxResults&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // Get video details (including duration) for each video
        final videoIds = items.map((item) => item['snippet']['resourceId']['videoId'] as String).toList();
        return await getVideoDetails(videoIds);
      } else {
        throw Exception('Failed to load playlist videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlist videos: $e');
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