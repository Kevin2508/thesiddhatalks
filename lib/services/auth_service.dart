import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add the web client ID from your google-services.json
    // This is required for proper token generation
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Initialize Firebase Auth
  Future<void> initialize() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.sendEmailVerification();
      await _createUserDocument(userCredential.user!, displayName: displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _updateUserDocument(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Google Sign In - Fixed for current google_sign_in package
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Check if Google Play Services are available
      final bool isAvailable = await _googleSignIn.isSignedIn();
      print('Google Sign-In available: $isAvailable');
      
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();

      // Start the sign-in process - correct method name for current version
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign in was cancelled by user');
        throw Exception('Google sign in was cancelled by user');
      }

      print('Google user signed in: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Got GoogleSignInAuthentication object');
      print('Access token null: ${googleAuth.accessToken == null}');
      print('ID token null: ${googleAuth.idToken == null}');

      // For current version, use the correct property names
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      // Validate tokens
      if (accessToken == null) {
        print('Access token is null - this indicates OAuth client configuration issues in Firebase');
        throw Exception('Failed to get Google access token. Please check your Firebase OAuth configuration and ensure SHA-1 fingerprint is added.');
      }
      
      if (idToken == null) {
        print('ID token is null - this indicates OAuth client configuration issues in Firebase');
        throw Exception('Failed to get Google ID token. Please check your Firebase OAuth configuration and ensure SHA-1 fingerprint is added.');
      }

      print('Got Google authentication tokens successfully');

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      await _createUserDocument(
        userCredential.user!,
        displayName: userCredential.user?.displayName,
        isGoogleSignIn: true,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during Google Sign-In: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('General exception during Google Sign-In: $e');
      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('sign_in_failed')) {
          throw Exception('Google Sign-In failed. Please check your SHA-1 fingerprint configuration in Firebase Console. Error: ${e.toString()}');
        }
      }
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('remember_me');
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        // User document doesn't exist, create it
        print('User document not found, creating new document for ${user.uid}');
        await _createUserDocument(user);
        
        // Try to get the data again
        final newDoc = await _firestore.collection('users').doc(user.uid).get();
        if (newDoc.exists) {
          return UserModel.fromJson(newDoc.data()!);
        }
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Create user document if it doesn't exist (public method)
  Future<void> createUserDocumentIfNeeded(User user) async {
    try {
      print('AuthService: Checking if user document exists for ${user.uid}');
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        print('AuthService: User document does not exist, creating...');
        await _createUserDocument(user, isGoogleSignIn: true);
        print('AuthService: User document created successfully');
      } else {
        print('AuthService: User document already exists');
      }
    } catch (e) {
      print('AuthService: Error creating user document: $e');
      throw e;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      if (displayName != null || photoURL != null) {
        await user.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }

      final updateData = <String, dynamic>{
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (preferences != null) updateData['preferences'] = preferences;

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Private helper methods
  Future<void> _createUserDocument(
      User user, {
        String? displayName,
        bool isGoogleSignIn = false,
      }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      final userData = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName ?? user.displayName ?? '',
        photoURL: user.photoURL,
        createdAt: docSnapshot.exists
            ? UserModel.fromJson(docSnapshot.data()!).createdAt
            : DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: user.emailVerified,
        phoneNumber: user.phoneNumber,
        preferences: {
          'isGoogleSignIn': isGoogleSignIn,
          'theme': 'system',
          'notifications': true,
        },
      );

      await userDoc.set(userData.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _updateUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isEmailVerified': user.emailVerified,
      });
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}