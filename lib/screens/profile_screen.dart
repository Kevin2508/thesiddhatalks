import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
  firebase_auth.User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    print('ProfileScreen initState - Firebase User: ${_firebaseUser?.email}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          // Debug information
          print('ProfileScreen - Auth Status: ${authProvider.status}');
          print('ProfileScreen - User: ${user?.email ?? 'null'}');
          print('ProfileScreen - Is Authenticated: ${authProvider.isAuthenticated}');
          
          // Handle loading state
          if (authProvider.status == AuthStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Handle unauthenticated state
          if (authProvider.status == AuthStatus.unauthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not Authenticated',
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please login to view your profile',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/auth',
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Go to Login',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Handle case where user is authenticated but user data is still loading
          if (user == null) {
            // Show Firebase Auth data as fallback
            if (_firebaseUser != null) {
              return _buildFirebaseAuthProfile(_firebaseUser!, authProvider);
            }
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your profile...',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This might be a Firestore permissions issue',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      // Force refresh user data
                      await authProvider.refreshUserData();
                    },
                    child: Text(
                      'Retry',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryAccent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent,
                          AppColors.secondaryAccent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60), // Space for status bar
                        
                        // Profile Picture
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.white,
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.primaryAccent,
                                  )
                                : null,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User Name
                        Text(
                          user.displayName,
                          style: GoogleFonts.rajdhani(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        // Email
                        Text(
                          user.email,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              
              // Profile Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Information Section
                      _buildSectionHeader('Account Information'),
                      const SizedBox(height: 16),
                      
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: 'Display Name',
                        value: user.displayName,
                      ),
                      
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: user.email,
                      ),
                      
                      _buildInfoCard(
                        icon: Icons.verified_outlined,
                        title: 'Email Verification',
                        value: user.isEmailVerified ? 'Verified' : 'Not Verified',
                        valueColor: user.isEmailVerified 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      
                      if (user.phoneNumber != null)
                        _buildInfoCard(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          value: user.phoneNumber!,
                        ),
                      
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Member Since',
                        value: _formatDate(user.createdAt),
                      ),
                      
                      _buildInfoCard(
                        icon: Icons.login_outlined,
                        title: 'Last Login',
                        value: _formatDate(user.lastLoginAt),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Actions Section
                      _buildSectionHeader('Actions'),
                      const SizedBox(height: 16),
                      
                      // Send Email Verification (if not verified)
                      if (!user.isEmailVerified)
                        _buildActionButton(
                          icon: Icons.mark_email_read_outlined,
                          title: 'Verify Email',
                          subtitle: 'Send verification email to your account',
                          onTap: () => _sendEmailVerification(context, authProvider),
                          color: Colors.blue,
                        ),
                      
                      // Update Profile
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        subtitle: 'Update your display name and other details',
                        onTap: () => _showEditProfileDialog(context, authProvider, user),
                        color: AppColors.primaryAccent,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoggingOut 
                              ? null 
                              : () => _showLogoutDialog(context, authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoggingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.logout, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFirebaseAuthProfile(firebase_auth.User firebaseUser, AuthProvider authProvider) {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 280.0,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primaryAccent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryAccent,
                    AppColors.secondaryAccent,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // Space for status bar
                  
                  // Profile Picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white,
                      backgroundImage: firebaseUser.photoURL != null
                          ? NetworkImage(firebaseUser.photoURL!)
                          : null,
                      child: firebaseUser.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primaryAccent,
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    firebaseUser.displayName ?? 'User',
                    style: GoogleFonts.rajdhani(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Email
                  Text(
                    firebaseUser.email ?? '',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  // Warning banner
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Firestore Data Unavailable',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        
        // Profile Details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Firestore Access Issue',
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to access Firestore data. This is likely a database permissions issue. Showing Firebase Auth data instead.',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Information Section
                _buildSectionHeader('Firebase Auth Information'),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: 'Display Name',
                  value: firebaseUser.displayName ?? 'Not set',
                ),
                
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: firebaseUser.email ?? 'Not available',
                ),
                
                _buildInfoCard(
                  icon: Icons.verified_outlined,
                  title: 'Email Verification',
                  value: firebaseUser.emailVerified ? 'Verified' : 'Not Verified',
                  valueColor: firebaseUser.emailVerified ? Colors.green : Colors.orange,
                ),
                
                if (firebaseUser.phoneNumber != null)
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    value: firebaseUser.phoneNumber!,
                  ),
                
                _buildInfoCard(
                  icon: Icons.fingerprint_outlined,
                  title: 'User ID',
                  value: firebaseUser.uid,
                ),
                
                if (firebaseUser.metadata.creationTime != null)
                  _buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Account Created',
                    value: _formatDate(firebaseUser.metadata.creationTime!),
                  ),
                
                if (firebaseUser.metadata.lastSignInTime != null)
                  _buildInfoCard(
                    icon: Icons.login_outlined,
                    title: 'Last Sign In',
                    value: _formatDate(firebaseUser.metadata.lastSignInTime!),
                  ),
                
                const SizedBox(height: 32),
                
                // Actions Section
                _buildSectionHeader('Actions'),
                const SizedBox(height: 16),
                
                // Retry Firestore
                _buildActionButton(
                  icon: Icons.refresh_outlined,
                  title: 'Retry Firestore Access',
                  subtitle: 'Try to reconnect to database',
                  onTap: () async {
                    await authProvider.refreshUserData();
                  },
                  color: Colors.blue,
                ),
                
                const SizedBox(height: 32),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoggingOut 
                        ? null 
                        : () => _showLogoutDialog(context, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: GoogleFonts.lato(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(authProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(AuthProvider authProvider) async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _sendEmailVerification(BuildContext context, AuthProvider authProvider) async {
    try {
      final success = await authProvider.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Verification email sent successfully!' 
                  : 'Failed to send verification email',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider, UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != user.displayName) {
                  Navigator.of(context).pop();
                  final success = await authProvider.updateUserProfile(
                    displayName: newName,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                              ? 'Profile updated successfully!' 
                              : 'Failed to update profile',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Update',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
