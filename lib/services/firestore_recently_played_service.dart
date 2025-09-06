import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recently_played_model.dart';
import '../models/video_models.dart';

class FirestoreRecentlyPlayedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> addRecentlyPlayedVideo(Video video) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final recentlyPlayedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyPlayed')
        .doc(video.id);

    // Convert duration string to Duration object
    Duration durationObj = Duration.zero;
    try {
      final parts = video.duration.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        durationObj = Duration(minutes: minutes, seconds: seconds);
      }
    } catch (e) {
      // If parsing fails, use zero duration
      durationObj = Duration.zero;
    }

    final recentlyPlayed = RecentlyPlayed(
      videoId: video.id,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      playedAt: DateTime.now(),
      pcloudUrl: video.pcloudUrl,
      youtubeUrl: video.youtubeUrl ?? '',
      description: video.description,
      duration: durationObj,
      channelTitle: video.channelTitle,
      category: '', // Video model doesn't have category
    );

    await recentlyPlayedRef.set(recentlyPlayed.toFirestore(), SetOptions(merge: true));
  }

  static Future<List<Video>> getRecentlyPlayedVideos() async {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recentlyPlayed')
          .orderBy('playedAt', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => RecentlyPlayed.fromFirestore(doc).toVideo())
          .toList();
    } catch (e) {
      print('Error fetching recently played videos: $e');
      return [];
    }
  }
}
