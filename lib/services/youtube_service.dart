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
}