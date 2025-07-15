import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import '../main.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper: Current status = ${authProvider.status}');
        
        switch (authProvider.status) {
          case AuthStatus.loading:
            print('AuthWrapper: Showing loading screen');
            return const SplashScreen();
          case AuthStatus.authenticated:
            print('AuthWrapper: User authenticated, showing main screen');
            return const MainScreen();
          case AuthStatus.unauthenticated:
            print('AuthWrapper: User not authenticated, showing login screen');
            return const LoginScreen();
        }
      },
    );
  }
}