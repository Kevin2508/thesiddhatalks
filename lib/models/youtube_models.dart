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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'snippet': {
        'title': title,
        'description': description,
        'thumbnails': {
          'high': {
            'url': thumbnailUrl,
          },
        },
        'channelTitle': channelTitle,
        'publishedAt': publishedAt.toIso8601String(),
      },
      'contentDetails': {
        'duration': _durationToIso(duration),
      },
      'statistics': {
        'viewCount': viewCount.toString(),
        'likeCount': likeCount.toString(),
      },
    };
  }

  static String _durationToIso(String formattedDuration) {
    final parts = formattedDuration.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return 'PT${minutes}M${seconds}S';
    } else if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return 'PT${hours}H${minutes}M${seconds}S';
    }
    return 'PT0S';
  }

  static String _formatDuration(String isoDuration) {
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
    return difference.inDays <= 7;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'snippet': {
        'title': title,
        'description': description,
        'thumbnails': {
          'high': {
            'url': thumbnailUrl,
          },
        },
        'publishedAt': publishedAt.toIso8601String(),
      },
      'contentDetails': {
        'itemCount': videoCount,
      },
    };
  }
}

// Live Stream Models
enum LiveStreamStatus {
  upcoming,
  live,
  completed,
  cancelled,
}

class LiveStream {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;
  final LiveStreamStatus status;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int? concurrentViewers;
  final int viewCount;
  final int likeCount;
  final String streamUrl;
  final bool isPrivate;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    required this.status,
    this.scheduledStartTime,
    this.actualStartTime,
    this.actualEndTime,
    this.concurrentViewers,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.streamUrl,
    this.isPrivate = false,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    final liveStreamingDetails = json['liveStreamingDetails'] as Map<String, dynamic>?;
    final statistics = json['statistics'] as Map<String, dynamic>?;

    // Determine status
    LiveStreamStatus status;
    if (liveStreamingDetails != null) {
      if (liveStreamingDetails['actualEndTime'] != null) {
        status = LiveStreamStatus.completed;
      } else if (liveStreamingDetails['actualStartTime'] != null) {
        status = LiveStreamStatus.live;
      } else {
        status = LiveStreamStatus.upcoming;
      }
    } else {
      status = LiveStreamStatus.completed;
    }

    return LiveStream(
      id: json['id'] as String,
      title: json['snippet']['title'] as String,
      description: json['snippet']['description'] as String? ?? '',
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'] as String,
      channelTitle: json['snippet']['channelTitle'] as String,
      publishedAt: DateTime.parse(json['snippet']['publishedAt'] as String),
      status: status,
      scheduledStartTime: liveStreamingDetails?['scheduledStartTime'] != null
          ? DateTime.parse(liveStreamingDetails!['scheduledStartTime'] as String)
          : null,
      actualStartTime: liveStreamingDetails?['actualStartTime'] != null
          ? DateTime.parse(liveStreamingDetails!['actualStartTime'] as String)
          : null,
      actualEndTime: liveStreamingDetails?['actualEndTime'] != null
          ? DateTime.parse(liveStreamingDetails!['actualEndTime'] as String)
          : null,
      concurrentViewers: liveStreamingDetails?['concurrentViewers'] != null
          ? int.tryParse(liveStreamingDetails!['concurrentViewers'] as String)
          : null,
      viewCount: int.tryParse(statistics?['viewCount'] as String? ?? '0') ?? 0,
      likeCount: int.tryParse(statistics?['likeCount'] as String? ?? '0') ?? 0,
      streamUrl: 'https://www.youtube.com/watch?v=${json['id']}',
      isPrivate: json['snippet']['liveBroadcastContent'] == 'none',
    );
  }

  factory LiveStream.fromSearchJson(Map<String, dynamic> json) {
    // For search results, we have limited data
    return LiveStream(
      id: json['id']['videoId'] as String,
      title: json['snippet']['title'] as String,
      description: json['snippet']['description'] as String? ?? '',
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'] as String,
      channelTitle: json['snippet']['channelTitle'] as String,
      publishedAt: DateTime.parse(json['snippet']['publishedAt'] as String),
      status: LiveStreamStatus.live, // Search results are typically live
      streamUrl: 'https://www.youtube.com/watch?v=${json['id']['videoId']}',
      isPrivate: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'snippet': {
        'title': title,
        'description': description,
        'thumbnails': {
          'high': {
            'url': thumbnailUrl,
          },
        },
        'channelTitle': channelTitle,
        'publishedAt': publishedAt.toIso8601String(),
      },
      'liveStreamingDetails': {
        if (scheduledStartTime != null)
          'scheduledStartTime': scheduledStartTime!.toIso8601String(),
        if (actualStartTime != null)
          'actualStartTime': actualStartTime!.toIso8601String(),
        if (actualEndTime != null)
          'actualEndTime': actualEndTime!.toIso8601String(),
        if (concurrentViewers != null)
          'concurrentViewers': concurrentViewers.toString(),
      },
      'statistics': {
        'viewCount': viewCount.toString(),
        'likeCount': likeCount.toString(),
      },
    };
  }

  // Helper methods
  bool get isLive => status == LiveStreamStatus.live;
  bool get isUpcoming => status == LiveStreamStatus.upcoming;
  bool get isCompleted => status == LiveStreamStatus.completed;

  String get statusText {
    switch (status) {
      case LiveStreamStatus.live:
        return 'LIVE';
      case LiveStreamStatus.upcoming:
        return 'Scheduled';
      case LiveStreamStatus.completed:
        return 'Completed';
      case LiveStreamStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get timeText {
    final now = DateTime.now();

    if (isLive && actualStartTime != null) {
      final duration = now.difference(actualStartTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return 'Live for ${hours > 0 ? '${hours}h ' : ''}${minutes}m';
    } else if (isUpcoming && scheduledStartTime != null) {
      final timeUntil = scheduledStartTime!.difference(now);
      if (timeUntil.isNegative) {
        return 'Starting soon';
      }
      final days = timeUntil.inDays;
      final hours = timeUntil.inHours.remainder(24);
      final minutes = timeUntil.inMinutes.remainder(60);

      if (days > 0) {
        return 'In ${days}d ${hours}h';
      } else if (hours > 0) {
        return 'In ${hours}h ${minutes}m';
      } else {
        return 'In ${minutes}m';
      }
    } else if (isCompleted && actualStartTime != null) {
      final timeAgo = now.difference(actualStartTime!);
      final days = timeAgo.inDays;
      final hours = timeAgo.inHours;

      if (days > 0) {
        return '${days} days ago';
      } else if (hours > 0) {
        return '${hours} hours ago';
      } else {
        return 'Recently completed';
      }
    }

    return '';
  }

  String get viewerText {
    if (isLive && concurrentViewers != null) {
      return '${_formatNumber(concurrentViewers!)} watching';
    } else {
      return '${_formatNumber(viewCount)} views';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Convert LiveStream to YouTubeVideo for watchlist functionality
  YouTubeVideo toYouTubeVideo() {
    return YouTubeVideo(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      publishedAt: publishedAt,
      duration: isLive ? 'LIVE' : 'Unknown',
      viewCount: viewCount,
      likeCount: likeCount,
      isNew: false,
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
    'Live Sessions': ['live', 'streaming', 'broadcast', 'session'],
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