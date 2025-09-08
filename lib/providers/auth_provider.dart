import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/auth_status.dart';
import '../utils/network_utils.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;
  String? _localProfilePicturePath;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get localProfilePicturePath => _localProfilePicturePath;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get firebaseUser => _authService.currentUser;

  AuthProvider() {
    _initializeAuth();
    _loadLocalProfilePicture();
  }

  void _initializeAuth() async {
    try {
      print('AuthProvider: Initializing auth...');
      
      // Give a moment for Firebase Auth to restore state after app startup
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if user is already signed in
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        print('AuthProvider: User already signed in: ${currentUser.uid}');
        print('AuthProvider: User email: ${currentUser.email}');
        
        try {
          // Ensure user document exists
          await _authService.createUserDocumentIfNeeded(currentUser);
          
          _user = await _authService.getUserData();
          _status = AuthStatus.authenticated;
          print('AuthProvider: Initial auth complete. User: ${_user?.email}');
        } catch (e) {
          print('AuthProvider: Error loading user data: $e');
          // Even if user data fails due to Firestore issues, keep user authenticated 
          // if Firebase user exists
          _status = AuthStatus.authenticated;
          _user = null; // Clear user data but keep authenticated status
          print('AuthProvider: Keeping authenticated status despite Firestore error');
        }
      } else {
        print('AuthProvider: No current user found, setting unauthenticated');
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
      
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? firebaseUser) async {
        try {
          print('AuthProvider: Auth state changed. User: ${firebaseUser?.uid}');
          print('AuthProvider: User email: ${firebaseUser?.email}');
          print('AuthProvider: User display name: ${firebaseUser?.displayName}');
          
          if (firebaseUser != null) {
            print('AuthProvider: User is logged in, getting user data...');
            _user = await _authService.getUserData();
            
            if (_user == null) {
              print('AuthProvider: User data is null, creating user document...');
              // If user data is null, create the user document
              await _authService.createUserDocumentIfNeeded(firebaseUser);
              // Try to get user data again
              _user = await _authService.getUserData();
            }
            
            _status = AuthStatus.authenticated;
            // Load local profile picture when user signs in
            await _loadLocalProfilePicture();
            print('AuthProvider: User authenticated successfully. User data: ${_user?.email}');
          } else {
            print('AuthProvider: No user found, setting as unauthenticated');
            _user = null;
            _localProfilePicturePath = null;
            _status = AuthStatus.unauthenticated;
            // Clean up old profile pictures when user signs out
            await _cleanupProfilePictures();
          }
        } catch (e) {
          print('AuthProvider: Error in auth state change: $e');
          // Don't set as unauthenticated if it's just a Firestore permission issue
          // The Firebase user is still authenticated, just can't access Firestore data
          if (firebaseUser != null) {
            print('AuthProvider: Firebase user still exists despite Firestore error, keeping authenticated status');
            _status = AuthStatus.authenticated;
            _user = null; // Clear user data but keep authenticated status
          } else {
            _status = AuthStatus.unauthenticated;
            _user = null;
          }
        }
        notifyListeners();
      });
    } catch (e) {
      print('AuthProvider: Error initializing auth: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Force refresh user data
  Future<void> refreshUserData() async {
    try {
      print('AuthProvider: Refreshing user data...');
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('AuthProvider: Current user exists: ${currentUser.email}');
        
        // Ensure user document exists
        await _authService.createUserDocumentIfNeeded(currentUser);
        
        _user = await _authService.getUserData();
        _status = AuthStatus.authenticated;
        print('AuthProvider: User data refreshed. Status: $_status, User: ${_user?.email}');
        notifyListeners();
      } else {
        print('AuthProvider: No current user found during refresh');
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Error refreshing user data: $e');
      // Keep authenticated if Firebase user exists, even if Firestore fails
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('AuthProvider: Keeping authenticated status despite refresh error');
        _status = AuthStatus.authenticated;
        _user = null;
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
      }
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading();
      
      // Check network connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _setError(NetworkUtils.getAuthNetworkErrorMessage());
        return false;
      }
      
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _clearError();
      return true;
    } catch (e) {
      // Use user-friendly error message
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading();
      
      // Check network connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _setError(NetworkUtils.getAuthNetworkErrorMessage());
        return false;
      }
      
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _clearError();
      return true;
    } catch (e) {
      // Use user-friendly error message
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      // Check network connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _setError(NetworkUtils.getAuthNetworkErrorMessage());
        return false;
      }
      
      // Don't set loading state here, let the auth state listener handle it
      // _setLoading(); // Commented out to prevent splash screen loop
      
      await _authService.signInWithGoogle();
      _clearError();
      return true;
    } catch (e) {
      // Use user-friendly error message
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear local profile picture path
      _localProfilePicturePath = null;
      // Don't set loading here, the auth state listener will handle the state change
      await _authService.signOut();
      _clearError();
    } catch (e) {
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      // Check network connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _setError(NetworkUtils.getAuthNetworkErrorMessage());
        return false;
      }
      
      await _authService.resetPassword(email);
      _clearError();
      return true;
    } catch (e) {
      // Use user-friendly error message
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      // Check network connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _setError(NetworkUtils.getAuthNetworkErrorMessage());
        return false;
      }
      
      await _authService.sendEmailVerification();
      _clearError();
      return true;
    } catch (e) {
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Check email verification
  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _authService.checkEmailVerification();
      if (isVerified && _user != null) {
        _user = _user!.copyWith(isEmailVerified: true);
        notifyListeners();
      }
      return isVerified;
    } catch (e) {
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
        preferences: preferences,
      );

      // Refresh user data
      _user = await _authService.getUserData();
      notifyListeners();
      _clearError();
      return true;
    } catch (e) {
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _clearError();
      return true;
    } catch (e) {
      _setError(NetworkUtils.getUserFriendlyAuthError(e.toString()));
      return false;
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Local Profile Picture Management
  
  // Load local profile picture path from SharedPreferences
  Future<void> _loadLocalProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = firebaseUser?.uid;
      if (userId != null) {
        _localProfilePicturePath = prefs.getString('profile_picture_$userId');
        // Check if the file still exists
        if (_localProfilePicturePath != null) {
          final file = File(_localProfilePicturePath!);
          if (!await file.exists()) {
            // File doesn't exist anymore, clear the path
            _localProfilePicturePath = null;
            await prefs.remove('profile_picture_$userId');
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Error loading local profile picture: $e');
    }
  }

  // Pick and save profile picture from gallery
  Future<bool> pickProfilePictureFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return await _saveProfilePicture(image);
      }
      return false;
    } catch (e) {
      _setError('Failed to pick image from gallery: $e');
      return false;
    }
  }

  // Pick and save profile picture from camera
  Future<bool> pickProfilePictureFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return await _saveProfilePicture(image);
      }
      return false;
    } catch (e) {
      _setError('Failed to take picture: $e');
      return false;
    }
  }

  // Save the selected image to local storage
  Future<bool> _saveProfilePicture(XFile image) async {
    try {
      final userId = firebaseUser?.uid;
      if (userId == null) {
        _setError('User not authenticated');
        return false;
      }

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final profilePicturesDir = Directory('${appDir.path}/profile_pictures');
      
      // Create directory if it doesn't exist
      if (!await profilePicturesDir.exists()) {
        await profilePicturesDir.create(recursive: true);
      }

      // Delete old profile picture if it exists
      await _deleteOldProfilePicture(userId);

      // Create new filename with timestamp to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.path.split('.').last;
      final newPath = '${profilePicturesDir.path}/profile_${userId}_$timestamp.$extension';

      // Copy the file to the new location
      final File newFile = await File(image.path).copy(newPath);
      
      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_picture_$userId', newFile.path);
      
      _localProfilePicturePath = newFile.path;
      notifyListeners();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to save profile picture: $e');
      return false;
    }
  }

  // Delete old profile picture file
  Future<void> _deleteOldProfilePicture(String userId) async {
    try {
      if (_localProfilePicturePath != null) {
        final oldFile = File(_localProfilePicturePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
    } catch (e) {
      print('AuthProvider: Error deleting old profile picture: $e');
    }
  }

  // Remove profile picture
  Future<bool> removeProfilePicture() async {
    try {
      final userId = firebaseUser?.uid;
      if (userId == null) {
        _setError('User not authenticated');
        return false;
      }

      // Delete the file
      await _deleteOldProfilePicture(userId);
      
      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_picture_$userId');
      
      _localProfilePicturePath = null;
      notifyListeners();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to remove profile picture: $e');
      return false;
    }
  }

  // Clean up profile pictures for signed out user
  Future<void> _cleanupProfilePictures() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profilePicturesDir = Directory('${appDir.path}/profile_pictures');
      
      if (await profilePicturesDir.exists()) {
        final files = await profilePicturesDir.list().toList();
        for (final file in files) {
          if (file is File) {
            // Clean up old files (older than 30 days)
            final stat = await file.stat();
            final age = DateTime.now().difference(stat.modified);
            if (age.inDays > 30) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('AuthProvider: Error cleaning up profile pictures: $e');
    }
  }
}