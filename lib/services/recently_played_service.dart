import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_models.dart';

class RecentlyPlayedService {
  static const String _recentlyPlayedKey = 'recently_played_videos';
  static const int _maxRecentVideos = 10;

  static Future<List<Video>> getRecentlyPlayedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentlyPlayedKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Error loading recently played videos: $e');
      return [];
    }
  }

  static Future<void> addRecentlyPlayedVideo(Video video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Video> recentVideos = await getRecentlyPlayedVideos();

      // Remove if already exists to avoid duplicates
      recentVideos.removeWhere((v) => v.id == video.id);

      // Add to beginning
      recentVideos.insert(0, video);

      // Keep only the latest videos
      if (recentVideos.length > _maxRecentVideos) {
        recentVideos = recentVideos.take(_maxRecentVideos).toList();
      }

      // Save to preferences
      final jsonString = json.encode(recentVideos.map((v) => v.toJson()).toList());
      await prefs.setString(_recentlyPlayedKey, jsonString);
    } catch (e) {
      print('Error saving recently played video: $e');
    }
  }

  static Future<void> clearRecentlyPlayedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyPlayedKey);
    } catch (e) {
      print('Error clearing recently played videos: $e');
    }
  }
}