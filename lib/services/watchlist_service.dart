import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_models.dart';

class WatchlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's ID
  static String? get _userId => _auth.currentUser?.uid;

  // Collection reference for watchlist
  static CollectionReference get _watchlistCollection =>
      _firestore.collection('watchlists');

  // Add video to watchlist
  static Future<bool> addToWatchlist(Video video) async {
    try {
      if (_userId == null) {
        print('❌ User not authenticated');
        return false;
      }

      final docRef = _watchlistCollection.doc(_userId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing watchlist
        await docRef.update({
          'videos.${video.id}': {
            ...video.toJson(),
            'addedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new watchlist
        await docRef.set({
          'userId': _userId,
          'videos': {
            video.id: {
              ...video.toJson(),
              'addedAt': FieldValue.serverTimestamp(),
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Video added to watchlist: ${video.title}');
      return true;
    } catch (e) {
      print('❌ Error adding to watchlist: $e');
      return false;
    }
  }

  // Remove video from watchlist
  static Future<bool> removeFromWatchlist(String userId, Video video) async {
    try {
      if (_userId == null) {
        print('❌ User not authenticated');
        return false;
      }

      final docRef = _watchlistCollection.doc(_userId);
      await docRef.update({
        'videos.${video.id}': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Video removed from watchlist: ${video.id}');
      return true;
    } catch (e) {
      print('❌ Error removing from watchlist: $e');
      return false;
    }
  }

  // Check if video is in watchlist
  static Future<bool> isInWatchlist(String userId, Video video) async {
    try {
      if (_userId == null) return false;

      final doc = await _watchlistCollection.doc(_userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final videos = data?['videos'] as Map<String, dynamic>?;
      
      return videos?.containsKey(video.id) ?? false;
    } catch (e) {
      print('❌ Error checking watchlist: $e');
      return false;
    }
  }

  // Get all watchlist videos
  static Future<List<Video>> getWatchlistVideos() async {
    try {
      if (_userId == null) {
        print('❌ User not authenticated');
        return [];
      }

      final doc = await _watchlistCollection.doc(_userId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>?;
      final videosMap = data?['videos'] as Map<String, dynamic>?;

      if (videosMap == null) return [];

      final List<Video> videos = [];
      
      for (final entry in videosMap.entries) {
        try {
          final videoData = entry.value as Map<String, dynamic>;
          // Remove the addedAt field before converting to Video
          videoData.remove('addedAt');
          
          final video = Video.fromJson(videoData);
          videos.add(video);
        } catch (e) {
          print('❌ Error parsing video ${entry.key}: $e');
        }
      }

      // Sort by addedAt timestamp (most recent first)
      videos.sort((a, b) {
        final aData = videosMap[a.id] as Map<String, dynamic>?;
        final bData = videosMap[b.id] as Map<String, dynamic>?;
        
        final aTimestamp = aData?['addedAt'] as Timestamp?;
        final bTimestamp = bData?['addedAt'] as Timestamp?;
        
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      print('✅ Retrieved ${videos.length} watchlist videos');
      return videos;
    } catch (e) {
      print('❌ Error getting watchlist videos: $e');
      return [];
    }
  }

  // Get watchlist stream for real-time updates
  static Stream<List<Video>> watchlistStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _watchlistCollection.doc(_userId).snapshots().map((doc) {
      if (!doc.exists) return <Video>[];

      final data = doc.data() as Map<String, dynamic>?;
      final videosMap = data?['videos'] as Map<String, dynamic>?;

      if (videosMap == null) return <Video>[];

      final List<Video> videos = [];
      
      for (final entry in videosMap.entries) {
        try {
          final videoData = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
          // Remove the addedAt field before converting to Video
          videoData.remove('addedAt');
          
          final video = Video.fromJson(videoData);
          videos.add(video);
        } catch (e) {
          print('❌ Error parsing video ${entry.key}: $e');
        }
      }

      // Sort by addedAt timestamp (most recent first)
      videos.sort((a, b) {
        final aData = videosMap[a.id] as Map<String, dynamic>?;
        final bData = videosMap[b.id] as Map<String, dynamic>?;
        
        final aTimestamp = aData?['addedAt'] as Timestamp?;
        final bTimestamp = bData?['addedAt'] as Timestamp?;
        
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return videos;
    });
  }

  // Clear entire watchlist
  static Future<bool> clearWatchlist() async {
    try {
      if (_userId == null) {
        print('❌ User not authenticated');
        return false;
      }

      await _watchlistCollection.doc(_userId).delete();
      print('✅ Watchlist cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing watchlist: $e');
      return false;
    }
  }

  // Get watchlist count
  static Future<int> getWatchlistCount() async {
    try {
      if (_userId == null) return 0;

      final doc = await _watchlistCollection.doc(_userId).get();
      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>?;
      final videos = data?['videos'] as Map<String, dynamic>?;
      
      return videos?.length ?? 0;
    } catch (e) {
      print('❌ Error getting watchlist count: $e');
      return 0;
    }
  }
}
