import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/youtube_models.dart';

class YouTubeService {
  static const String _baseUrl = ApiConfig.youtubeBaseUrl;
  static const String _apiKey = ApiConfig.youtubeApiKey;
  static const String _channelId = ApiConfig.channelId;

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

  // ADD THESE MISSING METHODS:

  // Get channel uploads (all videos from uploads playlist)
  Future<List<YouTubeVideo>> getChannelUploads({int maxResults = 20}) async {
    try {
      // First get the uploads playlist ID
      final channelUrl = Uri.parse(
          '$_baseUrl/channels?part=contentDetails&id=$_channelId&key=$_apiKey'
      );

      final channelResponse = await http.get(channelUrl);

      if (channelResponse.statusCode == 200) {
        final channelData = json.decode(channelResponse.body);
        final items = channelData['items'] as List?;

        if (items != null && items.isNotEmpty) {
          final uploadsPlaylistId = items.first['contentDetails']['relatedPlaylists']['uploads'] as String;

          // Now get videos from uploads playlist
          return await getPlaylistVideos(uploadsPlaylistId, maxResults: maxResults);
        }
      }

      // Fallback to search if uploads playlist not found
      return await getLatestVideos(maxResults: maxResults);
    } catch (e) {
      // Fallback to latest videos if uploads playlist fails
      return await getLatestVideos(maxResults: maxResults);
    }
  }

  // Get channel information
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
            'subscriberCount': channel['statistics']['subscriberCount'],
            'videoCount': channel['statistics']['videoCount'],
            'thumbnail': channel['snippet']['thumbnails']['high']['url'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting channel info: $e');
      return null;
    }
  }

  // Get videos by category (helper method)
  Future<List<YouTubeVideo>> getVideosByCategory(String category, {int maxResults = 10}) async {
    try {
      if (category == 'All') {
        return await getChannelUploads(maxResults: maxResults);
      }

      // Search for videos in the category
      final keywords = VideoCategory.categoryKeywords[category] ?? [];
      if (keywords.isNotEmpty) {
        final query = keywords.join(' OR ');
        return await searchChannelVideos(query, maxResults: maxResults);
      }

      return await getChannelUploads(maxResults: maxResults);
    } catch (e) {
      throw Exception('Error fetching videos by category: $e');
    }
  }
}