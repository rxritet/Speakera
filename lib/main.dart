import 'package:flutter/material.dart';
import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_dashboard.dart';

void main() {
  runApp(const SpeakeraApp());
}

class SpeakeraApp extends StatefulWidget {
  const SpeakeraApp({super.key});

  @override
  State<SpeakeraApp> createState() => _SpeakeraAppState();
}

class _SpeakeraAppState extends State<SpeakeraApp> {
  ThemeMode _themeMode = ThemeMode.light;
  UserRole? _loggedInRole;

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _login(UserRole role) {
    setState(() => _loggedInRole = role);
    // Snackbar shown after build via addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                'Logged in as ${role == UserRole.admin ? "Admin" : "Student"}',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    });
  }

  void _logout() {
    setState(() => _loggedInRole = null);
  }

  final _navigatorKey = GlobalKey<NavigatorState>();

  static const _primaryColor = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Speakera',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // ─── Light Theme ─────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: _primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: _primaryColor.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // ─── Dark Theme ──────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: const Color(0xFF1E293B),
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Color(0xFF3B82F6),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      home: _loggedInRole == null
          ? LoginScreen(onLogin: _login)
          : _loggedInRole == UserRole.admin
          ? AdminDashboard(
              onLogout: _logout,
              isDarkMode: _isDarkMode,
              onThemeToggle: _toggleTheme,
            )
          : StudentDashboard(
              studentId: 's1', // Default to Alice for demo
              onLogout: _logout,
              isDarkMode: _isDarkMode,
              onThemeToggle: _toggleTheme,
            ),
    );
  }
}
