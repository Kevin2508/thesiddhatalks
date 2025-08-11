import '../models/youtube_models.dart';
import '../models/firestore_video_models.dart';

/// Adapter class to provide a unified interface for both FirestoreVideo and YouTubeVideo
class VideoAdapter {
  final dynamic _video;
  
  VideoAdapter(this._video) {
    if (_video is! FirestoreVideo && _video is! YouTubeVideo) {
      throw ArgumentError('Video must be either FirestoreVideo or YouTubeVideo');
    }
  }

  // Common properties
  String get id {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).id.toString();
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).id;
    }
    return '';
  }

  String get title {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).getDisplayTitle();
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).title;
    }
    return '';
  }

  String get description {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).keywords; // Use keywords as description for Firestore videos
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).description;
    }
    return '';
  }

  String get thumbnailUrl {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).displayThumbnail;
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).thumbnailUrl;
    }
    return '';
  }

  String get duration {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).duration;
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).duration;
    }
    return '';
  }

  DateTime get publishedAt {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).publishedAt;
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).publishedAt;
    }
    return DateTime.now();
  }

  String get channelTitle {
    if (_video is FirestoreVideo) {
      return 'Siddha Samadhi'; // Default channel for Firestore videos
    } else if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).channelTitle;
    }
    return '';
  }

  // Video type identification
  bool get isFirestoreVideo => _video is FirestoreVideo;
  bool get isYouTubeVideo => _video is YouTubeVideo;

  // Video source URLs
  String get playbackUrl {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).pcloudLink;
    } else if (_video is YouTubeVideo) {
      return 'https://youtube.com/watch?v=${(_video as YouTubeVideo).id}';
    }
    return '';
  }

  String get youtubeUrl {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).youtubeUrl;
    } else if (_video is YouTubeVideo) {
      return 'https://youtube.com/watch?v=${(_video as YouTubeVideo).id}';
    }
    return '';
  }

  // Firestore-specific properties
  String get category {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).category;
    }
    return '';
  }

  String get titleEnglish {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).titleEnglish;
    }
    return title;
  }

  String get titleHindi {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).titleHindi;
    }
    return '';
  }

  String get keywords {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).keywords;
    }
    return '';
  }

  // YouTube-specific properties
  int get viewCount {
    if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).viewCount;
    }
    return 0;
  }

  int get likeCount {
    if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).likeCount;
    }
    return 0;
  }

  bool get isNew {
    if (_video is YouTubeVideo) {
      return (_video as YouTubeVideo).isNew;
    }
    // Consider Firestore videos published in last 7 days as new
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 7;
  }

  // Playback capabilities
  bool get canPlayInApp {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).canPlay && (_video as FirestoreVideo).pcloudLink.isNotEmpty;
    } else if (_video is YouTubeVideo) {
      return true; // YouTube videos can always be played
    }
    return false;
  }

  bool get hasYouTubeSource {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).youtubeUrl.isNotEmpty;
    } else if (_video is YouTubeVideo) {
      return true;
    }
    return false;
  }

  bool get hasPCloudSource {
    if (_video is FirestoreVideo) {
      return (_video as FirestoreVideo).pcloudLink.isNotEmpty;
    }
    return false;
  }

  // Get the original video object
  T getOriginalVideo<T>() {
    if (T == FirestoreVideo && _video is FirestoreVideo) {
      return _video as T;
    } else if (T == YouTubeVideo && _video is YouTubeVideo) {
      return _video as T;
    }
    throw ArgumentError('Video is not of type $T');
  }

  // Helper methods
  String getFormattedDuration() {
    return duration;
  }

  String getFormattedPublishedDate() {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String getFormattedViewCount() {
    if (viewCount == 0) return '';
    
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }

  // Share content
  String getShareText() {
    final shareUrl = hasYouTubeSource ? youtubeUrl : playbackUrl;
    return '$title\n\nWatch this meditation video: $shareUrl';
  }

  // Convert to map for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'type': isFirestoreVideo ? 'firestore' : 'youtube',
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'publishedAt': publishedAt.toIso8601String(),
      'channelTitle': channelTitle,
      'playbackUrl': playbackUrl,
      'youtubeUrl': youtubeUrl,
      if (isFirestoreVideo) ...{
        'category': category,
        'titleEnglish': titleEnglish,
        'titleHindi': titleHindi,
        'keywords': keywords,
      },
      if (isYouTubeVideo) ...{
        'viewCount': viewCount,
        'likeCount': likeCount,
        'isNew': isNew,
      },
    };
  }

  @override
  String toString() {
    return 'VideoAdapter(type: ${isFirestoreVideo ? 'Firestore' : 'YouTube'}, id: $id, title: $title)';
  }
}
