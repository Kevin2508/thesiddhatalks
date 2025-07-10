class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;
  final String duration;
  final int viewCount;
  final int likeCount;
  final bool isNew;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    this.isNew = false,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      id: json['id'] as String,
      title: json['snippet']['title'] as String,
      description: json['snippet']['description'] as String,
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'] as String,
      channelTitle: json['snippet']['channelTitle'] as String,
      publishedAt: DateTime.parse(json['snippet']['publishedAt'] as String),
      duration: _formatDuration(json['contentDetails']['duration'] as String),
      viewCount: int.tryParse(json['statistics']['viewCount'] as String? ?? '0') ?? 0,
      likeCount: int.tryParse(json['statistics']['likeCount'] as String? ?? '0') ?? 0,
      isNew: _isNewVideo(DateTime.parse(json['snippet']['publishedAt'] as String)),
    );
  }

  static String _formatDuration(String isoDuration) {
    // Convert ISO 8601 duration (PT15M33S) to readable format (15:33)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);

    if (match == null) return '0:00';

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  static bool _isNewVideo(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 7; // Consider videos newer than 7 days as "new"
  }
}

class PlaylistInfo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int videoCount;
  final DateTime publishedAt;

  PlaylistInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoCount,
    required this.publishedAt,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistInfo(
      id: json['id'] as String,
      title: json['snippet']['title'] as String,
      description: json['snippet']['description'] as String,
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'] as String,
      videoCount: json['contentDetails']['itemCount'] as int? ?? 0,
      publishedAt: DateTime.parse(json['snippet']['publishedAt'] as String),
    );
  }
}

// Category mapping for your app
class VideoCategory {
  static const Map<String, List<String>> categoryKeywords = {
    'Meditation': ['meditation', 'mindfulness', 'breathing', 'relaxation'],
    'Philosophy': ['philosophy', 'spiritual', 'consciousness', 'reality'],
    'Daily Wisdom': ['daily', 'wisdom', 'quote', 'insight', 'morning'],
    'Discourses': ['discourse', 'teaching', 'lecture', 'talk'],
    'Q&A Sessions': ['q&a', 'question', 'answer', 'session'],
  };

  static String categorizeVideo(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    for (final category in categoryKeywords.keys) {
      final keywords = categoryKeywords[category]!;
      if (keywords.any((keyword) => text.contains(keyword))) {
        return category;
      }
    }

    return 'Meditation'; // Default category
  }
}