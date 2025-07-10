class AppConstants {
  // App Information
  static const String appName = 'The Siddha Talk';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A Modern Digital Ashram';

  // Namaste Greeting
  static const String namaste = 'नमस्ते';

  // Daily Quotes in Hindi
  static const List<String> dailyQuotes = [
    'मन की शांति ही सबसे बड़ा धन है।',
    'आत्मा की शुद्धता में ही सच्चा सुख है।',
    'ध्यान से मिलती है अंतर्दृष्टि।',
    'सत्य का अनुसरण ही मोक्ष का मार्ग है।',
    'करुणा और प्रेम ही जीवन का आधार है।',
    'स्थिर मन ही सफलता की कुंजी है।',
    'आंतरिक यात्रा ही सच्ची यात्रा है।',
  ];

  // Animation Durations
  static const Duration splashDuration = Duration(milliseconds: 3000);
  static const Duration cardAnimationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // UI Constants
  static const double defaultPadding = 20.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;

  // Video Categories
  static const List<String> videoCategories = [
    'All',
    'Meditation',
    'Philosophy',
    'Daily Wisdom',
    'Discourses',
    'Q&A Sessions',
  ];

  // Time-based Greetings
  static const Map<String, String> timeBasedGreetings = {
    'morning': 'Good Morning',
    'afternoon': 'Good Afternoon',
    'evening': 'Good Evening',
    'night': 'Good Night',
  };
}

class AppStrings {
  // Home Screen
  static const String explore = 'Explore';
  static const String wisdom = 'Wisdom';
  static const String todaysWisdom = "Today's Wisdom";
  static const String setReminder = 'Set Reminder';
  static const String liveSoon = 'LIVE SOON';
  static const String newUpload = 'NEW UPLOAD';
  static const String guidedMeditations = 'Guided Meditations';
  static const String spiritualDiscourses = 'Spiritual Discourses';
  static const String dailyWisdom = 'Daily Wisdom';

  // Player Screen
  static const String about = 'About';
  static const String comments = 'Comments';
  static const String askQuestion = 'Ask Question';
  static const String shareThoughts = 'Share your thoughts...';
  static const String postComment = 'Post';
  static const String submitQuestion = 'Submit Question';
  static const String questionPrompt = 'Do you have a question about this teaching?';
  static const String questionSubmitted = 'Your question has been submitted';

  // Wisdom Screen
  static const String questionsGuidance = 'Questions & Spiritual Guidance';
  static const String searchWisdom = 'Search wisdom...';
  static const String guidance = 'Guidance';

  // Explore Screen
  static const String discoverTeachings = 'Discover spiritual teachings and wisdom';
  static const String searchTeachings = 'Search teachings...';
  static const String watch = 'Watch';
  static const String play = 'Play';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
}