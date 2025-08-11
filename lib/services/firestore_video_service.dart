import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_video_models.dart';

class FirestoreVideoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _videosCollection = 'videos';
  
  // Fetch all videos from Firestore
  static Future<List<FirestoreVideo>> fetchAllVideos() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_videosCollection)
          .orderBy('id')
          .get();
      
      return snapshot.docs
          .map((doc) => FirestoreVideo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching videos: $e');
      return [];
    }
  }

  // Fetch videos by category
  static Future<List<FirestoreVideo>> fetchVideosByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_videosCollection)
          .where('Category', isEqualTo: category)
          .orderBy('id')
          .get();
      
      return snapshot.docs
          .map((doc) => FirestoreVideo.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((video) => video.isAvailable) // Only return available videos
          .toList();
    } catch (e) {
      print('Error fetching videos for category $category: $e');
      return [];
    }
  }

  // Get all categories with their video counts
  static Future<Map<String, VideoCategory>> fetchCategoriesWithVideos() async {
    try {
      final List<FirestoreVideo> allVideos = await fetchAllVideos();
      final Map<String, List<FirestoreVideo>> categorizedVideos = {};
      
      // Group videos by category
      for (final video in allVideos) {
        if (!categorizedVideos.containsKey(video.category)) {
          categorizedVideos[video.category] = [];
        }
        categorizedVideos[video.category]!.add(video);
      }
      
      // Create VideoCategory objects
      final Map<String, VideoCategory> categories = {};
      for (final categoryName in VideoCategory.getAllCategories()) {
        final videos = categorizedVideos[categoryName] ?? [];
        categories[categoryName] = VideoCategory(
          name: categoryName,
          description: VideoCategory.getCategoryDescription(categoryName),
          videos: videos,
          iconName: VideoCategory.getCategoryIcon(categoryName),
        );
      }
      
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return {};
    }
  }

  // Search videos by keyword (both English and Hindi titles)
  static Future<List<FirestoreVideo>> searchVideos(String query) async {
    try {
      final List<FirestoreVideo> allVideos = await fetchAllVideos();
      final String lowerQuery = query.toLowerCase();
      
      return allVideos.where((video) {
        return video.isAvailable && (
          video.titleEnglish.toLowerCase().contains(lowerQuery) ||
          video.titleHindi.contains(query) ||
          video.keywords.toLowerCase().contains(lowerQuery) ||
          video.category.toLowerCase().contains(lowerQuery)
        );
      }).toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  // Get video by ID
  static Future<FirestoreVideo?> getVideoById(int videoId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_videosCollection)
          .where('id', isEqualTo: videoId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return FirestoreVideo.fromFirestore(
          snapshot.docs.first.data() as Map<String, dynamic>
        );
      }
      return null;
    } catch (e) {
      print('Error fetching video by ID $videoId: $e');
      return null;
    }
  }

  // Get recently added videos (last 10)
  static Future<List<FirestoreVideo>> getRecentVideos({int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_videosCollection)
          .orderBy('Published_At', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => FirestoreVideo.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((video) => video.isAvailable)
          .toList();
    } catch (e) {
      print('Error fetching recent videos: $e');
      return [];
    }
  }

  // Get popular videos (placeholder - you might want to add view count tracking)
  static Future<List<FirestoreVideo>> getPopularVideos({int limit = 10}) async {
    try {
      // For now, return videos by ID order (you can implement view counting later)
      final QuerySnapshot snapshot = await _firestore
          .collection(_videosCollection)
          .orderBy('id')
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => FirestoreVideo.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((video) => video.isAvailable)
          .toList();
    } catch (e) {
      print('Error fetching popular videos: $e');
      return [];
    }
  }

  // Stream for real-time updates (useful for future features)
  static Stream<List<FirestoreVideo>> watchVideosByCategory(String category) {
    return _firestore
        .collection(_videosCollection)
        .where('Category', isEqualTo: category)
        .orderBy('id')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirestoreVideo.fromFirestore(doc.data()))
            .where((video) => video.isAvailable)
            .toList());
  }

  // Get stats for dashboard/admin purposes
  static Future<Map<String, int>> getVideoStats() async {
    try {
      final List<FirestoreVideo> allVideos = await fetchAllVideos();
      final Map<String, int> stats = {
        'total': allVideos.length,
        'available': allVideos.where((v) => v.isAvailable).length,
        'unavailable': allVideos.where((v) => !v.isAvailable).length,
      };
      
      // Count by category
      for (final category in VideoCategory.getAllCategories()) {
        final categoryVideos = allVideos.where((v) => v.category == category);
        stats['${category}_total'] = categoryVideos.length;
        stats['${category}_available'] = categoryVideos.where((v) => v.isAvailable).length;
      }
      
      return stats;
    } catch (e) {
      print('Error fetching video stats: $e');
      return {};
    }
  }

  // Validate pCloud link format
  static bool isValidPCloudLink(String link) {
    return link.isNotEmpty && 
           (link.contains('pcloud.link') || link.contains('my.pcloud.com'));
  }

  // Get direct streaming URL from pCloud link (if needed for video player)
  static String getStreamingUrl(String pcloudLink) {
    // PCloud links are usually direct streaming links
    // You might need to modify this based on your PCloud setup
    if (isValidPCloudLink(pcloudLink)) {
      return pcloudLink;
    }
    return '';
  }
}
