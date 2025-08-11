class FirestoreVideo {
  final int id;
  final String titleEnglish;
  final String titleHindi;
  final String pcloudLink;
  final String youtubeUrl;
  final String category;
  final String thumbnail;
  final DateTime publishedAt;
  final String duration;
  final String keywords;
  final bool isAvailable;

  FirestoreVideo({
    required this.id,
    required this.titleEnglish,
    required this.titleHindi,
    required this.pcloudLink,
    required this.youtubeUrl,
    required this.category,
    required this.thumbnail,
    required this.publishedAt,
    required this.duration,
    required this.keywords,
    this.isAvailable = true,
  });

  factory FirestoreVideo.fromFirestore(Map<String, dynamic> data) {
    return FirestoreVideo(
      id: data['id'] ?? 0,
      titleEnglish: data['Title_in_English'] ?? 'Not available',
      titleHindi: data['Title_in_Hindi'] ?? 'उपलब्ध नहीं',
      pcloudLink: data['PCLOUD_LINK'] ?? '',
      youtubeUrl: data['YOUTUBE_URL'] ?? '',
      category: data['Category'] ?? 'Uncategorized',
      thumbnail: data['Thumbnail'] ?? '',
      publishedAt: data['Published_At'] != null 
          ? DateTime.tryParse(data['Published_At']) ?? DateTime.now()
          : DateTime.now(),
      duration: _formatDuration(data['Duration'] ?? 'PT0S'),
      keywords: data['Keyword'] ?? '',
      isAvailable: _checkAvailability(data),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Title_in_English': titleEnglish,
      'Title_in_Hindi': titleHindi,
      'PCLOUD_LINK': pcloudLink,
      'YOUTUBE_URL': youtubeUrl,
      'Category': category,
      'Thumbnail': thumbnail,
      'Published_At': publishedAt.toIso8601String(),
      'Duration': duration,
      'Keyword': keywords,
    };
  }

  // Helper method to check if video data is complete
  static bool _checkAvailability(Map<String, dynamic> data) {
    final requiredFields = [
      'Title_in_English',
      'Title_in_Hindi', 
      'PCLOUD_LINK',
      'Category'
    ];
    
    for (String field in requiredFields) {
      if (data[field] == null || 
          data[field].toString().isEmpty || 
          data[field].toString().toLowerCase() == 'not available') {
        return false;
      }
    }
    return true;
  }

  // Helper method to format duration from ISO 8601 format
  static String _formatDuration(String isoDuration) {
    if (isoDuration.isEmpty || isoDuration == 'PT0S') return '0:00';
    
    try {
      // Parse ISO 8601 duration format (PT1H2M3S)
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(isoDuration);
      
      if (match == null) return '0:00';
      
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      
      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '0:00';
    }
  }

  // Get display title based on language preference
  String getDisplayTitle({bool preferHindi = false}) {
    if (preferHindi && titleHindi.isNotEmpty && titleHindi != 'उपलब्ध नहीं') {
      return titleHindi;
    }
    return titleEnglish.isNotEmpty ? titleEnglish : 'Not available';
  }

  // Check if video has pCloud link for playing
  bool get canPlay => pcloudLink.isNotEmpty && pcloudLink.contains('pcloud.link');

  // Get video thumbnail or fallback
  String get displayThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    // Fallback to a default meditation thumbnail or category-based image
    return 'assets/images/meditation_default.png';
  }
}

class VideoCategory {
  final String name;
  final String description;
  final List<FirestoreVideo> videos;
  final String iconName;
  
  VideoCategory({
    required this.name,
    required this.description,
    required this.videos,
    required this.iconName,
  });

  // Get available videos count
  int get availableVideosCount => videos.where((v) => v.isAvailable).length;
  
  // Get total videos count
  int get totalVideosCount => videos.length;
  
  // Get category status
  String get statusText => '$availableVideosCount/$totalVideosCount videos';

  // Static method to get all categories
  static List<String> getAllCategories() {
    return [
      'Chakra Alignment',
      'Protection Layer',
      'Mangal Kamana',
      'Cleansing',
      'Breathing Technique',
      'Sahaj Dhyan',
      'Ratri Dhyan',
      'Devine Energy',
      'Gibberish',
      'Kundali',
      'Standing Meditation',
    ];
  }

  // Get category description
  static String getCategoryDescription(String category) {
    switch (category) {
      case 'Chakra Alignment':
        return 'Balance and align your energy centers for optimal well-being';
      case 'Protection Layer':
        return 'Create energetic shields and protective barriers';
      case 'Mangal Kamana':
        return 'Blessings and auspicious meditations for prosperity';
      case 'Cleansing':
        return 'Purify your mind, body, and energy field';
      case 'Breathing Technique':
        return 'Pranayama and breath-focused meditation practices';
      case 'Sahaj Dhyan':
        return 'Natural, effortless meditation techniques';
      case 'Ratri Dhyan':
        return 'Night-time meditation for deep rest and dreams';
      case 'Devine Energy':
        return 'Connect with divine consciousness and higher energies';
      case 'Gibberish':
        return 'Release mental chatter through gibberish meditation';
      case 'Kundali':
        return 'Awaken and work with Kundalini energy';
      case 'Standing Meditation':
        return 'Meditation practices done in standing position';
      default:
        return 'Explore this collection of meditation videos';
    }
  }

  // Get category icon
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'Chakra Alignment':
        return 'chakra_icon.png';
      case 'Protection Layer':
        return 'protection_icon.png';
      case 'Mangal Kamana':
        return 'mangal_icon.png';
      case 'Cleansing':
        return 'cleansing_icon.png';
      case 'Breathing Technique':
        return 'breathing_icon.png';
      case 'Sahaj Dhyan':
        return 'sahaj_icon.png';
      case 'Ratri Dhyan':
        return 'ratri_icon.png';
      case 'Devine Energy':
        return 'devine_icon.png';
      case 'Gibberish':
        return 'gibberish_icon.png';
      case 'Kundali':
        return 'kundali_icon.png';
      case 'Standing Meditation':
        return 'standing_icon.png';
      default:
        return 'meditation_default.png';
    }
  }
}
