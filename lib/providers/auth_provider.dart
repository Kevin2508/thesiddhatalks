import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      print('AuthProvider: Initializing auth...');
      
      // Check if user is already signed in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('AuthProvider: User already signed in: ${currentUser.uid}');
        print('AuthProvider: User email: ${currentUser.email}');
        
        // Ensure user document exists
        await _authService.createUserDocumentIfNeeded(currentUser);
        
        _user = await _authService.getUserData();
        _status = AuthStatus.authenticated;
        print('AuthProvider: Initial auth complete. User: ${_user?.email}');
        notifyListeners();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      
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
            print('AuthProvider: User authenticated successfully. User data: ${_user?.email}');
          } else {
            print('AuthProvider: No user found, setting as unauthenticated');
            _user = null;
            _status = AuthStatus.unauthenticated;
          }
        } catch (e) {
          print('AuthProvider: Error in auth state change: $e');
          _status = AuthStatus.unauthenticated;
          _user = null;
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
        _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
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
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
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
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      // Don't set loading state here, let the auth state listener handle it
      // _setLoading(); // Commented out to prevent splash screen loop
      
      await _authService.signInWithGoogle();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Don't set loading here, the auth state listener will handle the state change
      await _authService.signOut();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.toString());
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
      _setError(e.toString());
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
      _setError(e.toString());
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
}