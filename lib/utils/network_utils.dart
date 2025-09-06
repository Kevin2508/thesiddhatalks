import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // If no connectivity, return false immediately
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // If connected to wifi or mobile, do a real internet check
      if (connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        
        // Try to lookup a reliable host to confirm internet access
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 5));
          return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (e) {
          return false;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get connectivity status stream for listening to changes
  static Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Check if the error is network-related
  static bool isNetworkError(String error) {
    final networkErrors = [
      'network',
      'connection',
      'timeout',
      'unreachable',
      'failed to connect',
      'no internet',
      'socketexception',
      'handshakeexception',
      'tlsexception',
      'httperror',
      'dns',
      'resolve',
    ];

    final lowerError = error.toLowerCase();
    return networkErrors.any((keyword) => lowerError.contains(keyword));
  }

  /// Get user-friendly network error message
  static String getNetworkErrorMessage() {
    return 'No internet connection. Please check your network settings and try again.';
  }

  /// Get user-friendly firebase auth network error message
  static String getAuthNetworkErrorMessage() {
    return 'No internet connection. Please check your network and try again.';
  }

  /// Get user-friendly error message for authentication failures
  static String getUserFriendlyAuthError(String technicalError) {
    final lowerError = technicalError.toLowerCase();
    
    // Network-related errors
    if (isNetworkError(technicalError)) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    // Firebase Auth specific errors
    if (lowerError.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (lowerError.contains('wrong-password') || lowerError.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lowerError.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (lowerError.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    if (lowerError.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (lowerError.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    if (lowerError.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please contact support.';
    }
    if (lowerError.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method.';
    }
    if (lowerError.contains('requires-recent-login')) {
      return 'Please sign out and sign in again to continue.';
    }
    if (lowerError.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    
    // Google Sign In errors
    if (lowerError.contains('sign_in_canceled') || lowerError.contains('canceled')) {
      return 'Sign-in was canceled.';
    }
    if (lowerError.contains('sign_in_failed')) {
      return 'Google sign-in failed. Please try again.';
    }
    
    // Generic fallback messages
    if (lowerError.contains('signin') || lowerError.contains('login')) {
      return 'Sign-in failed. Please check your credentials and try again.';
    }
    if (lowerError.contains('signup') || lowerError.contains('register')) {
      return 'Sign-up failed. Please try again.';
    }
    
    // Default fallback
    return 'Something went wrong. Please try again.';
  }
}
