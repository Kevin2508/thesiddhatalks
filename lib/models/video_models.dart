class Video {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String duration;
  final int? viewCount;
  final int? likeCount;
  final DateTime publishedAt;
  final String channelTitle;
  final String pcloudUrl;
  final String? youtubeUrl; // Optional YouTube URL for external viewing

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.duration,
    this.viewCount,
    this.likeCount,
    required this.publishedAt,
    required this.channelTitle,
    required this.pcloudUrl,
    this.youtubeUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      duration: json['duration'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : DateTime.now(),
      channelTitle: json['channelTitle'] ?? 'Siddha Kutumbakam',
      pcloudUrl: json['pcloudUrl'] ?? '',
      youtubeUrl: json['youtubeUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'publishedAt': publishedAt.toIso8601String(),
      'channelTitle': channelTitle,
      'pcloudUrl': pcloudUrl,
      'youtubeUrl': youtubeUrl,
    };
  }

  // Helper method to get formatted duration (e.g., "PT56M51S" -> "56:51")
  String get formattedDuration {
    if (duration.isEmpty) return '0:00';
    
    // Parse ISO 8601 duration format (PT56M51S)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    
    if (match == null) return duration;
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Helper method to get formatted view count (e.g., 1234 -> "1.2K")
  String get formattedViewCount {
    if (viewCount == null) return '0';
    if (viewCount! < 1000) return viewCount.toString();
    if (viewCount! < 1000000) return '${(viewCount! / 1000).toStringAsFixed(1)}K';
    return '${(viewCount! / 1000000).toStringAsFixed(1)}M';
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoCount: json['videoCount'] ?? 0,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoCount': videoCount,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}
