import 'package:shared_preferences/shared_preferences.dart';
import '../services/optimized_youtube_service.dart';

class AppInitializationService {
  static bool _isSessionInitialized = false;
  static final OptimizedYouTubeService _youtubeService = OptimizedYouTubeService();
  
  static void _debugLog(String message) {
    print('🚀 AppInitializationService: $message');
  }
  
  /// Check if the current app session has been initialized
  static bool get isSessionInitialized => _isSessionInitialized;
  
  /// Initialize app data if not already done in this session
  static Future<bool> initializeAppIfNeeded() async {
    try {
      // If already initialized in this session, return immediately
      if (_isSessionInitialized) {
        _debugLog('✅ App already initialized in this session');
        return true;
      }
      
      _debugLog('🔄 Checking if app initialization is needed');
      
      // Check if app has data available (cache or previous initialization)
      final hasData = await _youtubeService.isAppDataInitialized();
      
      if (hasData) {
        _debugLog('✅ App data is available, marking session as initialized');
        _isSessionInitialized = true;
        return true;
      }
      
      // Need to perform initial data sync
      _debugLog('🔄 No data available, performing initial sync');
      await _youtubeService.performInitialSync();
      
      _isSessionInitialized = true;
      _debugLog('✅ App initialization completed');
      return true;
      
    } catch (e) {
      _debugLog('❌ Error during app initialization: $e');
      return false;
    }
  }
  
  /// Force refresh app data (user-initiated)
  static Future<void> forceRefreshApp() async {
    try {
      _debugLog('🔄 Force refresh initiated');
      
      await _youtubeService.forceRefresh();
      _isSessionInitialized = true;
      
      _debugLog('✅ Force refresh completed');
    } catch (e) {
      _debugLog('❌ Error during force refresh: $e');
      rethrow;
    }
  }
  
  /// Reset session initialization flag (for testing or app restart scenarios)
  static void resetSession() {
    _isSessionInitialized = false;
    _debugLog('🔄 Session reset');
  }
  
  /// Check if this is the first time the app is being opened ever
  static Future<bool> isFirstAppLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey('app_has_been_launched');
    } catch (e) {
      return true;
    }
  }
  
  /// Mark the app as having been launched at least once
  static Future<void> markAppAsLaunched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_has_been_launched', true);
    } catch (e) {
      _debugLog('Error marking app as launched: $e');
    }
  }
}
