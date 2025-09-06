import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_models.dart';

class RecentlyPlayed {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime playedAt;
  final String pcloudUrl;
  final String youtubeUrl;
  final String description;
  final Duration duration;
  final String channelTitle;
  final String category;

  RecentlyPlayed({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.playedAt,
    required this.pcloudUrl,
    required this.youtubeUrl,
    required this.description,
    required this.duration,
    required this.channelTitle,
    required this.category,
  });

  factory RecentlyPlayed.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RecentlyPlayed(
      videoId: doc.id,
      title: data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      playedAt: (data['playedAt'] as Timestamp).toDate(),
      pcloudUrl: data['pcloudUrl'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      description: data['description'] ?? '',
      duration: Duration(seconds: data['duration'] ?? 0),
      channelTitle: data['channelTitle'] ?? '',
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'playedAt': FieldValue.serverTimestamp(),
      'pcloudUrl': pcloudUrl,
      'youtubeUrl': youtubeUrl,
      'description': description,
      'duration': duration.inSeconds,
      'channelTitle': channelTitle,
      'category': category,
    };
  }

  // Convert RecentlyPlayed to Video for UI compatibility
  Video toVideo() {
    // Format duration as MM:SS
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Video(
      id: videoId,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      duration: durationString,
      viewCount: 0,
      likeCount: 0,
      publishedAt: playedAt,
      channelTitle: channelTitle,
      pcloudUrl: pcloudUrl,
      youtubeUrl: youtubeUrl,
    );
  }
}
