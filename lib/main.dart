import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const SpeakeraApp());
}

class SpeakeraApp extends StatelessWidget {
  const SpeakeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Speakera',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const SpeakeraHome(),
          );
        },
      ),
    );
  }
}

class SpeakeraHome extends StatefulWidget {
  const SpeakeraHome({super.key});

  @override
  State<SpeakeraHome> createState() => _SpeakeraHomeState();
}

class _SpeakeraHomeState extends State<SpeakeraHome> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.currentUser == null) {
          if (_showRegister) {
            return RegisterScreen(
              onSwitchToLogin: () => setState(() => _showRegister = false),
            );
          }
          return LoginScreen(
            onSwitchToRegister: () => setState(() => _showRegister = true),
          );
        }
        
        if (authProvider.currentUser!.role == UserRole.admin) {
          return AdminDashboard(
            onLogout: () => authProvider.logout(),
          );
        } else {
          return StudentDashboard(
            studentId: authProvider.currentUser!.id,
            onLogout: () => authProvider.logout(),
          );
        }
      },
    );
  }
}
